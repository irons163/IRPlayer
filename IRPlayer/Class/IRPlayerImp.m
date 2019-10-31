//
//  IRPlayer.m
//  IRPlayer
//
//  Created by Phil on 2019/7/5.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "IRPlayerImp.h"
#import "IRPlayerMacro.h"
#import "IRPlayerNotification.h"
#import "IRGLView.h"
#import "IRAVPlayer.h"
#import "IRFFPlayer.h"
#import "IRGLGestureController.h"
#import "IRGLRenderModeFactory.h"
#import "IRFisheyeParameter.h"
#import "IRSensor.h"
#import "IRSmoothScrollController.h"
#import "IRFFVideoInput+Private.h"

#if IRPLATFORM_TARGET_OS_IPHONE_OR_TV
#import "IRAudioManager.h"
#endif

@interface IRPlayerImp ()<IRGLViewDelegate>

@property (nonatomic, strong) IRGLView * displayView;
@property (nonatomic, assign) IRDecoderType decoderType;
@property (nonatomic, strong) IRAVPlayer * avPlayer;
@property (nonatomic, strong) IRFFPlayer * ffPlayer;
@property (nonatomic, strong) IRGLGestureController *gestureControl;
@property (nonatomic, strong) IRSensor *sensor;
@property (nonatomic, strong) IRSmoothScrollController *scrollController;

@property (nonatomic, assign) BOOL needAutoPlay;

@end

@implementation IRPlayerImp

+ (instancetype)player
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if (self = [super init]) {
#if IRPLATFORM_TARGET_OS_IPHONE_OR_TV
        [self setupNotification];
#endif
        self.decoder = [IRPlayerDecoder defaultDecoder];
        self.contentURL = nil;
        self.videoType = IRVideoTypeNormal;
        self.backgroundMode = IRPlayerBackgroundModeAutoPlayAndPause;
        self.displayMode = IRDisplayModeNormal;
        self.viewGravityMode = IRGravityModeResizeAspect;
        self.playableBufferInterval = 2.f;
        self.viewAnimationHidden = YES;
        self.volume = 1;
    }
    return self;
}

- (void)replaceEmpty
{
    [self replaceVideoWithURL:nil];
}

- (void)replaceVideoWithURL:(nullable NSURL *)contentURL
{
    [self replaceVideoWithURL:contentURL videoType:IRVideoTypeNormal];
}

- (void)replaceVideoWithURL:(nullable NSURL *)contentURL videoType:(IRVideoType)videoType
{
    self.error = nil;
    self.contentURL = contentURL;
    self.videoInput = nil;
    self.decoderType = [self.decoder decoderTypeForContentURL:self.contentURL];
    self.videoType = videoType;
    
    switch (self.decoderType) {
        case IRDecoderTypeAVPlayer:
            if (_ffPlayer) {
                [self.ffPlayer stop];
            }
            [self.avPlayer replaceVideo];
            break;
        case IRDecoderTypeFFmpeg:
            if (_avPlayer) {
                [self.avPlayer stop];
            }
            [self.ffPlayer replaceVideo];
            break;
        case IRDecoderTypeError:
            if (_avPlayer) {
                [self.avPlayer stop];
            }
            if (_ffPlayer) {
                [self.ffPlayer stop];
            }
            break;
    }
}

- (void)replaceVideoWithInput:(nullable IRFFVideoInput *)videoInput videoType:(IRVideoType)videoType
{
    self.error = nil;
    self.contentURL = [[NSURL alloc] init];
    self.videoInput = videoInput;
    if (self.videoInput) {
        self.videoInput.videoOutput = self.displayView;
    }
    self.decoderType = [self.decoder decoderTypeForContentURL:self.contentURL];
    self.videoType = videoType;
    
    switch (self.decoderType) {
        case IRDecoderTypeAVPlayer:
            if (_ffPlayer) {
                [self.ffPlayer stop];
            }
            [self.avPlayer replaceVideo];
            break;
        case IRDecoderTypeFFmpeg:
            if (_avPlayer) {
                [self.avPlayer stop];
            }
            [self.ffPlayer replaceVideo];
            break;
        case IRDecoderTypeError:
            if (_avPlayer) {
                [self.avPlayer stop];
            }
            if (_ffPlayer) {
                [self.ffPlayer stop];
            }
            break;
    }
}

