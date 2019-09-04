//
//  PlayerViewController.h
//  demo
//
//  Created by Phil on 2019/7/9.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, DemoType) {
    DemoType_AVPlayer_Normal = 0,
    DemoType_AVPlayer_VR,
    DemoType_AVPlayer_VR_Box,
    DemoType_FFmpeg_Normal,
    DemoType_FFmpeg_Normal_Hardware,
    DemoType_FFmpeg_Fisheye_Hardware,
    DemoType_FFmpeg_Fisheye_Hardware_Modes_Selection,
};

@interface PlayerViewController : UIViewController

@property (nonatomic, assign) DemoType demoType;

+ (NSString *)displayNameForDemoType:(DemoType)demoType;

@end

NS_ASSUME_NONNULL_END
