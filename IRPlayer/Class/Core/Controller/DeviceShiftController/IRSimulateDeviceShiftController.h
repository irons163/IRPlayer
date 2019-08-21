//
//  IRSimulateDeviceShiftController.h
//  IRPlayer
//
//  Created by Phil on 2019/7/5.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <Foundation/Foundation.h>
@class IRGLProgram2D;

NS_ASSUME_NONNULL_BEGIN

@interface IRSimulateDeviceShiftController : NSObject

@property BOOL enabled;
@property (nonatomic) float wideDegreeX;
@property (nonatomic) float wideDegreeY;

- (void)setProgram:(IRGLProgram2D*)program;
- (void)shiftDegreeX:(float)degreeX degreeY:(float)degreeY;
@end

NS_ASSUME_NONNULL_END
