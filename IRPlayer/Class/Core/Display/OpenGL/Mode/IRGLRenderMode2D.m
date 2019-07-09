//
//  IRGLRenderMode2D.m
//  IRPlayer
//
//  Created by Phil on 2019/7/5.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "IRGLRenderMode2D.h"
#import "IRGLRenderMode2D.h"
#import "IRGLProgram2DFactory.h"

@implementation IRGLRenderMode2D

-(void)initProgramFactory{
    programFactory = [[IRGLProgram2DFactory alloc] init];
}

-(void)setDefaultScale:(float)scale{
    [super setDefaultScale:scale];
    [program setDefaultScale:scale];
}

-(void)setWideDegreeX:(float)wideDegreeX{
    [super setWideDegreeX:wideDegreeX];
    program.wideDegreeX = wideDegreeX;
    self.shiftController.wideDegreeX = wideDegreeX;
}

-(void)setWideDegreeY:(float)wideDegreeY{
    [super setWideDegreeY:wideDegreeY];
    program.wideDegreeY = wideDegreeY;
    self.shiftController.wideDegreeY = wideDegreeY;
}

-(void)setContentMode:(IRGLRenderContentMode)contentMode{
    [super setContentMode:contentMode];
    program.contentMode = contentMode;
}

@end
