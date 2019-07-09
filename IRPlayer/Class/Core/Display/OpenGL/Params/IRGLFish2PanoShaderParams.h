//
//  IRGLFish2PanoShaderParams.h
//  IRPlayer
//
//  Created by Phil on 2019/7/5.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IRGLShaderParams.h"

NS_ASSUME_NONNULL_BEGIN

@interface IRGLFish2PanoShaderParams : IRGLShaderParams {
    enum
    {
        UNIFORM_ROTATION_ANGLE,
        UNIFORM_TEXTURE_WIDTH,
        UNIFORM_TEXTURE_HEIGHT,
        UNIFORM_FISH_APERTURE,
        UNIFORM_FISH_CENTERX,
        UNIFORM_FISH_CENTERY,
        UNIFORM_FISH_RADIUS_H,
        UNIFORM_FISH_RADIUS_V,
        UNIFORM_OUTPUT_WIDTH,
        UNIFORM_OUTPUT_HEIGHT,
        UNIFORM_ANTIALIAS,
        UNIFORM_VAPERTURE,
        UNIFORM_LAT1,
        UNIFORM_LAT2,
        UNIFORM_LONG1,
        UNIFORM_LONG2,
        UNIFORM_ENABLE_TRANSFORM_X,
        UNIFORM_ENABLE_TRANSFORM_Y,
        UNIFORM_ENABLE_TRANSFORM_Z,
        UNIFORM_TRANSFORM_X,
        UNIFORM_TRANSFORM_Y,
        UNIFORM_TRANSFORM_Z,
        UNIFORM_OFFSETX,
        NUM_UNIFORMS
    };
}

@property GLfloat preferredRotation;
@property (nonatomic) GLfloat fishaperture;
@property (nonatomic) GLint fishcenterx;
@property (nonatomic) GLint fishcentery;
@property (nonatomic) GLint fishradiush;
@property (nonatomic) GLint fishradiusv;
@property (nonatomic) GLint antialias;
@property (nonatomic) GLfloat vaperture;
@property (nonatomic) GLfloat lat1;
@property (nonatomic) GLfloat lat2;
@property (nonatomic) GLfloat long1;
@property (nonatomic) GLfloat long2;
@property (nonatomic) GLint enableTransformX;
@property (nonatomic) GLint enableTransformY;
@property (nonatomic) GLint enableTransformZ;
@property (nonatomic) GLfloat transformX;
@property (nonatomic) GLfloat transformY;
@property (nonatomic) GLfloat transformZ;
@property (nonatomic) GLfloat offsetX;
//@property int viewportWidth;
//@property int viewportHeight;
//@property (weak) id<Shader> delegate;

@end

NS_ASSUME_NONNULL_END
