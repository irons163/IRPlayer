//
//  IRPlayerDecoder.m
//  IRPlayer
//
//  Created by Phil on 2019/7/5.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "IRPlayerDecoder.h"

@implementation IRPlayerDecoder

+ (instancetype)defaultDecoder
{
    IRPlayerDecoder * decoder = [[self alloc] init];
    decoder.unkonwnFormat   = IRDecoderTypeFFmpeg;
    decoder.mpeg4Format     = IRDecoderTypeAVPlayer;
    decoder.flvFormat       = IRDecoderTypeFFmpeg;
    decoder.m3u8Format      = IRDecoderTypeAVPlayer;
    decoder.rtmpFormat      = IRDecoderTypeFFmpeg;
    decoder.rtspFormat      = IRDecoderTypeFFmpeg;
    return decoder;
}

+ (instancetype)AVPlayerDecoder
{
    IRPlayerDecoder * decoder = [[self alloc] init];
    decoder.unkonwnFormat   = IRDecoderTypeAVPlayer;
    decoder.mpeg4Format     = IRDecoderTypeAVPlayer;
    decoder.flvFormat       = IRDecoderTypeAVPlayer;
    decoder.m3u8Format      = IRDecoderTypeAVPlayer;
    decoder.rtmpFormat      = IRDecoderTypeAVPlayer;
    decoder.rtspFormat      = IRDecoderTypeAVPlayer;
    return decoder;
}

+ (instancetype)FFmpegDecoder
{
    IRPlayerDecoder * decoder = [[self alloc] init];
    decoder.unkonwnFormat   = IRDecoderTypeFFmpeg;
    decoder.mpeg4Format     = IRDecoderTypeFFmpeg;
    decoder.flvFormat       = IRDecoderTypeFFmpeg;
    decoder.m3u8Format      = IRDecoderTypeFFmpeg;
    decoder.rtmpFormat      = IRDecoderTypeFFmpeg;
    decoder.rtspFormat      = IRDecoderTypeFFmpeg;
    return decoder;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.ffmpegHardwareDecoderEnable = YES;
    }
    return self;
}

- (IRVideoFormat)formatForContentURL:(NSURL *)contentURL
{
    if (!contentURL) return IRVideoFormatError;
    
    NSString * path;
    if (contentURL.isFileURL) {
        path = contentURL.path;
    } else {
        path = contentURL.absoluteString;
    }
    
    if ([path hasPrefix:@"rtmp:"])
    {
        return IRVideoFormatRTMP;
    }
    else if ([path hasPrefix:@"rtsp:"])
    {
        return IRVideoFormatRTSP;
    }
    else if ([path containsString:@".flv"])
    {
        return IRVideoFormatFLV;
    }
    else if ([path containsString:@".mp4"])
    {
        return IRVideoFormatMPEG4;
    }
    else if ([path containsString:@".m3u8"])
    {
        return IRVideoFormatM3U8;
    }
    return IRVideoFormatUnknown;
}

- (IRDecoderType)decoderTypeForContentURL:(NSURL *)contentURL
{
    IRVideoFormat format = [self formatForContentURL:contentURL];
    switch (format) {
        case IRVideoFormatError:
            return IRDecoderTypeError;
        case IRVideoFormatUnknown:
            return self.unkonwnFormat;
        case IRVideoFormatMPEG4:
            return self.mpeg4Format;
        case IRVideoFormatFLV:
            return self.flvFormat;
        case IRVideoFormatM3U8:
            return self.m3u8Format;
        case IRVideoFormatRTMP:
            return self.rtmpFormat;
        case IRVideoFormatRTSP:
            return self.rtspFormat;
    }
}

@end