- (void)play
{
#if IRPLATFORM_TARGET_OS_IPHONE_OR_TV
    [UIApplication sharedApplication].idleTimerDisabled = YES;
#endif
    
    switch (self.decoderType) {
        case IRDecoderTypeAVPlayer:
            [self.avPlayer play];
            break;
        case IRDecoderTypeFFmpeg:
            [self.ffPlayer play];
            break;
        case IRDecoderTypeError:
            break;
    }
}

- (void)pause
{
#if IRPLATFORM_TARGET_OS_IPHONE_OR_TV
    [UIApplication sharedApplication].idleTimerDisabled = NO;
#endif
    
    switch (self.decoderType) {
        case IRDecoderTypeAVPlayer:
            [self.avPlayer pause];
            break;
        case IRDecoderTypeFFmpeg:
            [self.ffPlayer pause];
            break;
        case IRDecoderTypeError:
            break;
    }
}

- (void)seekToTime:(NSTimeInterval)time
{
    [self seekToTime:time completeHandler:nil];
}

- (void)seekToTime:(NSTimeInterval)time completeHandler:(nullable void (^)(BOOL))completeHandler
{
    switch (self.decoderType) {
        case IRDecoderTypeAVPlayer:
            [self.avPlayer seekToTime:time completeHandler:completeHandler];
            break;
        case IRDecoderTypeFFmpeg:
            [self.ffPlayer seekToTime:time completeHandler:completeHandler];
            break;
        case IRDecoderTypeError:
            break;
    }
}

- (void)updateGraphicsViewFrame:(CGRect)frame {
    [self.displayView updateFrameFromParent:frame];
}

- (void)setContentURL:(NSURL *)contentURL
{
    _contentURL = [contentURL copy];
}

- (void)setVideoType:(IRVideoType)videoType
{
    switch (videoType) {
        case IRVideoTypeNormal:
            _videoType = videoType;
            [self.displayView setRenderModes:[IRGLRenderModeFactory createNormalModesWithParameter:nil]];
            _gestureControl.currentMode = [self.displayView getCurrentRenderMode];
            break;
        case IRVideoTypeVR: {
            _videoType = videoType;
            if (self.displayMode == IRDisplayModeNormal) {
                IRGLRenderMode *mode = [IRGLRenderModeFactory createVRModeWithParameter:nil];
                [mode setDefaultScale:1.5f];
                mode.aspect = 16.0 / 9.0;
                [self.displayView setRenderModes:@[mode]];
            } else if (self.displayMode == IRDisplayModeBox) {
                IRGLRenderMode *mode = [IRGLRenderModeFactory createDistortionModeWithParameter:nil];
                [mode setDefaultScale:1.5f];
                mode.aspect = 16.0 / 9.0;
                [self.displayView setRenderModes:@[mode]];
                [_gestureControl removeGestureToView:self.displayView];
                _sensor = [[IRSensor alloc] init];
                _sensor.targetView = self.displayView;
                _sensor.smoothScroll = _gestureControl.smoothScroll;
                [_sensor resetUnit];
            }
            [self setViewGravityMode:IRGravityModeResizeAspect];
            _gestureControl.currentMode = [self.displayView getCurrentRenderMode];
            break;
        }
        case IRVideoTypeFisheye: {
            _videoType = videoType;
            IRGLRenderMode *mode = [IRGLRenderModeFactory createFisheyeModeWithParameter:[[IRFisheyeParameter alloc] initWithWidth:0 height:0 up:NO rx:0 ry:0 cx:0 cy:0 latmax:80]];
            [mode setDefaultScale:1.5f];
            mode.aspect = 16.0 / 9.0;
            [self.displayView setRenderModes:@[mode]];
            [self setViewGravityMode:IRGravityModeResizeAspect];
            _gestureControl.currentMode = [self.displayView getCurrentRenderMode];
            break;
        }
        case IRVideoTypePano: {
            _videoType = videoType;
            IRGLRenderMode *mode = [IRGLRenderModeFactory createPanoramaModeWithParameter:nil];
            [self.displayView setRenderModes:@[mode]];
            _gestureControl.currentMode = [self.displayView getCurrentRenderMode];
            break;
        }
        case IRVideoTypeCustom: {
            _videoType = videoType;
            _gestureControl.currentMode = [self.displayView getCurrentRenderMode];
            break;
        }
        default:
            _videoType = IRVideoTypeNormal;
            [self.displayView setRenderModes:[IRGLRenderModeFactory createNormalModesWithParameter:nil]];
            _gestureControl.currentMode = [self.displayView getCurrentRenderMode];
            break;
    }
}

