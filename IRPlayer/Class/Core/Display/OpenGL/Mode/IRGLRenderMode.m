//
//  IRGLRenderMode.m
//  IRPlayer
//
//  Created by Phil on 2019/7/5.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "IRGLRenderMode.h"
#import "IRGLProgram2D.h"
#import "IRGLProgram2DFactory.h"

@implementation IRGLRenderMode
@synthesize program = _program;

-(instancetype)init{
    if(self = [super init]){
        [self initProgramFactory];
        _shiftController = [[IRSimulateDeviceShiftController alloc] init];
        _name = @"";
        _defaultScale = 1.0;
    }
    return self;
}

-(void)initProgramFactory{
    programFactory = [[IRGLProgram2DFactory alloc] init];
}

-(void)setDefaultScale:(float)scale{
    _defaultScale = scale;
}

-(void)setWideDegreeX:(float)wideDegreeX{
    _wideDegreeX = wideDegreeX;
}

-(void)setWideDegreeY:(float)wideDegreeY{
    _wideDegreeY = wideDegreeY;
}

-(void)setContentMode:(IRGLRenderContentMode)contentMode{
    _contentMode = contentMode;
}

-(void) update{
    
}

-(IRGLProgram2D*)get{
    return nil;
}

@end
