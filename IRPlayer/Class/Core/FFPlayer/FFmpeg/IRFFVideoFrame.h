//
//  IRFFVideoFrame.h
//  IRPlayer
//
//  Created by Phil on 2019/7/5.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "IRFFFrame.h"
#import <AVFoundation/AVFoundation.h>
#import "IRPLFImage.h"
#import "avformat.h"
#import "pixfmt.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(int, IRYUVChannel) {
    IRYUVChannelLuma = 0,
    IRYUVChannelChromaB = 1,
    IRYUVChannelChromaR = 2,
    IRYUVChannelCount = 3,
};

@interface IRFFVideoFrame : IRFFFrame

@end


// FFmpeg AVFrame YUV frame
@interface IRFFAVYUVVideoFrame : IRFFVideoFrame

{
@public
    UInt8 * channel_pixels[IRYUVChannelCount];
}

@property (nonatomic, assign, readonly) int width;
@property (nonatomic, assign, readonly) int height;

+ (instancetype)videoFrame;
- (void)setFrameData:(AVFrame *)frame width:(int)width height:(int)height;

- (IRPLFImage *)image;

@end


// CoreVideo YUV frame
@interface IRFFCVYUVVideoFrame : IRFFVideoFrame

@property (nonatomic, assign, readonly) CVPixelBufferRef pixelBuffer;

- (instancetype)initWithAVPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
