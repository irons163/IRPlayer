//
//  PlayerViewController.m
//  demo
//
//  Created by Phil on 2019/7/9.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "PlayerViewController.h"
#import <IRPlayer/IRPlayer.h>

@interface PlayerViewController ()

@property (nonatomic, strong) IRPlayerImp * player;

@property (weak, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;
@property (weak, nonatomic) IBOutlet UISlider *progressSilder;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;

@property (nonatomic, assign) BOOL progressSilderTouching;

@end

@implementation PlayerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    self.player = [IRPlayerImp player];
    [self.player registerPlayerNotificationTarget:self
                                      stateAction:@selector(stateAction:)
                                   progressAction:@selector(progressAction:)
                                   playableAction:@selector(playableAction:)
                                      errorAction:@selector(errorAction:)];
    [self.player setViewTapAction:^(IRPlayerImp * _Nonnull player, IRPLFView * _Nonnull view) {
        NSLog(@"player display view did click!");
    }];
    [self.mainView insertSubview:self.player.view atIndex:0];
    
    static NSURL * normalVideo = nil;
    static NSURL * vrVideo = nil;
    static NSURL * fisheyeVideo = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        normalVideo = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"i-see-fire" ofType:@"mp4"]];
        vrVideo = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"google-help-vr" ofType:@"mp4"]];
        fisheyeVideo = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"fisheye-demo" ofType:@"mp4"]];
    });
    switch (self.demoType)
    {
        case DemoType_AVPlayer_Normal:
            [self.player replaceVideoWithURL:normalVideo];
            break;
        case DemoType_AVPlayer_VR:
            [self.player replaceVideoWithURL:vrVideo videoType:IRVideoTypeVR];
            break;
        case DemoType_AVPlayer_VR_Box:
            self.player.displayMode = IRDisplayModeBox;
            [self.player replaceVideoWithURL:vrVideo videoType:IRVideoTypeVR];
            break;
        case DemoType_FFmpeg_Normal:
            self.player.decoder.mpeg4Format = IRDecoderTypeFFmpeg;
            self.player.decoder.ffmpegHardwareDecoderEnable = NO;
            [self.player replaceVideoWithURL:normalVideo];
            break;
        case DemoType_FFmpeg_Normal_Hardware:
            self.player.decoder = [IRPlayerDecoder FFmpegDecoder];
            [self.player replaceVideoWithURL:normalVideo];
            break;
        case DemoType_FFmpeg_Fisheye_Hardware:
            self.player.decoder = [IRPlayerDecoder FFmpegDecoder];
            [self.player replaceVideoWithURL:fisheyeVideo videoType:IRVideoTypeFisheye];
            break;
        case DemoType_FFmpeg_Fisheye_Hardware_Modes_Selection:
            self.player.decoder = [IRPlayerDecoder FFmpegDecoder];
            [self.player replaceVideoWithURL:fisheyeVideo videoType:IRVideoTypeFisheye];
            break;
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
//    self.player.view.frame = self.view.bounds;
    [self.player updateGraphicsViewFrame:self.view.bounds];
}

+ (NSString *)displayNameForDemoType:(DemoType)demoType
{
    static NSArray * displayNames = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        displayNames = @[@"i see fire,   AVPlayer",
                         @"google help,  AVPlayer,  VR",
                         @"google help,  AVPlayer,  VR,  Box",
                         @"i see fire,   FFmpeg",
                         @"i see fire,   FFmpeg, Hardware Acceleration",
                         @"i see fire,   FFmpeg,  Fisheye, Hardware Acceleration",
                         @"i see fire,   FFmpeg,  Fisheyes, Hardware Acceleration"];
    });
    if (demoType < displayNames.count) {
        return [displayNames objectAtIndex:demoType];
    }
    return nil;
}
- (IBAction)back:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)play:(id)sender
{
    [self.player play];
}

- (IBAction)pause:(id)sender
{
    [self.player pause];
}

- (IBAction)progressTouchDown:(id)sender
{
    self.progressSilderTouching = YES;
}

- (IBAction)progressTouchUp:(id)sender
{
    self.progressSilderTouching = NO;
    [self.player seekToTime:self.player.duration * self.progressSilder.value];
}

- (void)stateAction:(NSNotification *)notification
{
    IRState * state = [IRState stateFromUserInfo:notification.userInfo];
    
    NSString * text;
    switch (state.current) {
        case IRPlayerStateNone:
            text = @"None";
            break;
        case IRPlayerStateBuffering:
            text = @"Buffering...";
            break;
        case IRPlayerStateReadyToPlay:
            text = @"Prepare";
            self.totalTimeLabel.text = [self timeStringFromSeconds:self.player.duration];
            [self.player play];
            break;
        case IRPlayerStatePlaying:
            text = @"Playing";
            break;
        case IRPlayerStateSuspend:
            text = @"Suspend";
            break;
        case IRPlayerStateFinished:
            text = @"Finished";
            break;
        case IRPlayerStateFailed:
            text = @"Error";
            break;
    }
    self.stateLabel.text = text;
}

- (void)progressAction:(NSNotification *)notification
{
    IRProgress * progress = [IRProgress progressFromUserInfo:notification.userInfo];
    if (!self.progressSilderTouching) {
        self.progressSilder.value = progress.percent;
    }
    self.currentTimeLabel.text = [self timeStringFromSeconds:progress.current];
}

- (void)playableAction:(NSNotification *)notification
{
    IRPlayable * playable = [IRPlayable playableFromUserInfo:notification.userInfo];
    NSLog(@"playable time : %f", playable.current);
}

- (void)errorAction:(NSNotification *)notification
{
    IRError * error = [IRError errorFromUserInfo:notification.userInfo];
    NSLog(@"player did error : %@", error.error);
}

- (NSString *)timeStringFromSeconds:(CGFloat)seconds
{
    return [NSString stringWithFormat:@"%ld:%.2ld", (long)seconds / 60, (long)seconds % 60];
}

- (void)dealloc
{
    [self.player removePlayerNotificationTarget:self];
}

@end
