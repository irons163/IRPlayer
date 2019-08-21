//
//  IRGLView.m
//  IRPlayer
//
//  Created by Phil on 2019/7/5.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "IRGLView.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/EAGL.h>
#import "IRMovieDecoder.h"
//#import "VideoDecoder.h"
#import "IRGLTransformController2D.h"
#import "IRGLTransformController3DFisheye.h"
#import "IRGLProjectionOrthographic.h"
#import "IRGLProjectionEquirectangular.h"
#import "IRGLProgram2D.h"
#import "IRGLProgram2DFisheye2Pano.h"
#import "IRGLProgram3DFisheye.h"
#import "IRGLProgram2DFisheye2Persp.h"
#import "IRGLProgramFactory.h"
#import "IRSimulateDeviceShiftController.h"
#import "IRGLRenderMode.h"
#import "IRGLProgram2DFactory.h"
#import "IRGLRenderModeFactory.h"
#import <pthread.h>
#include <sys/time.h>
#import "IRAVPlayer.h"

@interface IRGLRenderMode(BuildIRGLProgram)

@end

@implementation IRGLRenderMode(BuildIRGLProgram)

-(void)buildIRGLProgramWithPixelFormat:(IRPixelFormat)pixelFormat withViewprotRange:(CGRect)viewprotRange withParameter:(IRMediaParameter*)parameter{
    _program = [programFactory createIRGLProgramWithPixelFormat:pixelFormat withViewprotRange:viewprotRange withParameter:(IRMediaParameter*)parameter];
    [self.shiftController setProgram:self.program];
    [self setWideDegreeX:self.wideDegreeX];
    [self setWideDegreeY:self.wideDegreeY];
    [self setDefaultScale:self.defaultScale];
    [self setContentMode:self.contentMode];
    
    [self.delegate programDidCreate:_program];
}

@end

@interface IRGLView()<IRGLProgramDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) IRPlayerImp * abstractPlayer;
@property (nonatomic, strong) AVPlayerLayer * avplayerLayer;
@property (nonatomic, assign) BOOL avplayerLayerToken;
@end

@implementation IRGLView {
    EAGLContext     *_context;
    GLuint          _framebuffer;
    GLuint          _renderbuffer;
    
    GLint           _backingWidth;
    GLint           _backingHeight;
    GLint           _viewportWidth;
    GLint           _viewportHeight;
    
    dispatch_queue_t queue;
    IRPixelFormat irPixelFormat;
    
    NSArray *_programs;
    IRGLProgram2D *_currentProgram;
    
    BOOL isGLRenderContentModeChangable;
    BOOL isTouchedInProgram;
    BOOL willDoSnapshot;
    UITapGestureRecognizer *tapGr;
    
    IRGLRenderMode* mode;
    NSArray<IRGLRenderMode*>* _modes;
    CGRect viewprotRange;
}

+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0, 0, 1, 1);
        [self initDefaultValue];
        irPixelFormat = YUV_IRPixelFormat;
        [self initGLWithPixelFormat:irPixelFormat];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initDefaultValue];
        irPixelFormat = YUV_IRPixelFormat;
        [self initGLWithPixelFormat:irPixelFormat];
    }
    return self;
}

- (id) initWithFrame:(CGRect)frame
             decoder: (IRMovieDecoder *) decoder
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initDefaultValue];
        [self initGLWithIRMovieDecoder:decoder];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
         withPlayer:(IRPlayerImp *)abstractPlayer
{
    self = [super initWithFrame:frame];
    if (self) {
        self.abstractPlayer = abstractPlayer;
        [self initDefaultValue];
//        [self initGLWithIRMovieDecoder:decoder];
        irPixelFormat = YUV_IRPixelFormat;
        [self initGLWithPixelFormat:irPixelFormat];
    }
    
    return self;
}

-(void)initDefaultValue{
    _modes = [NSArray array];
}

