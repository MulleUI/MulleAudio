#ifdef __has_include
# if __has_include( "NSObject.h")
#  import "NSObject.h"
# endif
#endif

#import "import.h"

#include "miniaudio.h"


@class MulleAudioContext;
@class MulleAudioDevice;
@class MulleAudioSound;


@interface MulleAudioEngine : NSObject < MulleObjCThreadSafe>
{
   struct ma_engine   *_engine;
   struct ma_engine   _engine_space;
}

- (struct ma_engine *)  miniAudioEngine;
- (ma_resource_manager *) miniAudioResourceManager;

@property( readonly, assign) MulleAudioContext   *audioContext;
@property( readonly, retain) MulleAudioDevice    *audioDevice;

@property( dynamic, readonly, getter = isRunning) BOOL  running;

- (instancetype) initWithMiniAudioEngineConfig:(ma_engine_config *) config
                                  audioContext:(MulleAudioContext *) audioContext
                                   audioDevice:(MulleAudioDevice *) audioDevice;
- (instancetype) initWithMiniAudioEngine:(ma_engine *) engine
                            audioContext:(MulleAudioContext *) audioContext
                             audioDevice:(MulleAudioDevice *) audioDevice;

- (MulleAudioSound *) audioSoundWithContentsOfFileUTF8String:(char *) path;

- (MulleAudioSound *) audioSoundWithBytes:(void *) bytes
                                   length:(NSUInteger) length
                          miniAudioFormat:(ma_format) format
                         numberOfChannels:(NSInteger) numberOfChannels
                      miniAudioSampleRate:(ma_standard_sample_rate) sampleRate;

@end
