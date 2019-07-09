//
//  IRGLView.h
//  IRPlayer
//
//  Created by Phil on 2019/7/5.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IRGLSupportPixelFormat.h"

@class IRGLRenderMode;
@class IRGLViewSimulateDeviceShiftController;
@class IRGLView;
@class IRVideoFrame;
@class IRMovieDecoder;
@class VideoDecoder;
@class IRAVPlayer;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, IRRenderMode){
    Normal_2D, //default
    Fisheye_Pano,
    Fisheye_Persp,
    Fisheye_Persp_4P
};

@protocol IRGLViewDelegate

@optional
- (void)glViewWillBeginDragging:(IRGLView *)glView;
- (void)glViewDidEndDragging:(IRGLView *)glView willDecelerate:(BOOL)decelerate;
- (void)glViewDidEndDecelerating:(IRGLView *)glView;
- (void)glViewDidScrollToBounds:(IRGLView *)glView;
- (void)glViewWillBeginZooming:(IRGLView *)glView;
- (void)glViewDidEndZooming:(IRGLView *)glView atScale:(CGFloat)scale;
@end

@interface IRGLView : UIView

- (id)initWithFrame:(CGRect)frame
            decoder: (IRMovieDecoder *) decoder;
- (void)render: (IRVideoFrame *) frame;
- (void)setDecoder: (VideoDecoder *) decoder;
- (void)setPixelFormat: (IRPixelFormat) pixelFormat;
- (void)updateViewPort:(float)scale;
- (void)updateScopeByFx:(float)fx fy:(float)fy dsx:(float)dsx dsy:(float) dsy;
- (void)scrollByDx:(float)dx dy:(float)dy;
- (void)shiftDegreeX:(float)degreeX degreeY:(float)degreeY;
- (void)setRenderModes:(NSArray<IRGLRenderMode*>*) modes;
- (NSArray*)getRenderModes;
- (IRGLRenderMode*)getCurrentRenderMode;
- (BOOL)chooseRenderMode:(IRGLRenderMode*)mode withImmediatelyRenderOnce:(BOOL)immediatelyRenderOnce;
- (void)clearCanvas;
- (void)doSnapShot;
- (void)closeGLView;
@property (weak) id<IRGLViewDelegate> delegate;
@property BOOL doubleTapEnable;
@property BOOL swipeEnable;
@property (nonatomic, weak) IRAVPlayer *avplayer;
@end

NS_ASSUME_NONNULL_END
