//
//  IRGLRenderModeFactory.m
//  IRPlayer
//
//  Created by Phil on 2019/7/5.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "IRGLRenderModeFactory.h"
#import "IRGLRenderMode2D.h"
#import "IRGLRenderMode2DFisheye2Pano.h"
#import "IRGLRenderMode3DFisheye.h"
#import "IRGLRenderModeMulti4P.h"

@implementation IRGLRenderModeFactory

+(NSArray<IRGLRenderMode*>*)createNormalModesWithParameter:(IRMediaParameter*)parameter{
    NSArray<IRGLRenderMode*>* modes = @[[[IRGLRenderMode2D alloc] init]];
    
    for(IRGLRenderMode* mode in modes){
        mode.parameter = parameter;
    }
    
    return modes;
}

+(NSArray<IRGLRenderMode*>*)createFisheyeModesWithParameter:(IRMediaParameter*)parameter{
    IRGLRenderMode* normal = [[IRGLRenderMode2D alloc] init];
    IRGLRenderMode* fisheye2Pano = [[IRGLRenderMode2DFisheye2Pano alloc] init];
    IRGLRenderMode* fisheye = [[IRGLRenderMode3DFisheye alloc] init];
    IRGLRenderMode* fisheye4P = [[IRGLRenderModeMulti4P alloc] init];
    NSArray<IRGLRenderMode*>* modes = @[
                                             fisheye2Pano,
                                             fisheye,
                                             fisheye4P,
                                             normal
                                             ];
    
    normal.shiftController.enabled = NO;
    fisheye2Pano.contentMode = IRGLRenderContentModeScaleAspectFill;
    fisheye2Pano.wideDegreeX = 360;
    fisheye2Pano.wideDegreeY = 20;
    
    for(IRGLRenderMode* mode in modes){
        mode.parameter = parameter;
    }
    
    normal.name = @"Rawdata";
    fisheye2Pano.name = @"Panorama";
    fisheye.name = @"Onelen";
    fisheye4P.name = @"Fourlens";
    
    return modes;
}

@end
