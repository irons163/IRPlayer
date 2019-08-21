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
    self.program.wideDegreeX = wideDegreeX;
    self.shiftController.wideDegreeX = 180;
}

-(void)setWideDegreeY:(float)wideDegreeY{
    [super setWideDegreeY:wideDegreeY];
    self.program.wideDegreeY = wideDegreeY;
    self.shiftController.wideDegreeY = self.program.wideDegreeY;
}

-(void)setContentMode:(IRGLRenderContentMode)contentMode{
    [super setContentMode:contentMode];
    self.program.contentMode = contentMode;
}

@end
