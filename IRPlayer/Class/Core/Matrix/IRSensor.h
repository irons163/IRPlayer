//
//  IRSensor.h
//  IRPlayer
//
//  Created by Phil on 2019/8/14.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class IRGLView;

NS_ASSUME_NONNULL_BEGIN

@interface IRSensor : NSObject

@property (nonatomic, weak) IRGLView *targetView;

@end

NS_ASSUME_NONNULL_END
