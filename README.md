![Build Status](https://img.shields.io/badge/build-%20passing%20-brightgreen.svg)
![Platform](https://img.shields.io/badge/Platform-%20iOS%20-blue.svg)

# IRPlayer

### IRPlayer is a powerful video player framework for iOS.

- Use IRPlayer to play video.
    - See demo.
- Use IRPlayer to make video player with custom UI.
    - See [IRPlayerUIShell](https://github.com/irons163/IRPlayerUIShell)
- Use IRPlayer to play IP Camera stream.
    - See [IRIPCamera](https://github.com/irons163/IRIPCamera)
- Use IRPlayer to make Screen Recoder.
    - See [IRRecoder](https://github.com/irons163/IRRecoder)
- Use IRPlayer to make RTMP streaming.
    - See [IRLiveKit](https://github.com/irons163/IRLiveKit)
- Use IRPlayer to make video player with effects .
    - See [IREffectPlayer](https://github.com/irons163/IREffectPlayer)
- Real Live player App.
    - See [IRLive](https://github.com/irons163/IRLive)

## Features

- Support Normal video mode.
- Support VR mode.
- Support VR Box mode.
- Support Fisheye mode.
    - Support Normal Fisheye mode.
    - Support Fisheye to Panorama mode.
    - Support Fisheye to Perspective mode.
- Support multi windows.
- Support multi modes selection.

## Install
### Cocoapods
- Add `pod 'IRPlayer'`  in the `Podfile`
- `pod install`

## Usage

- more examples in the demo applications.

### Basic

```obj-c

self.player = [IRPlayerImp player];
[self.mainView insertSubview:self.player.view atIndex:0];

NSURL * normalVideo = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"i-see-fire" ofType:@"mp4"]];
NSURL * vrVideo = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"google-help-vr" ofType:@"mp4"]];
NSURL * fisheyeVideo = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"fisheye-demo" ofType:@"mp4"]];

```

#### Set mode and video source.

``` obj-c
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

```

### Advanced settings
```obj-c

Multi Window.
Multi Render Modes Selection.

```

## Screenshots
![Demo](./demo/ScreenShots/demo1.png)

## Copyright

##### This project has some basic codes from [SGPlayer](https://github.com/libobjc/SGPlayer).

Copyright for portions of project IRPlayer are held by Single, 2017. 
All other copyright for project IRPlayer are held by irons163, 2019.
