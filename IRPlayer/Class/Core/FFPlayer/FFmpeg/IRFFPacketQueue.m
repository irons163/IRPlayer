//
//  IRFFPacketQueue.m
//  IRPlayer
//
//  Created by Phil on 2019/7/5.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "IRFFPacketQueue.h"

@interface IRFFPacketQueue ()

@property (nonatomic, assign) int size;
@property (atomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) NSTimeInterval timebase;

@property (nonatomic, strong) NSCondition * condition;
@property (nonatomic, strong) NSMutableArray <NSValue *> * packets;

@property (nonatomic, assign) BOOL destoryToken;

@end

@implementation IRFFPacketQueue

+ (instancetype)packetQueueWithTimebase:(NSTimeInterval)timebase
{
    return [[self alloc] initWithTimebase:timebase];
}

- (instancetype)initWithTimebase:(NSTimeInterval)timebase
{
    if (self = [super init]) {
        self.timebase = timebase;
        self.packets = [NSMutableArray array];
        self.condition = [[NSCondition alloc] init];
    }
    return self;
}

- (void)putPacket:(AVPacket)packet duration:(NSTimeInterval)duration
{
    [self.condition lock];
    if (self.destoryToken) {
        [self.condition unlock];
        return;
    }
    NSValue * value = [NSValue value:&packet withObjCType:@encode(AVPacket)];
    [self.packets addObject:value];
    self.size += packet.size;
    if (packet.duration > 0) {
        self.duration += packet.duration * self.timebase;
    } else if (duration > 0) {
        self.duration += duration;
    }
    [self.condition signal];
    [self.condition unlock];
}

- (AVPacket)getPacket
{
    [self.condition lock];
    AVPacket packet;
    packet.stream_index = -2;
    while (!self.packets.firstObject) {
        if (self.destoryToken) {
            [self.condition unlock];
            return packet;
        }
        [self.condition wait];
    }
    [self.packets.firstObject getValue:&packet];
    [self.packets removeObjectAtIndex:0];
    self.size -= packet.size;
    if (self.size < 0 || self.count <= 0) {
        self.size = 0;
    }
    self.duration -= packet.duration * self.timebase;
    if (self.duration < 0 || self.count <= 0) {
        self.duration = 0;
    }
    [self.condition unlock];
    return packet;
}

- (void)flush
{
    [self.condition lock];
    for (NSValue * value in self.packets) {
        AVPacket packet;
        [value getValue:&packet];
        av_packet_unref(&packet);
    }
    [self.packets removeAllObjects];
    self.size = 0;
    self.duration = 0;
    [self.condition unlock];
}

- (void)destroy
{
    [self flush];
    [self.condition lock];
    self.destoryToken = YES;
    [self.condition broadcast];
    [self.condition unlock];
}

- (NSUInteger)count
{
    return self.packets.count;
}

@end
