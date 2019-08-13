//
//  IRFFAudioDecoder.m
//  IRPlayer
//
//  Created by Phil on 2019/7/5.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "IRFFAudioDecoder.h"
#import "IRFFFrameQueue.h"
#import "IRFFFramePool.h"
#import "IRFFTools.h"
#import "IRPlayerMacro.h"
#import <Accelerate/Accelerate.h>
#import "swscale.h"
#import "swresample.h"

@interface IRFFAudioDecoder ()

{
    AVCodecContext * _codec_context;
    AVFrame * _temp_frame;
    
    NSTimeInterval _timebase;
    Float64 _samplingRate;
    UInt32 _channelCount;
    
    struct SwsContext * _video_sws_context;
    SwrContext * _audio_swr_context;
    void * _audio_swr_buffer;
    NSUInteger _audio_swr_buffer_size;
}

@property (nonatomic, strong) IRFFFrameQueue * frameQueue;
@property (nonatomic, strong) IRFFFramePool * framePool;

@end

@implementation IRFFAudioDecoder

+ (instancetype)decoderWithCodecContext:(AVCodecContext *)codec_context timebase:(NSTimeInterval)timebase delegate:(id<IRFFAudioDecoderDelegate>)delegate
{
    return [[self alloc] initWithCodecContext:codec_context timebase:timebase delegate:delegate];
}

- (instancetype)initWithCodecContext:(AVCodecContext *)codec_context timebase:(NSTimeInterval)timebase delegate:(id<IRFFAudioDecoderDelegate>)delegate
{
    if (self = [super init]) {
        self.delegate = delegate;
        self->_codec_context = codec_context;
        self->_temp_frame = av_frame_alloc();
        self->_timebase = timebase;
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.frameQueue = [IRFFFrameQueue frameQueue];
    self.framePool = [IRFFFramePool audioPool];
    [self setupSwsContext];
}

- (void)setupSwsContext
{
    [self reloadAudioOuputInfo];
    
    _audio_swr_context = swr_alloc_set_opts(NULL, av_get_default_channel_layout(_channelCount), AV_SAMPLE_FMT_S16, _samplingRate, av_get_default_channel_layout(_codec_context->channels), _codec_context->sample_fmt, _codec_context->sample_rate, 0, NULL);
    
    int result = swr_init(_audio_swr_context);
    NSError * error = IRFFCheckError(result);
    if (error || !_audio_swr_context) {
        if (_audio_swr_context) {
            swr_free(&_audio_swr_context);
        }
    }
}

- (int)size
{
    return [self.frameQueue size];
}

- (BOOL)empty
{
    return self.frameQueue.count <= 0;
}

- (NSTimeInterval)duration
{
    return self.frameQueue.duration;
}

- (void)flush
{
    [self.frameQueue flush];
    [self.framePool flush];
    if (_codec_context) {
        avcodec_flush_buffers(_codec_context);
    }
}

- (void)destroy
{
    [self.frameQueue destroy];
    [self.framePool flush];
}

- (IRFFAudioFrame *)getFrameSync
{
    return [self.frameQueue getFrameSync];
}

- (int)putPacket:(AVPacket)packet
{
    if (packet.data == NULL) return 0;
    
    int result = avcodec_send_packet(_codec_context, &packet);
    if (result < 0 && result != AVERROR(EAGAIN) && result != AVERROR_EOF) {
        return -1;
    }
    
    while (result >= 0) {
        result = avcodec_receive_frame(_codec_context, _temp_frame);
        if (result < 0) {
            if (result != AVERROR(EAGAIN) && result != AVERROR_EOF) {
                return -1;
            }
            break;
        }
        @autoreleasepool
        {
            IRFFAudioFrame * frame = [self decode];
            if (frame) {
                [self.frameQueue putFrame:frame];
            }
        }
    }
    av_packet_unref(&packet);
    return 0;
}

- (IRFFAudioFrame *)decode
{
    if (!_temp_frame->data[0]) return nil;
    
    [self reloadAudioOuputInfo];
    
    int numberOfFrames;
    void * audioDataBuffer;
    
    if (_audio_swr_context) {
        const int ratio = MAX(1, _samplingRate / _codec_context->sample_rate) * MAX(1, _channelCount / _codec_context->channels) * 2;
        const int buffer_size = av_samples_get_buffer_size(NULL, _channelCount, _temp_frame->nb_samples * ratio, AV_SAMPLE_FMT_S16, 1);
        
        if (!_audio_swr_buffer || _audio_swr_buffer_size < buffer_size) {
            _audio_swr_buffer_size = buffer_size;
            _audio_swr_buffer = realloc(_audio_swr_buffer, _audio_swr_buffer_size);
        }
        
        Byte * outyput_buffer[2] = {_audio_swr_buffer, 0};
        numberOfFrames = swr_convert(_audio_swr_context, outyput_buffer, _temp_frame->nb_samples * ratio, (const uint8_t **)_temp_frame->data, _temp_frame->nb_samples);
        NSError * error = IRFFCheckError(numberOfFrames);
        if (error) {
            IRFFErrorLog(@"audio codec error : %@", error);
            return nil;
        }
        audioDataBuffer = _audio_swr_buffer;
    } else {
        if (_codec_context->sample_fmt != AV_SAMPLE_FMT_S16) {
            IRFFErrorLog(@"audio format error");
            return nil;
        }
        audioDataBuffer = _temp_frame->data[0];
        numberOfFrames = _temp_frame->nb_samples;
    }
    
    IRFFAudioFrame * audioFrame = [self.framePool getUnuseFrame];
    audioFrame.position = av_frame_get_best_effort_timestamp(_temp_frame) * _timebase;
    audioFrame.duration = av_frame_get_pkt_duration(_temp_frame) * _timebase;
    
    if (audioFrame.duration == 0) {
        audioFrame.duration = audioFrame->length / (sizeof(float) * _channelCount * _samplingRate);
    }
    
    const NSUInteger numberOfElements = numberOfFrames * self->_channelCount;
    [audioFrame setSamplesLength:numberOfElements * sizeof(float)];
    
    float scale = 1.0 / (float)INT16_MAX ;
    vDSP_vflt16((SInt16 *)audioDataBuffer, 1, audioFrame->samples, 1, numberOfElements);
    vDSP_vsmul(audioFrame->samples, 1, &scale, audioFrame->samples, 1, numberOfElements);
    
    return audioFrame;
}

- (void)reloadAudioOuputInfo
{
    [self.delegate audioDecoder:self samplingRate:&self->_samplingRate];
    [self.delegate audioDecoder:self channelCount:&self->_channelCount];
}

- (void)dealloc
{
    if (_audio_swr_buffer) {
        free(_audio_swr_buffer);
        _audio_swr_buffer = NULL;
        _audio_swr_buffer_size = 0;
    }
    if (_audio_swr_context) {
        swr_free(&_audio_swr_context);
        _audio_swr_context = NULL;
    }
    if (_temp_frame) {
        av_free(_temp_frame);
        _temp_frame = NULL;
    }
    IRPlayerLog(@"IRFFAudioDecoder release");
}

@end
