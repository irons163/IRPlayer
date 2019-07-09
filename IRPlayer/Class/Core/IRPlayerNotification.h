//
//  IRPlayerNotification.h
//  IRPlayer
//
//  Created by Phil on 2019/7/9.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IRPlayer.h"
#import "IRPlayerAction.h"

NS_ASSUME_NONNULL_BEGIN

@interface IRPlayer (IRPlayerNotification)
@property (nonatomic, strong, nullable) IRError * error;
@end

@interface IRPlayerNotification : NSObject

+ (void)postPlayer:(IRPlayer *)player error:(IRError *)error;
+ (void)postPlayer:(IRPlayer *)player statePrevious:(IRPlayerState)previous current:(IRPlayerState)current;
+ (void)postPlayer:(IRPlayer *)player progressPercent:(NSNumber *)percent current:(NSNumber *)current total:(NSNumber *)total;
+ (void)postPlayer:(IRPlayer *)player playablePercent:(NSNumber *)percent current:(NSNumber *)current total:(NSNumber *)total;

@end

NS_ASSUME_NONNULL_END
