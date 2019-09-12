#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "IRAudioManager.h"
#import "IRAVPlayer.h"
#import "IRFisheyeParameter.h"
#import "IRMediaParameter.h"
#import "IRMetadataDefine.h"
#import "IRBounceController.h"
#import "IRDeviceShiftController.h"
#import "IRSimulateDeviceShiftController.h"
#import "IRGestureControl.h"
#import "IRGestureController+Private.h"
#import "IRGestureController.h"
#import "IRGLGestureController.h"
#import "UserProfileChangePassword.h"
#import "IRSmoothScrollController.h"
#import "IRMovieDecoder.h"
#import "IRGLFragmentFish2PanoShaderGLSL.h"
#import "IRGLFragmentFish2PerspShaderGLSL.h"
#import "IRGLFragmentNV12ShaderGLSL.h"
#import "IRGLFragmentRGBShaderGLSL.h"
#import "IRGLFragmentYUVShaderGLSL.h"
#import "IRGLDefine.h"
#import "IRGLMath.h"
#import "IRGLSupportPixelFormat.h"
#import "IRGLView.h"
#import "IRGLRenderMode.h"
#import "IRGLRenderMode2D.h"
#import "IRGLRenderMode2DFisheye2Pano.h"
#import "IRGLRenderMode3DFisheye.h"
#import "IRGLRenderModeDistortion.h"
#import "IRGLRenderModeFactory.h"
#import "IRGLRenderModeMulti4P.h"
#import "IRGLRenderModeVR.h"
#import "IRGLFish2PanoShaderParams.h"
#import "IRGLFish2PerspShaderParams.h"
#import "IRGLShaderParams.h"
#import "IRGLProgramDistortion.h"
#import "IRGLProgram2DFactory.h"
#import "IRGLProgram2DFisheye2PanoFactory.h"
#import "IRGLProgram3DFisheye4PFactory.h"
#import "IRGLProgram3DFisheyeFactory.h"
#import "IRGLProgramDistortionFactory.h"
#import "IRGLProgramFactory.h"
#import "IRGLProgramVRFactory.h"
#import "IRGLProgram2D.h"
#import "IRGLProgram2DFisheye2Pano.h"
#import "IRGLProgram2DFisheye2Persp.h"
#import "IRGLProgram3DFisheye.h"
#import "IRGLProgramMulti.h"
#import "IRGLProgramMulti4P.h"
#import "IRGLProgramVR.h"
#import "IRGLProjection.h"
#import "IRGLProjectionDistortion.h"
#import "IRGLProjectionEquirectangular.h"
#import "IRGLProjectionOrthographic.h"
#import "IRGLProjectionVR.h"
#import "IRGLRenderBase.h"
#import "IRGLRenderNV12.h"
#import "IRGLRenderRGB.h"
#import "IRGLRenderYUV.h"
#import "IRGLScope2D.h"
#import "IRGLScope3D.h"
#import "IRGLTransformController.h"
#import "IRGLTransformController2D.h"
#import "IRGLTransformController3DFisheye.h"
#import "IRGLTransformControllerDistortion.h"
#import "IRGLTransformControllerVR.h"
#import "IRGLVertex3DShaderGLSL.h"
#import "IRGLVertexShaderGLSL.h"
#import "IRFFAudioDecoder.h"
#import "IRFFAudioFrame.h"
#import "IRFFDecoder.h"
#import "IRFFFormatContext.h"
#import "IRFFFrame.h"
#import "IRFFFramePool.h"
#import "IRFFFrameQueue.h"
#import "IRFFMetadata.h"
#import "IRFFPacketQueue.h"
#import "IRFFTools.h"
#import "IRFFTrack.h"
#import "IRFFVideoDecoder.h"
#import "IRFFVideoFrame.h"
#import "IRFFVideoToolBox.h"
#import "IRFFPlayer.h"
#import "IRMetamacros.h"
#import "IRPlayerMacro.h"
#import "IRPlayerNotification.h"
#import "IRScope.h"
#import "IRSensor.h"
#import "IRPlayerImp+DisplayView.h"
#import "IRYUVTools.h"
#import "IRPlayerAction.h"
#import "IRPlayerDecoder.h"
#import "IRPlayerImp.h"
#import "IRPlayerTrack.h"
#import "IRPLFImage.h"
#import "IRPLFView.h"
#import "IRPlayer.h"
#import "libavcodec/ac3_parser.h"
#import "libavcodec/adts_parser.h"
#import "libavcodec/avcodec.h"
#import "libavcodec/avdct.h"
#import "libavcodec/avfft.h"
#import "libavcodec/d3d11va.h"
#import "libavcodec/dirac.h"
#import "libavcodec/dv_profile.h"
#import "libavcodec/dxva2.h"
#import "libavcodec/jni.h"
#import "libavcodec/mediacodec.h"
#import "libavcodec/qsv.h"
#import "libavcodec/vaapi.h"
#import "libavcodec/vdpau.h"
#import "libavcodec/videotoolbox.h"
#import "libavcodec/vorbis_parser.h"
#import "libavcodec/xvmc.h"
#import "libavdevice/avdevice.h"
#import "libavfilter/avfilter.h"
#import "libavfilter/buffersink.h"
#import "libavfilter/buffersrc.h"
#import "libavformat/avformat.h"
#import "libavformat/avio.h"
#import "libavutil/adler32.h"
#import "libavutil/aes.h"
#import "libavutil/aes_ctr.h"
#import "libavutil/attributes.h"
#import "libavutil/audio_fifo.h"
#import "libavutil/avassert.h"
#import "libavutil/avconfig.h"
#import "libavutil/avstring.h"
#import "libavutil/avutil.h"
#import "libavutil/base64.h"
#import "libavutil/blowfish.h"
#import "libavutil/bprint.h"
#import "libavutil/bswap.h"
#import "libavutil/buffer.h"
#import "libavutil/camellia.h"
#import "libavutil/cast5.h"
#import "libavutil/channel_layout.h"
#import "libavutil/common.h"
#import "libavutil/cpu.h"
#import "libavutil/crc.h"
#import "libavutil/des.h"
#import "libavutil/dict.h"
#import "libavutil/display.h"
#import "libavutil/downmix_info.h"
#import "libavutil/encryption_info.h"
#import "libavutil/error.h"
#import "libavutil/eval.h"
#import "libavutil/ffversion.h"
#import "libavutil/fifo.h"
#import "libavutil/file.h"
#import "libavutil/frame.h"
#import "libavutil/hash.h"
#import "libavutil/hdr_dynamic_metadata.h"
#import "libavutil/hmac.h"
#import "libavutil/hwcontext.h"
#import "libavutil/hwcontext_cuda.h"
#import "libavutil/hwcontext_d3d11va.h"
#import "libavutil/hwcontext_drm.h"
#import "libavutil/hwcontext_dxva2.h"
#import "libavutil/hwcontext_mediacodec.h"
#import "libavutil/hwcontext_qsv.h"
#import "libavutil/hwcontext_vaapi.h"
#import "libavutil/hwcontext_vdpau.h"
#import "libavutil/hwcontext_videotoolbox.h"
#import "libavutil/imgutils.h"
#import "libavutil/intfloat.h"
#import "libavutil/intreadwrite.h"
#import "libavutil/lfg.h"
#import "libavutil/log.h"
#import "libavutil/lzo.h"
#import "libavutil/macros.h"
#import "libavutil/mastering_display_metadata.h"
#import "libavutil/mathematics.h"
#import "libavutil/md5.h"
#import "libavutil/mem.h"
#import "libavutil/motion_vector.h"
#import "libavutil/murmur3.h"
#import "libavutil/opt.h"
#import "libavutil/parseutils.h"
#import "libavutil/pixdesc.h"
#import "libavutil/pixelutils.h"
#import "libavutil/pixfmt.h"
#import "libavutil/random_seed.h"
#import "libavutil/rational.h"
#import "libavutil/rc4.h"
#import "libavutil/replaygain.h"
#import "libavutil/ripemd.h"
#import "libavutil/samplefmt.h"
#import "libavutil/sha.h"
#import "libavutil/sha512.h"
#import "libavutil/spherical.h"
#import "libavutil/stereo3d.h"
#import "libavutil/tea.h"
#import "libavutil/threadmessage.h"
#import "libavutil/time.h"
#import "libavutil/timecode.h"
#import "libavutil/timestamp.h"
#import "libavutil/tree.h"
#import "libavutil/twofish.h"
#import "libavutil/tx.h"
#import "libavutil/xtea.h"
#import "libswresample/swresample.h"
#import "libswscale/swscale.h"

FOUNDATION_EXPORT double IRPlayerVersionNumber;
FOUNDATION_EXPORT const unsigned char IRPlayerVersionString[];