-(void)initGLWithIRMovieDecoder: (IRMovieDecoder *) decoder{
    if ([decoder setupVideoFrameFormat:IRFrameFormatYUV]) {
        irPixelFormat = YUV_IRPixelFormat;
    } else {
        irPixelFormat = RGB_IRPixelFormat;
    }
    
    [self initGLWithPixelFormat:irPixelFormat];
}

-(void)initGLWithPixelFormat:(IRPixelFormat)irPixelFormat{
    [self initRenderQueue];
    
    [CATransaction flush];
    
    [EAGLContext setCurrentContext:_context];
    
    CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
    
    dispatch_sync(queue, ^{
        [self reset];
        
        eaglLayer.contentsScale = [[UIScreen mainScreen] scale];
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
                                        kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                        nil];
        
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
        if(!_context)
            _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        if (!_context ||
            ![EAGLContext setCurrentContext:_context]) {
            
            NSLog(@"failed to setup EAGLContext");
            return;
        }
        
        glGenFramebuffers(1, &_framebuffer);
        glGenRenderbuffers(1, &_renderbuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
        [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderbuffer);
        
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        if (status != GL_FRAMEBUFFER_COMPLETE) {
            
            NSLog(@"failed to make complete framebuffer object %x", status);
            return;
        }
        
        GLenum glError = glGetError();
        if (GL_NO_ERROR != glError) {
            NSLog(@"failed to setup GL %x", glError);
            return;
        }
    });
    
    viewprotRange = CGRectMake(0, 0, _backingWidth, _backingHeight);
    
    [self setupModes];
    
    NSLog(@"OK setup GL");
}

-(void)closeGLView{
    if(queue){
        dispatch_sync(queue, ^{
            [EAGLContext setCurrentContext:_context];
            [self reset];
        });
    }
}

//For NV12, This is important that need to glDeleteFramebuffers and glDeleteRenderbuffers before set _renderer = nil.
//If not, when change live view's resolustion, it render nothing. The reason is unknown.
-(void)reset{
    if (_framebuffer) {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }
    
    if (_renderbuffer) {
        glClear(GL_COLOR_BUFFER_BIT);
        glDeleteRenderbuffers(1, &_renderbuffer);
        _renderbuffer = 0;
    }
    
    if (_programs) {
        for(IRGLProgram2D *program in _programs){
            if (program) {
                [program releaseProgram];
            }
        }
        _programs = nil;
    }
    
    if ([EAGLContext currentContext] == _context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    _context = nil;
}

-(void)initRenderQueue{
    if(!queue)
        queue = dispatch_queue_create("render.queue", DISPATCH_QUEUE_SERIAL);
}

- (void) setDecoder: (VideoDecoder *) decoder
{
    irPixelFormat = NV12_IRPixelFormat;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self initGLWithPixelFormat:irPixelFormat];
    });
}

- (void) setPixelFormat: (IRPixelFormat) pixelFormat
{
    irPixelFormat = pixelFormat;
    
    [self initGLWithPixelFormat:irPixelFormat];
}

//Not consider Multi program status yet.
-(BOOL)isProgramZooming{
    return _currentProgram && !CGPointEqualToPoint([_currentProgram getCurrentScale], CGPointMake(1.0,1.0));
}

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    if ((!self.doubleTapEnable || ![self isProgramZooming]) && gestureRecognizer == tapGr){
        return NO;
    }else if([gestureRecognizer isKindOfClass:[UISwipeGestureRecognizer class]] && [self isProgramZooming]){
        return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]  && [otherGestureRecognizer isKindOfClass:[UISwipeGestureRecognizer class]] && (self.swipeEnable && ![self isProgramZooming])) {
        return YES;
    } else {
        return NO;
    }
}

- (void)dealloc
{
    [self reset];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self updateViewPort:1.0];
}

- (void)updateViewPort:(float)viewportScale{
    if(!queue)
        return;
    
    [CATransaction flush];
    
    dispatch_sync(queue, ^{
        
        [EAGLContext setCurrentContext:_context];
        CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
        eaglLayer.contentsScale = viewportScale * [[UIScreen mainScreen] scale];
        glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
        [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
        NSLog(@"_backingWidth:%d",_backingWidth);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderbuffer);
    });
    
    [self resetAllViewport:_backingWidth :_backingHeight resetTransform:YES];
}

