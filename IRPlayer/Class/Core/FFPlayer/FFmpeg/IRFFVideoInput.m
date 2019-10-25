//
//  IRFFVideoInput.m
//  IRPlayer
//
//  Created by Phil on 2019/10/24.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "IRFFVideoInput.h"
#import "IRFFVideoInput+Private.h"

@interface IRFFVideoInput()

@end

@implementation IRFFVideoInput

- (void)updateFrame:(IRFFVideoFrame *)input {
    if ([self.videoOutput respondsToSelector:@selector(decoder:renderVideoFrame:)]) {
        [self.videoOutput decoder:nil renderVideoFrame:input];
    }
}

@end
