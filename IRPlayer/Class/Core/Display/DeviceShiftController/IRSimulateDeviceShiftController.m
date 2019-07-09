//
//  IRSimulateDeviceShiftController.m
//  IRPlayer
//
//  Created by Phil on 2019/7/5.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "IRSimulateDeviceShiftController.h"
#import "IRGLProgram2D.h"

@implementation IRSimulateDeviceShiftController{
    IRGLProgram2D* _program;
}

-(instancetype)init{
    if(self = [super init]){
        self.enabled = YES;
    }
    return self;
}

-(void)setProgram:(IRGLProgram2D*)program{
    _program = program;
}

-(void)shiftDegreeX:(float)degreeX degreeY:(float)degreeY{
    if(!self.enabled)
        return;
    
    if(self.wideDegreeX == 0){
        degreeX = 0;
    }else{
        degreeX = degreeX * _program.wideDegreeX / self.wideDegreeX;
    }
    
    if(self.wideDegreeY == 0){
        degreeY = 0;
    }else{
        degreeY = degreeY * _program.wideDegreeY / self.wideDegreeY;
    }
    
    [_program didPanByDegreeX:degreeX degreey:degreeY];
}

@end
