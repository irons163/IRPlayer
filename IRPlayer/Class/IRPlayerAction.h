//
//  IRPlayerAction.h
//  IRPlayer
//
//  Created by Phil on 2019/7/5.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "IRPlayerImp.h"

@class IRState;
@class IRProgress;
@class IRPlayable;
@class IRError;

NS_ASSUME_NONNULL_BEGIN

// extern
#if defined(__cplusplus)
#define IRPLAYER_EXTERN extern "C"
#else
#define IRPLAYER_EXTERN extern
#endif

// notification name
IRPLAYER_EXTERN NSString * const IRPlayerErrorNotificationName;             // player error
IRPLAYER_EXTERN NSString * const IRPlayerStateChangeNotificationName;       // player state change
IRPLAYER_EXTERN NSString * const IRPlayerProgressChangeNotificationName;    // player play progress change
IRPLAYER_EXTERN NSString * const IRPlayerPlayableChangeNotificationName;    // player playable progress change

// notification userinfo key
IRPLAYER_EXTERN NSString * const IRPlayerErrorKey;              // error

IRPLAYER_EXTERN NSString * const IRPlayerStatePreviousKey;      // state
IRPLAYER_EXTERN NSString * const IRPlayerStateCurrentKey;       // state

IRPLAYER_EXTERN NSString * const IRPlayerProgressPercentKey;    // progress
IRPLAYER_EXTERN NSString * const IRPlayerProgressCurrentKey;    // progress
IRPLAYER_EXTERN NSString * const IRPlayerProgressTotalKey;      // progress

IRPLAYER_EXTERN NSString * const IRPlayerPlayablePercentKey;    // playable
IRPLAYER_EXTERN NSString * const IRPlayerPlayableCurrentKey;    // playable
IRPLAYER_EXTERN NSString * const IRPlayerPlayableTotalKey;      // playable


#pragma mark - IRPlayer Action Category

@interface IRPlayerImp (IRPlayerAction)

- (void)registerPlayerNotificationTarget:(id)target
                             stateAction:(nullable SEL)stateAction
                          progressAction:(nullable SEL)progressAction
                          playableAction:(nullable SEL)playableAction;      // object's class is NSNotification

- (void)registerPlayerNotificationTarget:(id)target
                             stateAction:(nullable SEL)stateAction
                          progressAction:(nullable SEL)progressAction
                          playableAction:(nullable SEL)playableAction
                             errorAction:(nullable SEL)errorAction;

- (void)removePlayerNotificationTarget:(id)target;

@end


#pragma mark - IRPlayer Action Models

@interface IRModel : NSObject

+ (IRState *)stateFromUserInfo:(NSDictionary *)userInfo;
+ (IRProgress *)progressFromUserInfo:(NSDictionary *)userInfo;
+ (IRPlayable *)playableFromUserInfo:(NSDictionary *)userInfo;
+ (IRError *)errorFromUserInfo:(NSDictionary *)userInfo;

@end

@interface IRState : IRModel
@property (nonatomic, assign) IRPlayerState previous;
@property (nonatomic, assign) IRPlayerState current;
@end

@interface IRProgress : IRModel
@property (nonatomic, assign) CGFloat percent;
@property (nonatomic, assign) CGFloat current;
@property (nonatomic, assign) CGFloat total;
@end

@interface IRPlayable : IRModel
@property (nonatomic, assign) CGFloat percent;
@property (nonatomic, assign) CGFloat current;
@property (nonatomic, assign) CGFloat total;
@end

@interface IRErrorEvent : IRModel
@property (nonatomic, copy, nullable) NSDate * date;
@property (nonatomic, copy, nullable) NSString * URI;
@property (nonatomic, copy, nullable) NSString * serverAddress;
@property (nonatomic, copy, nullable) NSString * playbackSessionID;
@property (nonatomic, assign) NSInteger errorStatusCode;
@property (nonatomic, copy) NSString * errorDomain;
@property (nonatomic, copy, nullable) NSString * errorComment;
@end

@interface IRError : IRModel
@property (nonatomic, copy) NSError * error;
@property (nonatomic, copy, nullable) NSData * extendedLogData;
@property (nonatomic, assign) NSStringEncoding extendedLogDataStringEncoding;
@property (nonatomic, copy, nullable) NSArray <IRErrorEvent *> * errorEvents;
@end

NS_ASSUME_NONNULL_END
