//
//  IRGestureControl.h
//  IRPlayer
//
//  Created by Phil on 2019/8/19.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "IRGestureController.h"
#import "IRGLView.h"
//#import "IRGLRe"

//@class IRGLView;

@protocol IRGLViewDelegate

@optional
- (void)glViewWillBeginDragging:(IRGLView *)glView;
- (void)glViewDidEndDragging:(IRGLView *)glView willDecelerate:(BOOL)decelerate;
- (void)glViewDidEndDecelerating:(IRGLView *)glView;
- (void)glViewDidScrollToBounds:(IRGLView *)glView;
- (void)glViewWillBeginZooming:(IRGLView *)glView;
- (void)glViewDidEndZooming:(IRGLView *)glView atScale:(CGFloat)scale;
@end

NS_ASSUME_NONNULL_BEGIN

@interface IRGLGestureController : IRGestureController

@property (weak) id<IRGLViewDelegate> delegate;
@property BOOL doubleTapEnable;
@property BOOL swipeEnable;
@property (nonatomic) IRGLRenderMode *currentMode;

@property (nonatomic, weak, readonly) IRGLView *targetView;

@end

NS_ASSUME_NONNULL_END
