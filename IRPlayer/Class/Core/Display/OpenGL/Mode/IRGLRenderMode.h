//
//  IRGLRenderMode.h
//  IRPlayer
//
//  Created by Phil on 2019/7/5.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IRSimulateDeviceShiftController.h"
#import "IRGLProgram2D.h"

@class IRGLProgram2DFactory;

NS_ASSUME_NONNULL_BEGIN

@interface IRGLRenderMode : NSObject{
@protected
    IRGLProgram2D* program;
    IRGLProgram2DFactory* programFactory;
}

@property IRSimulateDeviceShiftController* shiftController;
@property (nonatomic) float wideDegreeX;
@property (nonatomic) float wideDegreeY;
@property (nonatomic) float defaultScale;
@property (nonatomic) IRGLRenderContentMode contentMode;
@property (nonatomic) IRMediaParameter* parameter;
@property (nonatomic) NSString* name;

-(void) setDefaultScale:(float)scale;
-(void) setWideDegreeX:(float)wideDegreeX;
-(void) update;
@end

NS_ASSUME_NONNULL_END
