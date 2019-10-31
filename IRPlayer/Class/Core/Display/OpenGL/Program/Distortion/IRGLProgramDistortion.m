//
//  IRGLProgramDistortion.m
//  IRPlayer
//
//  Created by Phil on 2019/8/22.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "IRGLProgramDistortion.h"
#import "IRGLVertexShaderGLSL.h"
#import "IRGLFragmentRGBShaderGLSL.h"
#import "IRGLFragmentYUVShaderGLSL.h"
#import "IRGLFragmentNV12ShaderGLSL.h"
#import "IRGLProjectionDistortion.h"

#define LeftEye 0
#define RightEye 1



//#import "SGDistortionModel.h"
//#import "SGPlayerMacro.h"

#define SG_GLES_STRINGIZE(x) #x

static const char vertexShaderString2[] = SG_GLES_STRINGIZE
(
 attribute vec2 aPosition;
 attribute float aVignette;
 attribute vec2 aRedTextureCoord;
 attribute vec2 aGreenTextureCoord;
 attribute vec2 aBlueTextureCoord;
 varying vec2 vRedTextureCoord;
 varying vec2 vBlueTextureCoord;
 varying vec2 vGreenTextureCoord;
 varying float vVignette;
 uniform float uTextureCoordScale;
 void main() {
     gl_Position = vec4(aPosition, 0.0, 1.0);
     vRedTextureCoord = aRedTextureCoord.xy * uTextureCoordScale;
     vGreenTextureCoord = aGreenTextureCoord.xy * uTextureCoordScale;
     vBlueTextureCoord = aBlueTextureCoord.xy * uTextureCoordScale;
     vVignette = aVignette;
 }
 );

static const char fragmentShaderString2[] = SG_GLES_STRINGIZE
(
 precision mediump float;
 varying vec2 vRedTextureCoord;
 varying vec2 vBlueTextureCoord;
 varying vec2 vGreenTextureCoord;
 varying float vVignette;
 uniform sampler2D uTextureSampler;
 void main() {
     gl_FragColor = vVignette * vec4(texture2D(uTextureSampler, vRedTextureCoord).r,
                                     texture2D(uTextureSampler, vGreenTextureCoord).g,
                                     texture2D(uTextureSampler, vBlueTextureCoord).b, 1.0);
 }
 );


@interface IRGLProgramDistortion() {
    GLint previous_frame_buffer_id;
    GLuint frame_buffer_id;
    GLuint color_render_id;
    GLuint frame_texture_id;
    
    GLuint index_buffer_id;
    GLuint vertex_buffer_id;
    GLuint texture_buffer_id;
    
    GLuint program_id;
    GLuint vertex_shader_id;
    GLuint fragment_shader_id;
    
    GLint position_shader_location;
    GLint vignette_shader_location;
    GLint redTextureCoord_shader_location;
    GLint greenTextureCoord_shader_location;
    GLint blueTextureCoord_shader_location;
    GLint uTextureCoordScale_shader_location;
    GLint uTextureSampler_shader_location;
}
@property (nonatomic, assign) CGSize viewportSize;

@property (nonatomic, strong) IRGLProjectionDistortion *leftEye;
@property (nonatomic, strong) IRGLProjectionDistortion *rightEye;
@end

@implementation IRGLProgramDistortion
@dynamic tramsformController;

- (NSString*)vertexShader {
    vertexShaderString = [IRGLVertexShaderGLSL getShardString];
    return vertexShaderString;
}

- (NSString*)fragmentShader {
    switch (_pixelFormat) {
        case RGB_IRPixelFormat:
            fragmentShaderString = [IRGLFragmentRGBShaderGLSL getShardString];
            break;
        case YUV_IRPixelFormat:
            fragmentShaderString = [IRGLFragmentYUVShaderGLSL getShardString];
            break;
        case NV12_IRPixelFormat:
            fragmentShaderString = [IRGLFragmentNV12ShaderGLSL getShardString];
            break;
    }
    return fragmentShaderString;
}