- (void)setContentMode:(UIViewContentMode)contentMode
{
    [super setContentMode:contentMode];
    
    if(isGLRenderContentModeChangable)
        [self changeGLRenderContentMode];
}

- (void)changeGLRenderContentMode{
    IRGLRenderContentMode irGLViewContentMode;
    
    switch (self.contentMode) {
        case UIViewContentModeScaleAspectFit:
            irGLViewContentMode = IRGLRenderContentModeScaleAspectFit;
        case UIViewContentModeScaleAspectFill:
            irGLViewContentMode = IRGLRenderContentModeScaleAspectFill;
            break;
        case UIViewContentModeScaleToFill:
            irGLViewContentMode = IRGLRenderContentModeScaleToFill;
            break;
        default:
            irGLViewContentMode = IRGLRenderContentModeScaleAspectFit;
            break;
    }
    
    for(IRGLProgram2D *program in _programs){
        program.contentMode = irGLViewContentMode;
    }
}

-(void) resetAllViewport:(float)w :(float)h resetTransform:(BOOL)resetTransform{
    if(self.delegate)
        [self.delegate glViewWillBeginZooming:nil];
    
    viewprotRange = CGRectMake(0, 0, w, h);
    
    for(IRGLProgram2D *program in _programs){
        [program setViewprotRange:CGRectMake(0, 0, w, h) resetTransform:NO];
    }
    [self render:nil];
    
    if(self.delegate)
        [self.delegate glViewDidEndZooming:nil atScale:0];
}

-(void) updateScopeByFx:(float)fx fy:(float)fy dsx:(float)dsx dsy:(float) dsy
{
    if(self.delegate)
        [self.delegate glViewWillBeginZooming:nil];
    
    [_currentProgram didPinchByfx:fx fy:fy dsx:dsx dsy:dsy];
    [self render:nil];
    
    if(self.delegate)
        [self.delegate glViewDidEndZooming:nil atScale:0];
}

-(void) scrollByDx:(float)dx dy:(float)dy
{
    [_currentProgram didPanBydx:dx dy:dy];
    [self render:nil];
}

-(void) scrollByDegreeX:(float)degreex degreey:(float)degreey
{
    [_currentProgram didPanByDegreeX:degreex degreey:degreey];
    [self render:nil];
}

- (void)render: (IRFFVideoFrame *) frame
{
    if(!queue || !_currentProgram)
        return;
    
    dispatch_sync(queue, ^{
        [EAGLContext setCurrentContext:_context];
        glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
        
        if (frame) {
            [_currentProgram setRenderFrame:frame];
        }
        
        [_currentProgram clearBuffer];
        
        //        NSDate *methodStart = [NSDate date];
        [_currentProgram render];
        
        //        glFinish();
        
        glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
        [_context presentRenderbuffer:GL_RENDERBUFFER];
        
        //        NSDate *methodFinish = [NSDate date];
        //        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
        //                NSLog(@"executionTime = %f", executionTime);
        
        [self saveSnapShot];
    });
}

- (void)setRenderModes:(NSArray<IRGLRenderMode*>*) modes{
    _modes = modes;
    
    [self initGLWithPixelFormat:irPixelFormat];
}

- (void)initModes {
    NSMutableArray* array = [NSMutableArray array];
    if(_modes.count == 0) {
        _modes = [IRGLRenderModeFactory createNormalModesWithParameter:nil];
    }
    
    for(IRGLRenderMode* m in _modes){
        [m buildIRGLProgramWithPixelFormat:irPixelFormat withViewprotRange:viewprotRange withParameter:m.parameter];
        if(m.program)
            [array addObject:m.program];
    }
    
    _programs = [NSArray arrayWithArray:array];
}

