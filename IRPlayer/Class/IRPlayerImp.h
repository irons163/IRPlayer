//
//  IRPlayer.h
//  IRPlayer
//
//  Created by Phil on 2019/7/5.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "IRPLFView.h"
#import "IRPLFImage.h"
#import "IRPlayerTrack.h"
#import "IRPlayerDecoder.h"
#import "IRFFVideoInput.h"

@class IRGLRenderMode;

// video type
typedef NS_ENUM(NSUInteger, IRVideoType) {
    IRVideoTypeNormal,  // normal
    IRVideoTypeVR,      // virtual reality
    IRVideoTypeFisheye,
    IRVideoTypePano,
    IRVideoTypeCustom,
};

// player state
typedef NS_ENUM(NSUInteger, IRPlayerState) {
    IRPlayerStateNone = 0,          // none
    IRPlayerStateBuffering = 1,     // buffering
    IRPlayerStateReadyToPlay = 2,   // ready to play
    IRPlayerStatePlaying = 3,       // playing
    IRPlayerStateSuspend = 4,       // pause
    IRPlayerStateFinished = 5,      // finished
    IRPlayerStateFailed = 6,        // failed
};

// display mode
typedef NS_ENUM(NSUInteger, IRDisplayMode) {
    IRDisplayModeNormal,    // default
    IRDisplayModeBox,
};

// video content mode
typedef NS_ENUM(NSUInteger, IRGravityMode) {
    IRGravityModeResize,
    IRGravityModeResizeAspect,
    IRGravityModeResizeAspectFill,
};

// background mode
typedef NS_ENUM(NSUInteger, IRPlayerBackgroundMode) {
    IRPlayerBackgroundModeNothing,
    IRPlayerBackgroundModeAutoPlayAndPause,     // default
    IRPlayerBackgroundModeContinue,
};


#pragma mark - IRPlayerImp

@class IRPlayerImp;
@class IRError;

NS_ASSUME_NONNULL_BEGIN

@interface IRPlayerImp : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)player;

@property (nonatomic, strong) IRPlayerDecoder *decoder;      // default is [IRPlayerDecoder defaultDecoder]

@property (nonatomic, copy, readonly) NSURL *contentURL;
@property (nonatomic, strong, readonly) IRFFVideoInput *videoInput;
@property (nonatomic, assign, readonly) IRVideoType videoType;

@property (nonatomic, strong, readonly, nullable) IRError *error;

- (void)replaceEmpty;
- (void)replaceVideoWithURL:(nullable NSURL *)contentURL;
- (void)replaceVideoWithURL:(nullable NSURL *)contentURL videoType:(IRVideoType)videoType;
- (void)replaceVideoWithInput:(nullable IRFFVideoInput *)videoInput videoType:(IRVideoType)videoType;

// preview
@property (nonatomic, assign) IRDisplayMode displayMode;
@property (nonatomic, strong, readonly) IRPLFView *view;      // graphics view
@property (nonatomic, assign) BOOL viewAnimationHidden;     // default is YES;
@property (nonatomic, assign) IRGravityMode viewGravityMode;       // default is IRGravityModeResizeAspect;
@property (nonatomic, strong) NSArray<IRGLRenderMode *> *renderModes;
@property (nonatomic, strong, readonly) IRGLRenderMode *renderMode;
@property (nonatomic, copy) void (^viewTapAction)(IRPlayerImp * player, IRPLFView * view);

- (void)selectRenderMode:(IRGLRenderMode *)renderMode;
- (IRPLFImage *)snapshot;

// control
@property (nonatomic, assign) IRPlayerBackgroundMode backgroundMode;    // background mode
@property (nonatomic, assign, readonly) IRPlayerState state;
@property (nonatomic, assign, readonly) CGSize presentationSize;
@property (nonatomic, assign, readonly) NSTimeInterval bitrate;
@property (nonatomic, assign, readonly) NSTimeInterval progress;
@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign, readonly) NSTimeInterval playableTime;
@property (nonatomic, assign) NSTimeInterval playableBufferInterval;    // default is 2s
@property (nonatomic, assign, readonly) BOOL seeking;
@property (nonatomic, assign) CGFloat volume;       // default is 1

- (void)play;
- (void)pause;
- (void)seekToTime:(NSTimeInterval)time;
- (void)seekToTime:(NSTimeInterval)time completeHandler:(nullable void(^)(BOOL finished))completeHandler;
- (void)updateGraphicsViewFrame:(CGRect)frame;

@end


#pragma mark - Tracks Category

@interface IRPlayerImp (Tracks)

@property (nonatomic, assign, readonly) BOOL videoEnable;
@property (nonatomic, assign, readonly) BOOL audioEnable;

@property (nonatomic, strong, readonly) IRPlayerTrack *videoTrack;
@property (nonatomic, strong, readonly) IRPlayerTrack *audioTrack;

@property (nonatomic, strong, readonly) NSArray <IRPlayerTrack *> *videoTracks;
@property (nonatomic, strong, readonly) NSArray <IRPlayerTrack *> *audioTracks;

- (void)selectAudioTrack:(IRPlayerTrack *)audioTrack;
- (void)selectAudioTrackIndex:(int)audioTrackIndex;

@end

NS_ASSUME_NONNULL_END

#import "IRPlayerAction.h"
