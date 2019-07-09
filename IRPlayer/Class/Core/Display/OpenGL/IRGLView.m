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
#import <pthread.h>
#include <sys/time.h>

@interface IRGLRenderMode(BuildIRGLProgram)

-(IRGLProgram2D*)getProgram;
@end

@implementation IRGLRenderMode(BuildIRGLProgram)

-(IRGLProgram2D*)getProgram{
    return program;
}

-(void)buildIRGLProgramWithPixelFormat:(IRPixelFormat)pixelFormat withViewprotRange:(CGRect)viewprotRange withParameter:(IRMediaParameter*)parameter{
    
    program = [programFactory createIRGLProgramWithPixelFormat:pixelFormat withViewprotRange:viewprotRange withParameter:(IRMediaParameter*)parameter];
    [self.shiftController setProgram:program];
    [self setWideDegreeX:self.wideDegreeX];
    [self setWideDegreeY:self.wideDegreeY];
    [self setDefaultScale:self.defaultScale];
    [self setContentMode:self.contentMode];
}

@end

@interface IRGLView()<IRGLProgramDelegate, UIGestureRecognizerDelegate>

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
    
    //Smooth Scroll
    CGPoint finalPoint;
    CGPoint alreadyPoint;
    CGFloat slideDuration;
    CADisplayLink *timer;
    NSTimeInterval startTimestamp;
    NSTimeInterval lastTimestamp;
    CAShapeLayer *horizontalLineLayer, *verticalLineLayer;
    BOOL didHorizontalBoundsBonce, didVerticalBoundsBonce;
    BOOL isPaned;
}

+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initDefaultValue];
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

-(void)initDefaultValue{
    self.swipeEnable = YES;
    
    UIPanGestureRecognizer* gr = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                         action:@selector(didPan:)];
    gr.delegate = self;
    [self addGestureRecognizer:gr];
    
    UIPinchGestureRecognizer *pinchGr = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(didPinch:)];
    [self addGestureRecognizer:pinchGr];
    
    UIRotationGestureRecognizer *rotateGr = [[UIRotationGestureRecognizer alloc] initWithTarget:self
                                                                                         action:@selector(didRotate:)];
    [self addGestureRecognizer:rotateGr];
    
    tapGr = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(didDoubleTap:)];
    [tapGr setNumberOfTapsRequired:2];
    [self addGestureRecognizer:tapGr];
    
    tapGr.delegate = self;
    
    isTouchedInProgram = NO;
    
    self.doubleTapEnable = YES;
    
    _modes = [NSArray array];
    
    [self createLine];
    
    timer = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
    [timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)tick:(CADisplayLink *)sender {
    if (CGPointEqualToPoint(finalPoint, CGPointZero)) {
        return;
    }
    
    if(startTimestamp == 0) {
        startTimestamp = sender.timestamp;
    }
    
    CGFloat duration = MIN(slideDuration, sender.timestamp - startTimestamp);
    //    CGFloat persentage = pow(duration / slideDuration, 1);
    CGFloat persentage = duration / slideDuration;
    persentage = -1 * persentage*(persentage-2); // quadratic easing out
    /* //cubic easing out
     persentage -= 1;
     persentage = persentage*persentage*persentage + 1;
     */
    CGFloat moveX = finalPoint.x * persentage - alreadyPoint.x;
    CGFloat moveY = finalPoint.y * persentage - alreadyPoint.y;
    
    alreadyPoint.x += moveX;
    alreadyPoint.y += moveY;
    
    if(isPaned)
        [self scrollByDx:moveX*[[UIScreen mainScreen] scale] dy:-1*moveY*[[UIScreen mainScreen] scale]];
    else{
        [mode.shiftController shiftDegreeX:moveX degreeY:-1*moveY];
        [self render:nil];
    }
    
    if(CGPointEqualToPoint(finalPoint, alreadyPoint)){
        [self resetSmoothScroll];
        if(self.delegate)
            [self.delegate glViewDidEndDecelerating:self];
    }
}

-(void)resetSmoothScroll{
    finalPoint = CGPointZero;
    alreadyPoint = CGPointZero;
    startTimestamp = 0;
    didHorizontalBoundsBonce = NO;
    didVerticalBoundsBonce = NO;
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
    
    [self initModes];
    
    NSLog(@"OK setup GL");
}

