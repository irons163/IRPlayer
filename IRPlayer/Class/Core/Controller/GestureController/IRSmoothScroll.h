//
//  IRSmoothScroll.h
//  IRPlayer
//
//  Created by Phil on 2019/9/2.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "IRGLView.h"
#import "IRGLGestureController.h"
#import "IRGLProgram2D.h"

NS_ASSUME_NONNULL_BEGIN

@interface IRSmoothScroll : NSObject<IRGLProgramDelegate>

@property (weak) id<IRGLViewDelegate> delegate;
@property (nonatomic) IRGLRenderMode *currentMode;
@property (nonatomic, weak, readonly) IRGLView *targetView;
@property (nonatomic) BOOL isPaned;

- (instancetype)initWithTargetView:(IRGLView *)targetView;

- (void)resetSmoothScroll;
- (void)calculateSmoothScroll:(CGPoint)velocity;

@end

NS_ASSUME_NONNULL_END