- (void)setVolume:(CGFloat)volume
{
    _volume = volume;
    if (_avPlayer) {
        [self.avPlayer reloadVolume];
    }
    if (_ffPlayer) {
        [self.ffPlayer reloadVolume];
    }
}

- (void)setPlayableBufferInterval:(NSTimeInterval)playableBufferInterval
{
    _playableBufferInterval = playableBufferInterval;
    if (_ffPlayer) {
        [self.ffPlayer reloadPlayableBufferInterval];
    }
}

- (void)setViewGravityMode:(IRGravityMode)viewGravityMode
{
    _viewGravityMode = viewGravityMode;
    [self.displayView reloadGravityMode];
}

- (void)setRenderModes:(NSArray<IRGLRenderMode *> *)renderModes {
    [self.displayView setRenderModes:renderModes];
}

- (NSArray<IRGLRenderMode *> *)renderModes {
    return [self.displayView getRenderModes];
}

- (void)selectRenderMode:(IRGLRenderMode *)renderMode {
    [self.displayView chooseRenderMode:renderMode withImmediatelyRenderOnce:YES];
    _gestureControl.currentMode = [self.displayView getCurrentRenderMode];
}

- (IRPlayerState)state
{
    switch (self.decoderType) {
        case IRDecoderTypeAVPlayer:
            return self.avPlayer.state;
        case IRDecoderTypeFFmpeg:
            return self.ffPlayer.state;
        case IRDecoderTypeError:
            return IRPlayerStateNone;
    }
}

- (CGSize)presentationSize
{
    switch (self.decoderType) {
        case IRDecoderTypeAVPlayer:
            return self.avPlayer.presentationSize;
        case IRDecoderTypeFFmpeg:
            return self.ffPlayer.presentationSize;
        case IRDecoderTypeError:
            return CGSizeZero;
    }
}

- (NSTimeInterval)bitrate
{
    switch (self.decoderType) {
        case IRDecoderTypeAVPlayer:
            return self.avPlayer.bitrate;
        case IRDecoderTypeFFmpeg:
            return self.ffPlayer.bitrate;
        case IRDecoderTypeError:
            return 0;
    }
}

- (NSTimeInterval)progress
{
    switch (self.decoderType) {
        case IRDecoderTypeAVPlayer:
            return self.avPlayer.progress;
        case IRDecoderTypeFFmpeg:
            return self.ffPlayer.progress;
        case IRDecoderTypeError:
            return 0;
    }
}

- (NSTimeInterval)duration
{
    switch (self.decoderType) {
        case IRDecoderTypeAVPlayer:
            return self.avPlayer.duration;
        case IRDecoderTypeFFmpeg:
            return self.ffPlayer.duration;
        case IRDecoderTypeError:
            return 0;
    }
}

- (NSTimeInterval)playableTime
{
    switch (self.decoderType) {
        case IRDecoderTypeAVPlayer:
            return self.avPlayer.playableTime;
        case IRDecoderTypeFFmpeg:
            return self.ffPlayer.playableTime;
        case IRDecoderTypeError:
            return 0;
    }
}

- (IRPLFImage *)snapshot
{
//    return self.displayView.snapshot;
    return nil;
}

- (BOOL)seeking
{
    switch (self.decoderType) {
        case IRDecoderTypeAVPlayer:
            return self.avPlayer.seeking;
        case IRDecoderTypeFFmpeg:
            return self.ffPlayer.seeking;
        case IRDecoderTypeError:
            return NO;
    }
}

- (IRPLFView *)view
{
    return self.displayView;
}

