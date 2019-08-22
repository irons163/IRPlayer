//
//  IRGLRenderMode2D.m
//  IRPlayer
//
//  Created by Phil on 2019/7/5.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "IRGLRenderMode2D.h"
#import "IRGLProgram2DFactory.h"

@implementation IRGLRenderMode2D

-(void)initProgramFactory{
    programFactory = [[IRGLProgram2DFactory alloc] init];
}

-(void)setDefaultScale:(float)scale{
    [super setDefaultScale:scale];
    [self.program setDefaultScale:scale];
}

-(void)setWideDegreeX:(float)wideDegreeX{
    [super setWideDegreeX:wideDegreeX];
    self.program.wideDegreeX = wideDegreeX;
    self.shiftController.wideDegreeX = wideDegreeX;
}

-(void)setWideDegreeY:(float)wideDegreeY{
    [super setWideDegreeY:wideDegreeY];
    self.program.wideDegreeY = wideDegreeY;
    self.shiftController.wideDegreeY = wideDegreeY;
}

-(void)setContentMode:(IRGLRenderContentMode)contentMode{
    [super setContentMode:contentMode];
    self.program.contentMode = contentMode;
}

@end
