//
//  IRGLRenderModeVR.m
//  IRPlayer
//
//  Created by Phil on 2019/8/21.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "IRGLRenderModeVR.h"
#import "IRGLProgramVRFactory.h"

@implementation IRGLRenderModeVR

-(void)initProgramFactory{
    programFactory = [[IRGLProgramVRFactory alloc] init];
}

-(void)setDefaultScale:(float)scale{
    [super setDefaultScale:scale];
//    [self.program setDefaultScale:scale];
}

-(void)setWideDegreeX:(float)wideDegreeX{
    [super setWideDegreeX:wideDegreeX];
//    self.program.wideDegreeX = wideDegreeX;
    self.shiftController.wideDegreeX = wideDegreeX;
}

-(void)setWideDegreeY:(float)wideDegreeY{
    [super setWideDegreeY:wideDegreeY];
//    self.program.wideDegreeY = wideDegreeY;
    self.shiftController.wideDegreeY = wideDegreeY;
}

-(void)setContentMode:(IRGLRenderContentMode)contentMode{
    [super setContentMode:contentMode];
    self.program.contentMode = contentMode;
}

@end