- (IRGLView *)displayView
{
    if (!_displayView) {
//        _displayView = [IRGLView displayViewWithAbstractPlayer:self];
        _displayView = [[IRGLView alloc] init];
        
        _scrollController = [[IRSmoothScrollController alloc] initWithTargetView:_displayView];
        _scrollController.currentMode = [_displayView getCurrentRenderMode];
        _scrollController.delegate = self;
        
        _gestureControl = [IRGLGestureController new];
        [_gestureControl addGestureToView:_displayView];
        _gestureControl.currentMode = [_displayView getCurrentRenderMode];
        _gestureControl.smoothScroll = _scrollController;
        _gestureControl.delegate = self;
    }
    return _displayView;
}

- (IRAVPlayer *)avPlayer
{
    if (!_avPlayer) {
        _avPlayer = [IRAVPlayer playerWithAbstractPlayer:self];
    }
    return _avPlayer;
}

- (IRFFPlayer *)ffPlayer
{
    if (!_ffPlayer) {
        _ffPlayer = [IRFFPlayer playerWithAbstractPlayer:self];
    }
    return _ffPlayer;
}

- (void)setupPlayerView:(IRPLFView *)playerView;
{
    [self cleanPlayerView];
    if (playerView) {
        [self.view addSubview:playerView];
        
        playerView.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSLayoutConstraint * top = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0];
        NSLayoutConstraint * bottom = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
        NSLayoutConstraint * left = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
        NSLayoutConstraint * right = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:0];
        
        [self.view addConstraint:top];
        [self.view addConstraint:bottom];
        [self.view addConstraint:left];
        [self.view addConstraint:right];
    }
}

- (void)setVideoInput:(IRFFVideoInput * _Nullable)videoInput {
    _videoInput = videoInput;
}

- (void)setError:(IRError * _Nullable)error
{
    if (self.error != error) {
        self->_error = error;
    }
}

- (void)cleanPlayer
{
    if (_avPlayer) {
        [self.avPlayer stop];
        self.avPlayer = nil;
    }
    if (_ffPlayer) {
        [self.ffPlayer stop];
        self.ffPlayer = nil;
    }
    if(_gestureControl) {
        [_gestureControl removeGestureToView:_displayView];
        self.gestureControl = nil;
    }
    if(_displayView) {
        [_displayView closeGLView];
    }
    
    [self cleanPlayerView];
    
#if IRPLATFORM_TARGET_OS_IPHONE_OR_TV
    [UIApplication sharedApplication].idleTimerDisabled = NO;
#endif
    
    self.needAutoPlay = NO;
    self.error = nil;
}

- (void)cleanPlayerView
{
    [self.view.subviews enumerateObjectsUsingBlock:^(__kindof IRPLFView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
}

- (void)dealloc
{
    IRPlayerLog(@"IRPlayer release");
    [self cleanPlayer];
    
#if IRPLATFORM_TARGET_OS_IPHONE_OR_TV
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[IRAudioManager manager] removeHandlerTarget:self];
#endif
}

#pragma mark - background mode

#if IRPLATFORM_TARGET_OS_IPHONE_OR_TV
- (void)setupNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    @weakify(self)
    IRAudioManager * manager = [IRAudioManager manager];
    [manager setHandlerTarget:self interruption:^(id handlerTarget, IRAudioManager *audioManager, IRAudioManagerInterruptionType type, IRAudioManagerInterruptionOption option) {
        @strongify(self)
        if (type == IRAudioManagerInterruptionTypeBegin) {
            switch (self.state) {
                case IRPlayerStatePlaying:
                case IRPlayerStateBuffering:
                {
                    [self pause];
                }
                    break;
                default:
                    break;
            }
        }
    } routeChange:^(id handlerTarget, IRAudioManager *audioManager, IRAudioManagerRouteChangeReason reason) {
        @strongify(self)
        if (reason == IRAudioManagerRouteChangeReasonOldDeviceUnavailable) {
            switch (self.state) {
                case IRPlayerStatePlaying:
                case IRPlayerStateBuffering:
                {
                    [self pause];
                }
                    break;
                default:
                    break;
            }
        }
    }];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    switch (self.backgroundMode) {
        case IRPlayerBackgroundModeNothing:
        case IRPlayerBackgroundModeContinue:
            break;
        case IRPlayerBackgroundModeAutoPlayAndPause:
        {
            switch (self.state) {
                case IRPlayerStatePlaying:
                case IRPlayerStateBuffering:
                {
                    self.needAutoPlay = YES;
                    [self pause];
                }
                    break;
                default:
                    break;
            }
        }
            break;
    }
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    switch (self.backgroundMode) {
        case IRPlayerBackgroundModeNothing:
        case IRPlayerBackgroundModeContinue:
            break;
        case IRPlayerBackgroundModeAutoPlayAndPause:
        {
            switch (self.state) {
                case IRPlayerStateSuspend:
                {
                    if (self.needAutoPlay) {
                        self.needAutoPlay = NO;
                        [self play];
                    }
                }
                    break;
                default:
                    break;
            }
        }
            break;
    }
}
#endif