- (instancetype)initWithPixelFormat:(IRPixelFormat)pixelFormat withViewprotRange:(CGRect)viewprotRange withParameter:(IRMediaParameter *)parameter {
    if (self = [super initWithPixelFormat:pixelFormat withViewprotRange:viewprotRange withParameter:parameter]) {
        self.viewportSize = viewprotRange.size;
        [self setup];
    }
    return self;
}

- (void)setViewprotRange:(CGRect)viewprotRange resetTransform:(BOOL)resetTransform {
    [super setViewprotRange:viewprotRange resetTransform:resetTransform];
    
    [self.tramsformController resetViewport:viewprotRange.size.width / 2 :viewprotRange.size.height resetTransform:NO];
    self.viewportSize = viewprotRange.size;
}

- (void)drawBox {
    glBindFramebuffer(GL_FRAMEBUFFER, previous_frame_buffer_id);
    
    CGRect viewport = [self calculateViewport];
    glViewport(viewport.origin.x, viewport.origin.y, viewport.size.width, viewport.size.height);
    
    glDisable(GL_CULL_FACE);
    glDisable(GL_SCISSOR_TEST);

    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glEnable(GL_SCISSOR_TEST);
    
    glScissor(viewport.origin.x, viewport.origin.y, viewport.size.width / 2, viewport.size.height);
    [self draw:self.leftEye];
    glScissor(viewport.origin.x + viewport.size.width / 2, viewport.origin.y, viewport.size.width / 2, viewport.size.height);
    [self draw:self.rightEye];
    
    glDisable(GL_SCISSOR_TEST);
}

- (IRGLProjectionDistortion *)leftEye
{
    if (!_leftEye) {
        _leftEye = [[IRGLProjectionDistortion alloc] initWithModelType:IRDistortionModelTypeLeft];
    }
    return _leftEye;
}

- (IRGLProjectionDistortion *)rightEye
{
    if (!_rightEye) {
        _rightEye = [[IRGLProjectionDistortion alloc] initWithModelType:IRDistortionModelTypeRight];
    }
    return _rightEye;
}

//- (void)draw:(IRGLProjectionDistortion *)eye
//{
//    glBindBuffer(GL_ARRAY_BUFFER, eye.vertex_buffer_id);
//    glVertexAttribPointer(ATTRIBUTE_VERTEX, 2, GL_FLOAT, GL_FALSE, 9 * sizeof(float), (void *)(0 * sizeof(float)));
//    glEnableVertexAttribArray(ATTRIBUTE_VERTEX);
//    glVertexAttribPointer(ATTRIBUTE_TEXCOORD, 1, GL_FLOAT, GL_FALSE, 9 * sizeof(float), (void *)(2 * sizeof(float)));
//    glEnableVertexAttribArray(ATTRIBUTE_TEXCOORD);
//
//    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, eye.index_buffer_id);
//    glDrawElements(GL_TRIANGLE_STRIP, eye.index_count, GL_UNSIGNED_SHORT, 0);
//}

- (void)draw {
    if ([self prepareRender]) {
        [self.mapProjection updateVertex];
    }
}

- (void)render {
    CGRect viewport = [self calculateViewport];
    
    [self beforDrawFrame];
    
    glViewport(viewport.origin.x, viewport.origin.y, viewport.size.width / 2, viewport.size.height);
    [self.mapProjection updateVertex];
    [self.tramsformController resetViewport:viewport.size.width / 2 :viewport.size.height resetTransform:NO];
    [self setModelviewProj:[self.tramsformController getModelViewProjectionMatrix]];
    if ([self prepareRender]) {
        [self.mapProjection draw];
    }
    glViewport(viewport.origin.x + viewport.size.width / 2, viewport.origin.y, viewport.size.width / 2, viewport.size.height);
    [self.tramsformController resetViewport:viewport.size.width / 2 :viewport.size.height resetTransform:NO];
    [self setModelviewProj:[self.tramsformController getModelViewProjectionMatrix2]];
    if ([self prepareRender]) {
        [self.mapProjection draw];
    }
   
    [self drawBox];
}

