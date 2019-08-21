//
//  IRGLRenderMode3DFisheye.m
//  IRPlayer
//
//  Created by Phil on 2019/7/5.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "IRGLRenderMode3DFisheye.h"
#import "IRGLProgram3DFisheyeFactory.h"

@implementation IRGLRenderMode3DFisheye

-(void)initProgramFactory{
    programFactory = [[IRGLProgram3DFisheyeFactory alloc] init];
}

-(void)setWideDegreeX:(float)wideDegreeX{
    [super setWideDegreeX:wideDegreeX];
    self.shiftController.wideDegreeX = 360;
}

-(void)setWideDegreeY:(float)wideDegreeY{
    [super setWideDegreeY:wideDegreeY];
    self.shiftController.wideDegreeY = self.program.wideDegreeY;
}

-(void)setContentMode:(IRGLRenderContentMode)contentMode{
    [super setContentMode:contentMode];
    self.program.contentMode = contentMode;
}

@end