@end


#pragma mark - Tracks Category

@implementation IRPlayerImp (Tracks)

- (BOOL)videoEnable
{
    switch (self.decoderType) {
        case IRDecoderTypeAVPlayer:
            return self.avPlayer.videoEnable;
        case IRDecoderTypeFFmpeg:
            return self.ffPlayer.videoEnable;
        case IRDecoderTypeError:
            return NO;
    }
}

- (BOOL)audioEnable
{
    switch (self.decoderType) {
        case IRDecoderTypeAVPlayer:
            return self.avPlayer.audioEnable;
        case IRDecoderTypeFFmpeg:
            return self.ffPlayer.audioEnable;
        case IRDecoderTypeError:
            return NO;
    }
}

- (IRPlayerTrack *)videoTrack
{
    switch (self.decoderType) {
        case IRDecoderTypeAVPlayer:
            return self.avPlayer.videoTrack;
        case IRDecoderTypeFFmpeg:
            return self.ffPlayer.videoTrack;
        case IRDecoderTypeError:
            return nil;
    }
}

- (IRPlayerTrack *)audioTrack
{
    switch (self.decoderType) {
        case IRDecoderTypeAVPlayer:
            return self.avPlayer.audioTrack;
        case IRDecoderTypeFFmpeg:
            return self.ffPlayer.audioTrack;
        case IRDecoderTypeError:
            return nil;
    }
}

- (NSArray<IRPlayerTrack *> *)videoTracks
{
    switch (self.decoderType) {
        case IRDecoderTypeAVPlayer:
            return self.avPlayer.videoTracks;
        case IRDecoderTypeFFmpeg:
            return self.ffPlayer.videoTracks;
        case IRDecoderTypeError:
            return nil;
    }
}

- (NSArray<IRPlayerTrack *> *)audioTracks
{
    switch (self.decoderType) {
        case IRDecoderTypeAVPlayer:
            return self.avPlayer.audioTracks;
        case IRDecoderTypeFFmpeg:
            return self.ffPlayer.audioTracks;
        case IRDecoderTypeError:
            return nil;
    }
}

- (void)selectAudioTrack:(IRPlayerTrack *)audioTrack
{
    [self selectAudioTrackIndex:audioTrack.index];
}

- (void)selectAudioTrackIndex:(int)audioTrackIndex
{
    switch (self.decoderType) {
        case IRDecoderTypeAVPlayer:
            [self.avPlayer selectAudioTrackIndex:audioTrackIndex];
        case IRDecoderTypeFFmpeg:
            [self.ffPlayer selectAudioTrackIndex:audioTrackIndex];
            break;
        case IRDecoderTypeError:
            break;
    }
}

#pragma mark - UIScrollViewDelegate

-(void)glViewWillBeginZooming:(IRGLView *)glView{
    [_sensor stopMotionDetection];
}

-(void)glViewDidEndZooming:(IRGLView *)glView atScale:(CGFloat)scale{
    [_sensor resetUnit];
}

-(void)glViewWillBeginDragging:(IRGLView *)glView{
    [_sensor stopMotionDetection];
}

-(void)glViewDidEndDragging:(IRGLView *)glView willDecelerate:(BOOL)decelerate{
    if ((!decelerate)) {
        [_sensor resetUnit];
    }
}

-(void)glViewDidEndDecelerating:(IRGLView *)glView{
    
}

-(void)glViewDidScrollToBounds:(IRGLView *)glView{
    NSLog(@"scroll to bounds");
}

@end