-(BOOL)doScrollVerticalWithStatus:(IRGLTransformControllerScrollStatus)status withTramsformController:(IRGLTransformController *)tramsformController{
    if(status & IRGLTransformControllerScrollToMaxY || status & IRGLTransformControllerScrollToMinY){
        return NO;
    }
    return YES;
}

- (void)setViewportSize:(CGSize)viewportSize
{
    if (!CGSizeEqualToSize(_viewportSize, viewportSize)) {
        _viewportSize = viewportSize;
        [self resetFrameBufferSize];
    }
}

- (void)beforDrawFrame
{
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &previous_frame_buffer_id);
    glBindFramebuffer(GL_FRAMEBUFFER, frame_buffer_id);
}

- (void)draw:(IRGLProjectionDistortion *)eye
{
    [self useProgram];
    
    glBindBuffer(GL_ARRAY_BUFFER, eye.vertex_buffer_id);
    glVertexAttribPointer(position_shader_location, 2, GL_FLOAT, GL_FALSE, 9 * sizeof(float), (void *)(0 * sizeof(float)));
    glEnableVertexAttribArray(position_shader_location);
    glVertexAttribPointer(vignette_shader_location, 1, GL_FLOAT, GL_FALSE, 9 * sizeof(float), (void *)(2 * sizeof(float)));
    glEnableVertexAttribArray(vignette_shader_location);
    glVertexAttribPointer(blueTextureCoord_shader_location, 2, GL_FLOAT, GL_FALSE, 9 * sizeof(float), (void *)(7 * sizeof(float)));
    glEnableVertexAttribArray(blueTextureCoord_shader_location);
    
    if (YES) {
        glVertexAttribPointer(redTextureCoord_shader_location, 2, GL_FLOAT, GL_FALSE, 9 * sizeof(float), (void *)(3 * sizeof(float)));
        glEnableVertexAttribArray(redTextureCoord_shader_location);
        glVertexAttribPointer(greenTextureCoord_shader_location, 2, GL_FLOAT, GL_FALSE, 9 * sizeof(float), (void *)(5 * sizeof(float)));
        glEnableVertexAttribArray(greenTextureCoord_shader_location);
    }
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, frame_texture_id);
    
    glUniform1i(uTextureSampler_shader_location, 0);
    float _resolutionScale = 1;
    glUniform1f(uTextureCoordScale_shader_location, _resolutionScale);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, eye.index_buffer_id);
    glDrawElements(GL_TRIANGLE_STRIP, eye.index_count, GL_UNSIGNED_SHORT, 0);
}

- (void)setup
{
    [self setupFrameBuffer];
    [self setupProgramAndShader];
    [self resetFrameBufferSize];
}

- (void)useProgram
{
    glUseProgram(program_id);
}

- (void)setupFrameBuffer
{
    glGenTextures(1, &frame_texture_id);
    glBindTexture(GL_TEXTURE_2D, frame_texture_id);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
    [self checkGLError];
    
    glGenRenderbuffers(1, &color_render_id);
    glBindRenderbuffer(GL_RENDERBUFFER, color_render_id);
    
    [self checkGLError];
    
    glGenFramebuffers(1, &frame_buffer_id);
    glBindFramebuffer(GL_FRAMEBUFFER, frame_buffer_id);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, frame_texture_id, 0);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, color_render_id);
    
    [self checkGLError];
}

- (void)resetFrameBufferSize
{
    glBindTexture(GL_TEXTURE_2D, frame_texture_id);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, self.viewportSize.width, self.viewportSize.height, 0, GL_RGB, GL_UNSIGNED_BYTE, nil);
    
    glBindRenderbuffer(GL_RENDERBUFFER, color_render_id);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.viewportSize.width, self.viewportSize.height);
    [self checkGLError];
}