-(void)closeGLView{
    if(timer){
        [timer invalidate];
        timer = nil;
    }
    
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

- (void)calculateSmoothScroll:(CGPoint)velocity {
    CGFloat magnitude = sqrtf((velocity.x * velocity.x) + (velocity.y * velocity.y));
    CGFloat slideMult = magnitude / 200;
    NSLog(@"magnitude: %f, slideMult: %f", magnitude, slideMult);
    
    float slideFactor = 0.05 * slideMult; // Increase for more of a slide
    finalPoint = CGPointMake(0 + (velocity.x * slideFactor),
                             0 + (velocity.y * slideFactor));
    slideDuration = slideFactor*2;
}

- (void)didPan:(UIPanGestureRecognizer*)gr
{
    NSLog(@"didPan, state %zd",gr.state);
    
    isPaned = YES;
    [self resetSmoothScroll];
    
    if ((UIGestureRecognizerStateCancelled == gr.state ||
         UIGestureRecognizerStateFailed == gr.state))
    {
        isTouchedInProgram = NO;
        
        if(self.delegate)
            [self.delegate glViewDidEndDragging:self willDecelerate:NO];
    }
    else if(UIGestureRecognizerStateEnded == gr.state){
        isTouchedInProgram = NO;
        
        CGPoint velocity = [gr velocityInView:self];
        [self calculateSmoothScroll:velocity];
        
        if(self.delegate)
            [self.delegate glViewDidEndDragging:self willDecelerate:CGPointEqualToPoint(velocity, CGPointZero)];
    }
    else if(UIGestureRecognizerStateBegan == gr.state){
        CGPoint touchedPoint = [gr locationInView:self];
        touchedPoint.x *= [UIScreen mainScreen].scale;
        touchedPoint.y = self.frame.size.height - touchedPoint.y;
        touchedPoint.y *= [UIScreen mainScreen].scale;
        isTouchedInProgram = [_currentProgram touchedInProgram:touchedPoint];
    }else{
        if(!isTouchedInProgram)
            return;
        
        if(self.delegate)
            [self.delegate glViewWillBeginDragging:self];
        
        CGPoint screenOffset = [(UIPanGestureRecognizer*)gr translationInView:self];
        
        [self scrollByDx:screenOffset.x*[[UIScreen mainScreen] scale] dy:-1*screenOffset.y*[[UIScreen mainScreen] scale]];
        
        [(UIPanGestureRecognizer*)gr setTranslation:CGPointZero inView:self];
    }
}

- (void)didPinch:(UIPinchGestureRecognizer*)sender{
    NSLog(@"didPinch %f state %zd",sender.scale,sender.state);
    
    if ((UIGestureRecognizerStateCancelled == sender.state ||
         UIGestureRecognizerStateEnded == sender.state ||
         UIGestureRecognizerStateFailed == sender.state))
    {
        isTouchedInProgram = NO;
    }else if(UIGestureRecognizerStateBegan == sender.state){
        CGPoint touchedPoint = [sender locationInView:self];
        touchedPoint.x *= [UIScreen mainScreen].scale;
        touchedPoint.y = self.frame.size.height - touchedPoint.y;
        touchedPoint.y *= [UIScreen mainScreen].scale;
        isTouchedInProgram = [_currentProgram touchedInProgram:touchedPoint];
    }else{
        if(!isTouchedInProgram)
            return;
        if(sender.numberOfTouches < 2)
            return;
        
        CGPoint p1 = [sender locationOfTouch:0 inView:self];
        CGPoint p2 = [sender locationOfTouch:1 inView:self];
        
        [self updateScopeByFx:(p1.x + p2.x) / 2 fy:(p1.y + p2.y) / 2 dsx:sender.scale dsy:sender.scale];
        
        sender.scale = 1;
    }
}

- (void)didRotate:(UIRotationGestureRecognizer*)gr
{
    NSLog(@"didRotate, state %zd",gr.state);
    if ((UIGestureRecognizerStateCancelled == gr.state ||
         UIGestureRecognizerStateEnded == gr.state ||
         UIGestureRecognizerStateFailed == gr.state))
    {
        isTouchedInProgram = NO;
    }
    else if(UIGestureRecognizerStateBegan == gr.state){
        CGPoint touchedPoint = [gr locationInView:self];
        touchedPoint.x *= [UIScreen mainScreen].scale;
        touchedPoint.y = self.frame.size.height - touchedPoint.y;
        touchedPoint.y *= [UIScreen mainScreen].scale;
        isTouchedInProgram = [_currentProgram touchedInProgram:touchedPoint];
    }else{
        if(!isTouchedInProgram)
            return;
        
        if(self.delegate)
            [self.delegate glViewWillBeginDragging:nil];
        
        NSLog(@"rotate:%f",gr.rotation);
        
        [self updateRotation:gr.rotation];
        
        gr.rotation = 0;
        
        if(self.delegate)
            [self.delegate glViewDidEndDragging:nil willDecelerate:NO];
        
        //    if(self.delegate)
        //        [self.delegate scrollViewDidEndDecelerating:nil];
    }
}

- (void)didDoubleTap:(UITapGestureRecognizer*)gr
{
    NSLog(@"didDoubleTap, state %zd",gr.state);
    
    isTouchedInProgram = NO;
    
    CGPoint touchedPoint = [gr locationInView:self];
    touchedPoint.x *= [UIScreen mainScreen].scale;
    touchedPoint.y = self.frame.size.height - touchedPoint.y;
    touchedPoint.y *= [UIScreen mainScreen].scale;
    isTouchedInProgram = [_currentProgram touchedInProgram:touchedPoint];
    
    if(!isTouchedInProgram)
        return;
    
    _currentProgram.doResetToDefaultScaleBlock = ^BOOL(IRGLProgram2D *program) {
        if(CGPointEqualToPoint([program getCurrentScale], CGPointMake(1.0,1.0)))
            return NO;
        
        [program setDefaultScale:1.0];
        
        return YES;
    };
    
    [_currentProgram didDoubleTap];
    
    [mode update]; //It for multi_4P, not a good method, should modify future.
    
    [self render:nil];
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

-(void)shiftDegreeX:(float)degreeX degreeY:(float)degreeY{
    CGFloat unmoveYetX = finalPoint.x - alreadyPoint.x;
    CGFloat unmoveYetY = finalPoint.y - alreadyPoint.y;
    degreeX += unmoveYetX;
    degreeY += -1*unmoveYetY;
    
    [self resetSmoothScroll];
    isPaned = NO;
    
    finalPoint = CGPointMake(degreeX,
                             -1*degreeY);
    slideDuration = 0.5;
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

-(void) updateRotation:(float)rotateRadians{
    [_currentProgram didRotate: -1 * rotateRadians];
    [self render:nil];
}

- (void)render: (IRVideoFrame *) frame
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

-(void)initModes{
    NSMutableArray* array = [NSMutableArray array];
    for(IRGLRenderMode* m in _modes){
        [m buildIRGLProgramWithPixelFormat:irPixelFormat withViewprotRange:viewprotRange withParameter:m.parameter];
        if([m getProgram])
            [array addObject:[m getProgram]];
    }
    
    _programs = [NSArray arrayWithArray:array];
    
    dispatch_sync(queue, ^{
        
        [EAGLContext setCurrentContext:_context];
        
        for(IRGLProgram2D *program in _programs){
            //        program.tramsformController.delegate = self;
            program.delegate = self;
            
            if (![program loadShaders]) {
                return;
            }
        }
    });
    
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
        _currentProgram = [mode getProgram];
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

-(void)didScrollToBounds:(IRGLTransformControllerScrollToBounds)bounds withProgram:(IRGLProgram2D *)program;{
    CGFloat moveX = finalPoint.x - alreadyPoint.x;
    CGFloat moveY = finalPoint.y - alreadyPoint.y;
    
    IRScrollDirectionType scrollDirectionType = None;
    
    
    
    switch (bounds) {
        case IRGLTransformControllerScrollToHorizontalBounds:
            moveY = 0;
            break;
        case IRGLTransformControllerScrollToVerticalBounds:
            moveX = 0;
            break;
        case IRGLTransformControllerScrollToHorizontalandVerticalBounds:
            
            break;
            
        default:
            moveX = 0;
            moveY = 0;
            break;
    }
    
    if(moveX > 0)
        scrollDirectionType = Right;
    else if(moveX < 0)
        scrollDirectionType = Left;
    
    if(!didHorizontalBoundsBonce && (scrollDirectionType == Left || scrollDirectionType == Right)){
        [self removeAndAddAnimateWithScrollValue:moveX byScrollDirection:scrollDirectionType];
        didHorizontalBoundsBonce = YES;
    }
    
    if(moveY > 0)
        scrollDirectionType = Down;
    else if(moveY < 0)
        scrollDirectionType = Up;
    
    if(!didVerticalBoundsBonce && (scrollDirectionType == Up || scrollDirectionType == Down)){
        [self removeAndAddAnimateWithScrollValue:moveY byScrollDirection:scrollDirectionType];
        didVerticalBoundsBonce = YES;
    }
    
    if(self.delegate)
        [self.delegate glViewDidScrollToBounds:self];
}

- (void) createLine {
    horizontalLineLayer = [CAShapeLayer layer];
    horizontalLineLayer.strokeColor = [[UIColor colorWithWhite:0.333f alpha:0.5f] CGColor];
    horizontalLineLayer.lineWidth = 0.0;
    horizontalLineLayer.fillColor = [[UIColor colorWithWhite:0.333f alpha:0.5f] CGColor];
    [self.layer addSublayer:horizontalLineLayer];
    
    verticalLineLayer = [CAShapeLayer layer];
    verticalLineLayer.strokeColor = [[UIColor colorWithWhite:0.333f alpha:0.5f] CGColor];
    verticalLineLayer.lineWidth = 0.0;
    verticalLineLayer.fillColor = [[UIColor colorWithWhite:0.333f alpha:0.5f] CGColor];
    
    [self.layer addSublayer:verticalLineLayer];
}

-(void)removeAndAddAnimateWithScrollValue:(CGFloat)scrollValue byScrollDirection:(IRScrollDirectionType)type{
    NSString* key = nil;
    CAShapeLayer* lineLayer = nil;
    UIBezierPath* startPath = nil;
    UIBezierPath* endPath = nil;
    
    startPath = [self getLinePathWithAmount:scrollValue byScrollDirection:type];
    endPath = [self getLinePathWithAmount:0.0 byScrollDirection:type];
    
    switch (type) {
        case Left:{
            key = @"bounce_right";
            lineLayer = horizontalLineLayer;
            break;
        }
        case Right:{
            key = @"bounce_left";
            lineLayer = horizontalLineLayer;
            break;
        }
        case Up:{
            key = @"bounce_bottom";
            lineLayer = verticalLineLayer;
            break;
        }
        case Down:{
            key = @"bounce_top";
            lineLayer = verticalLineLayer;
            break;
        }
        default:
            return;
    }
    
    [lineLayer removeAnimationForKey:key];
    lineLayer.path = [startPath CGPath];
    
    CABasicAnimation *morph = [CABasicAnimation animationWithKeyPath:@"path"];
    morph.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    morph.fromValue = (id) lineLayer.path;
    morph.toValue = (id) [endPath CGPath];
    morph.duration = 0.2;
    morph.removedOnCompletion = NO;
    morph.fillMode = kCAFillModeForwards;
    //    morph.delegate = self;
    [lineLayer addAnimation:morph forKey:key];
}

- (UIBezierPath*) getLinePathWithAmount:(CGFloat)amount byScrollDirection:(IRScrollDirectionType)type{
    CGPoint startPoint = CGPointZero;
    CGPoint midControlPoint = CGPointZero;
    CGPoint endPoint = CGPointZero;
    CGFloat bounceWidth = MIN(self.bounds.size.width/10, self.bounds.size.height/10);
    
    switch (type) {
        case Left:{
            startPoint = CGPointMake(self.bounds.size.width , 0);
            midControlPoint = CGPointMake(MAX(self.bounds.size.width + amount, self.bounds.size.width - bounceWidth), self.bounds.size.height/2);
            endPoint = CGPointMake(self.bounds.size.width , self.bounds.size.height);
            break;
        }
        case Right:{
            
            startPoint = CGPointZero;
            midControlPoint = CGPointMake(MIN(amount, bounceWidth), self.bounds.size.height/2);
            endPoint = CGPointMake(0, self.bounds.size.height);
            break;
        }
        case Up:{
            startPoint = CGPointMake(0 , self.bounds.size.height);
            midControlPoint = CGPointMake(self.bounds.size.width/2, MAX(self.bounds.size.height + amount, self.bounds.size.height - bounceWidth));
            endPoint = CGPointMake(self.bounds.size.width, self.bounds.size.height);
            break;
        }
        case Down:{
            startPoint = CGPointZero;
            midControlPoint = CGPointMake(self.bounds.size.width/2, MIN(amount, bounceWidth));
            endPoint = CGPointMake(self.bounds.size.width, 0);
            break;
        }
        default:
            return nil;
    }
    
    UIBezierPath *verticalLine = [UIBezierPath bezierPath];
    [verticalLine moveToPoint:startPoint];
    [verticalLine addQuadCurveToPoint:endPoint controlPoint:midControlPoint];
    [verticalLine closePath];
    
    return verticalLine;
}

-(UIBezierPath*) getRightLinePathWithAmount:(CGFloat)amount{
    UIBezierPath *verticalLine = [UIBezierPath bezierPath];
    CGPoint topPoint = CGPointMake(self.bounds.size.width , 0);
    CGPoint midControlPoint = CGPointMake(self.bounds.size.width - amount, self.bounds.size.height/2);
    CGPoint bottomPoint = CGPointMake(self.bounds.size.width , self.bounds.size.height);
    
    [verticalLine moveToPoint:topPoint];
    [verticalLine addQuadCurveToPoint:bottomPoint controlPoint:midControlPoint];
    [verticalLine closePath];
    
    return verticalLine;
}

@end
