//
//  IRPlayer.h
//  IRPlayer
//
//  Created by Phil on 2019/7/5.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

FOUNDATION_EXPORT double IRPlayerVersionNumber;
FOUNDATION_EXPORT const unsigned char IRPlayerVersionString[];

// IRPlayer
#import <IRPlayer/IRPlayerImp.h>
#import <IRPlayer/IRPlayerTrack.h>
#import <IRPlayer/IRPlayerAction.h>
#import <IRPlayer/IRPlayerDecoder.h>
#import <IRPlayer/IRGLRenderMode2D.h>
#import <IRPlayer/IRGLRenderMode2DFisheye2Pano.h>
#import <IRPlayer/IRGLRenderMode3DFisheye.h>
#import <IRPlayer/IRGLRenderModeMulti4P.h>
#import <IRPlayer/IRMediaParameter.h>
#import <IRPlayer/IRFisheyeParameter.h>
#import <IRPlayer/IRFFVideoFrame.h>
#import <IRPlayer/IRFFAVYUVVideoFrame.h>
#import <IRPlayer/IRFFCVYUVVideoFrame.h>
