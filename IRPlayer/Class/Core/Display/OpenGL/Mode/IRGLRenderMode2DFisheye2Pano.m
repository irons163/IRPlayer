//
//  IRGLRenderMode2DFIsheye2Pano.m
//  IRPlayer
//
//  Created by Phil on 2019/7/5.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "IRGLRenderMode2DFisheye2Pano.h"
#import "IRGLProgram2DFisheye2PanoFactory.h"

@implementation IRGLRenderMode2DFisheye2Pano

-(void)initProgramFactory{
    programFactory = [[IRGLProgram2DFisheye2PanoFactory alloc] init];
}

-(void)setWideDegreeX:(float)wideDegreeX{
    [super setWideDegreeX:wideDegreeX];
    program.wideDegreeX = wideDegreeX;
    self.shiftController.wideDegreeX = 180;
}

-(void)setWideDegreeY:(float)wideDegreeY{
    [super setWideDegreeY:wideDegreeY];
    program.wideDegreeY = wideDegreeY;
    self.shiftController.wideDegreeY = program.wideDegreeY;
}

-(void)setContentMode:(IRGLRenderContentMode)contentMode{
    [super setContentMode:contentMode];
    program.contentMode = contentMode;
}

@end