- (void)setupProgramAndShader
{
    program_id = glCreateProgram();
    
    if (![self compileShader:&vertex_shader_id type:GL_VERTEX_SHADER string:vertexShaderString2])
    {
        NSLog(@"load vertex shader failure");
    }
    if (![self compileShader:&fragment_shader_id type:GL_FRAGMENT_SHADER string:fragmentShaderString2])
    {
        NSLog(@"load fragment shader failure");
    }
    glAttachShader(program_id, vertex_shader_id);
    glAttachShader(program_id, fragment_shader_id);
    
    GLint status;
    glLinkProgram(program_id);
    
    glGetProgramiv(program_id, GL_LINK_STATUS, &status);
    
    if (status == GL_FALSE) {
        NSLog(@"link program failure");
    }
    
    [self clearShader];
    
    position_shader_location = glGetAttribLocation(program_id, "aPosition");
    if (position_shader_location == -1)
    {
        [NSException raise:@"DistortionRenderer" format:@"Could not get attrib location for aPosition"];
    }
    
    vignette_shader_location = glGetAttribLocation(program_id, "aVignette");
    if (vignette_shader_location == -1)
    {
        [NSException raise:@"DistortionRenderer" format:@"Could not get attrib location for aVignette"];
    }
    
    if (YES)
    {
        redTextureCoord_shader_location = glGetAttribLocation(program_id, "aRedTextureCoord");
        if (redTextureCoord_shader_location == -1)
        {
            [NSException raise:@"DistortionRenderer" format:@"Could not get attrib location for aRedTextureCoord"];
        }
        
        greenTextureCoord_shader_location = glGetAttribLocation(program_id, "aGreenTextureCoord");
        if (greenTextureCoord_shader_location == -1)
        {
            [NSException raise:@"DistortionRenderer" format:@"Could not get attrib location for aGreenTextureCoord"];
        }
    }
    
    blueTextureCoord_shader_location = glGetAttribLocation(program_id, "aBlueTextureCoord");
    if (blueTextureCoord_shader_location == -1)
    {
        [NSException raise:@"DistortionRenderer" format:@"Could not get attrib location for aBlueTextureCoord"];
    }
    
    uTextureCoordScale_shader_location = glGetUniformLocation(program_id, "uTextureCoordScale");
    if (uTextureCoordScale_shader_location == -1)
    {
        [NSException raise:@"DistortionRenderer" format:@"Could not get attrib location for uTextureCoordScale"];
    }
    
    uTextureSampler_shader_location = glGetUniformLocation(program_id, "uTextureSampler");
    if (uTextureSampler_shader_location == -1)
    {
        [NSException raise:@"DistortionRenderer" format:@"Could not get attrib location for uTextureSampler"];
    }
    
    [self useProgram];
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type string:(const char *)shaderString
{
    if (!shaderString)
    {
        NSLog(@"Failed to load shader");
        return NO;
    }
    
    GLint status;
    
    * shader = glCreateShader(type);
    glShaderSource(* shader, 1, &shaderString, NULL);
    glCompileShader(* shader);
    glGetShaderiv(* shader, GL_COMPILE_STATUS, &status);
    if (status != GL_TRUE)
    {
        GLint logLength;
        glGetShaderiv(* shader, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0) {
            GLchar * log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(* shader, logLength, &logLength, log);
            NSLog(@"Shader compile log:\n%s", log);
            free(log);
        }
    }
    
    return status == GL_TRUE;
}

- (void)clearShader
{
    if (vertex_shader_id) {
        glDeleteShader(vertex_shader_id);
    }
    
    if (fragment_shader_id) {
        glDeleteShader(fragment_shader_id);
    }
}

- (void)checkGLError
{
    GLenum err = glGetError();
    if (err != GL_NO_ERROR)
    {
        NSLog(@"glError: 0x%04X", err);
    }
}

@end