- (void)setupModes {
    [self initModes];
    
    dispatch_sync(queue, ^{
        
        [EAGLContext setCurrentContext:_context];
        
        for(IRGLProgram2D *program in _programs){
            //        program.tramsformController.delegate = self;
//            program.delegate = self;
            
            if (![program loadShaders]) {
                return;
            }
        }
    });
    self.contentMode = UIViewContentModeScaleAspectFit;
    [self setContentMode:self.contentMode];
    
    [self chooseRenderMode:[_modes firstObject] withImmediatelyRenderOnce:NO];
}

- (NSArray*)getRenderModes{
    return _modes;
}

- (IRGLRenderMode*)getCurrentRenderMode{
    return mode;
}

- (BOOL)chooseRenderMode:(IRGLRenderMode*)renderMode withImmediatelyRenderOnce:(BOOL)immediatelyRenderOnce{
    if(!queue)
        return NO;
    
    if(![_modes containsObject:renderMode])
        return NO;
    
    dispatch_sync(queue, ^{
        mode = renderMode;
        _currentProgram = mode.program;
        [mode.shiftController setProgram:_currentProgram];
        
        if(immediatelyRenderOnce){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self render:nil];
            });
        }
    });
    
    return YES;
}

-(void) clearCanvas{
    if(!queue || !_currentProgram)
        return;
    
    dispatch_sync(queue, ^{
        [EAGLContext setCurrentContext:_context];
        glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
        
        [_currentProgram clearBuffer];
        
        glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
        [_context presentRenderbuffer:GL_RENDERBUFFER];
    });
}

-(void) doSnapShot
{
    willDoSnapshot = YES;
}

-(void) saveSnapShot{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(willDoSnapshot){
            [self saveSnapshotAlbum:[self createImageFromFramebuffer]];
            willDoSnapshot = NO;
        }
    });
}

-(void) saveSnapshotAlbum:(UIImage *) _snap
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library writeImageToSavedPhotosAlbum:_snap.CGImage orientation:(ALAssetOrientation)_snap.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error )
     {
         //            NSLog(@"IMAGE SAVED TO PHOTO ALBUM");
         [library assetForURL:assetURL
                  resultBlock:^(ALAsset *asset )
          {
              [library enumerateGroupsWithTypes:ALAssetsGroupAlbum
                                     usingBlock:^(ALAssetsGroup *group, BOOL *stop)
               {
                   
               }
                                   failureBlock:^(NSError *error)
               {
                   NSLog(@"Error:%@",error.localizedDescription);
               }];
              
              //                  NSLog(@"we have our ALAsset!");
          }
          
                 failureBlock:^(NSError *error )
          {
              NSLog(@"Error loading asset");
          }];
     }];
}


- (UIImage *)createImageFromFramebuffer {
    UIImage* imgRtn;
    CGSize size = [self.layer bounds].size;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGRect containerRect = [self.layer bounds];
    [self drawViewHierarchyInRect:containerRect afterScreenUpdates:NO];
    imgRtn = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return imgRtn;
}

typedef NS_ENUM(NSInteger, IRScrollDirectionType){
    None, //default
    Left,
    Right,
    Up,
    Down
};

- (void)cleanEmptyBuffer
{
//    [self cleanTexture];
//    
//    if ([NSThread isMainThread]) {
//        [self displayAndClear:YES];
//    } else {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self displayAndClear:YES];
//        });
//    }
}

- (void)decoder:(IRFFDecoder *)decoder renderVideoFrame:(IRFFVideoFrame *)videoFrame {
    [self render:videoFrame];
}

- (void)setRendererType:(IRDisplayRendererType)rendererType
{
    if (_rendererType != rendererType) {
        _rendererType = rendererType;
        [self reloadView];
    }
}

