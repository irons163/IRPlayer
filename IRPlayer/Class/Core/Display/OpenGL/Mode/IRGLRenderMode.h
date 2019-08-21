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

@protocol IRGLRenderModeDelegate

@optional
- (void)programDidCreate:(IRGLProgram2D *)program;
@end

@interface IRGLRenderMode : NSObject {
@protected
    IRGLProgram2D* _program;
    IRGLProgram2DFactory* programFactory;
}

@property (weak) id<IRGLRenderModeDelegate> delegate;
@property IRSimulateDeviceShiftController* shiftController;
@property (nonatomic) float wideDegreeX;
@property (nonatomic) float wideDegreeY;
@property (nonatomic) float defaultScale;
@property (nonatomic) IRGLRenderContentMode contentMode;
@property (nonatomic) IRMediaParameter* parameter;
@property (nonatomic) NSString* name;
@property (readonly) IRGLProgram2D* program;

-(void) setDefaultScale:(float)scale;
-(void) setWideDegreeX:(float)wideDegreeX;
-(void) update;
@end

NS_ASSUME_NONNULL_END
