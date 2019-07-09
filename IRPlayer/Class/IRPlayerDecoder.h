//
//  IRPlayerDecoder.h
//  IRPlayer
//
//  Created by Phil on 2019/7/5.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// decode type
typedef NS_ENUM(NSUInteger, IRDecoderType) {
    IRDecoderTypeError,
    IRDecoderTypeAVPlayer,
    IRDecoderTypeFFmpeg,
};

// video format
typedef NS_ENUM(NSUInteger, IRVideoFormat) {
    IRVideoFormatError,
    IRVideoFormatUnknown,
    IRVideoFormatMPEG4,
    IRVideoFormatFLV,
    IRVideoFormatM3U8,
    IRVideoFormatRTMP,
    IRVideoFormatRTSP,
};

@interface IRPlayerDecoder : NSObject

+ (instancetype)defaultDecoder;
+ (instancetype)AVPlayerDecoder;
+ (instancetype)FFmpegDecoder;

- (IRVideoFormat)formatForContentURL:(NSURL *)contentURL;
- (IRDecoderType)decoderTypeForContentURL:(NSURL *)contentURL;

@property (nonatomic, assign) BOOL ffmpegHardwareDecoderEnable; // default is YES

@property (nonatomic, assign) IRDecoderType unkonwnFormat;      // default is IRDecodeTypeFFmpeg
@property (nonatomic, assign) IRDecoderType mpeg4Format;        // default is IRDecodeTypeAVPlayer
@property (nonatomic, assign) IRDecoderType flvFormat;          // default is IRDecodeTypeFFmpeg
@property (nonatomic, assign) IRDecoderType m3u8Format;         // default is IRDecodeTypeAVPlayer
@property (nonatomic, assign) IRDecoderType rtmpFormat;         // default is IRDecodeTypeFFmpeg
@property (nonatomic, assign) IRDecoderType rtspFormat;         // default is IRDecodeTypeFFmpeg

@end

NS_ASSUME_NONNULL_END