- (void)reloadView
{
    [self cleanViewIgnore];
    switch (self.rendererType) {
        case IRDisplayRendererTypeEmpty:
            break;
        case IRDisplayRendererTypeAVPlayerLayer:
            if (!self.avplayerLayer) {
                self.avplayerLayer = [AVPlayerLayer playerLayerWithPlayer:nil];
                [self reloadIRAVPlayer];
                self.avplayerLayerToken = NO;
                [self.layer insertSublayer:self.avplayerLayer atIndex:0];
                [self reloadGravityMode];
            }
            break;
        case IRDisplayRendererTypeAVPlayerPixelBufferVR:
//            if (!self.avplayerView) {
//                self.avplayerView = [IRGLAVView viewWithDisplayView:self];
//                IRPLFViewInsertSubview(self, self.avplayerView, 0);
//            }
            break;
        case IRDisplayRendererTypeFFmpegPexelBuffer:
        case IRDisplayRendererTypeFFmpegPexelBufferVR:
//            if (!self.ffplayerView) {
//                self.ffplayerView = [IRGLFFView viewWithDisplayView:self];
//                IRPLFViewInsertSubview(self, self.ffplayerView, 0);
//            }
            break;
    }
    [self updateDisplayViewLayout:self.bounds];
}

- (void)reloadGravityMode
{
    if (self.avplayerLayer) {
        switch (self.abstractPlayer.viewGravityMode) {
            case IRGravityModeResize:
                self.avplayerLayer.videoGravity = AVLayerVideoGravityResize;
                break;
            case IRGravityModeResizeAspect:
                self.avplayerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
                break;
            case IRGravityModeResizeAspectFill:
                self.avplayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                break;
        }
    }
}

- (void)updateDisplayViewLayout:(CGRect)frame
{
    if (self.avplayerLayer) {
        self.avplayerLayer.frame = frame;
        if (self.abstractPlayer.viewAnimationHidden || !self.avplayerLayerToken) {
            [self.avplayerLayer removeAllAnimations];
            self.avplayerLayerToken = YES;
        }
    }
//    if (self.avplayerView) {
//        [self.avplayerView reloadViewport];
//    }
//    if (self.ffplayerView) {
//        [self.ffplayerView reloadViewport];
//    }
}

- (void)reloadIRAVPlayer
{
#if IRPLATFORM_TARGET_OS_MAC
    self.avplayerLayer.player = self.sgavplayer.avPlayer;
#elif IRPLATFORM_TARGET_OS_IPHONE_OR_TV
    if (self.avplayer.avPlayer && [UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
        self.avplayerLayer.player = self.avplayer.avPlayer;
    } else {
        self.avplayerLayer.player = nil;
    }
#endif
}

- (void)cleanView
{
    [self cleanViewCleanAVPlayerLayer:YES cleanAVPlayerView:YES cleanFFPlayerView:YES];
}

- (void)cleanViewIgnore
{
    switch (self.rendererType) {
        case IRDisplayRendererTypeEmpty:
            [self cleanView];
            break;
        case IRDisplayRendererTypeAVPlayerLayer:
            [self cleanViewCleanAVPlayerLayer:NO cleanAVPlayerView:YES cleanFFPlayerView:YES];
            break;
        case IRDisplayRendererTypeAVPlayerPixelBufferVR:
            [self cleanViewCleanAVPlayerLayer:YES cleanAVPlayerView:NO cleanFFPlayerView:YES];
            break;
        case IRDisplayRendererTypeFFmpegPexelBuffer:
        case IRDisplayRendererTypeFFmpegPexelBufferVR:
            [self cleanViewCleanAVPlayerLayer:YES cleanAVPlayerView:YES cleanFFPlayerView:NO];
            break;
    }
}

- (void)cleanViewCleanAVPlayerLayer:(BOOL)cleanAVPlayerLayer cleanAVPlayerView:(BOOL)cleanAVPlayerView cleanFFPlayerView:(BOOL)cleanFFPlayerView
{
    [self cleanEmptyBuffer];
    if (cleanAVPlayerLayer && self.avplayerLayer) {
        [self.avplayerLayer removeFromSuperlayer];
        self.avplayerLayer = nil;
    }
//    if (cleanAVPlayerView && self.avplayerView) {
//        [self.avplayerView invalidate];
//        [self.avplayerView removeFromSuperview];
//        self.avplayerView = nil;
//    }
//    if (cleanFFPlayerView && self.ffplayerView) {
//        [self.ffplayerView removeFromSuperview];
//        self.ffplayerView = nil;
//    }
    self.avplayerLayerToken = NO;
}


@end
