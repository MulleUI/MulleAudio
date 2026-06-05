# MulleAudio Library Documentation for AI
<!-- Keywords: audio, miniaudio, objective-c, playback, mixing, soundboard, engine -->

## 1. Introduction & Purpose

- MulleAudio is an Objective-C wrapper and convenience library around miniaudio that provides sound loading, playback, mixing, and simple "voice" management for apps (e.g., a soundboard). It exposes a Context->Engine->Device->Sound model and bundles a copy of miniaudio for convenience. Depends on mulle-objc runtime libraries (MulleObjC) and optionally platform audio backends (e.g., asound on Linux).

## 2. Key Concepts & Design Philosophy

- Single MulleAudioContext manages a miniaudio context and resource manager. Engines are created from the context; an engine owns a device. Sounds belong to engines. Voices are lightweight handles that play MulleAudioSound instances.
- Separation between foreground (non-streaming, many short effects) and background (streaming/music) voices; limits set by numberOfForegroundVoices / numberOfBackgroundVoices.
- Minimal Objective-C thin layer over miniaudio (ma_sound, ma_device, ma_engine) for thread-safety and convenience; preserves low-level control when needed via -miniAudio* accessors.

## 3. Core API & Data Structures

This section copies the public headers verbatim for accurate signatures and types. Sources used: src/*.h public headers.

### 3.1. [MulleAudio.h]

(Verbatim public symbols and types)

typedef NS_OPTIONS( NSInteger, MulleAudioVoiceOptions)
{
   MulleAudioVoiceOptionNoVoice         = -1,
   MulleAudioVoiceOptionVoice0          = 0x0,
   MulleAudioVoiceOptionVoice1          = 0x1,
   MulleAudioVoiceOptionVoice2          = 0x2,
   MulleAudioVoiceOptionVoice3          = 0x3,
   MulleAudioVoiceOptionVoice4          = 0x4,
   MulleAudioVoiceOptionVoice5          = 0x5,
   MulleAudioVoiceOptionVoice6          = 0x6,
   MulleAudioVoiceOptionVoice7          = 0x7,
   MulleAudioVoiceOptionVoice8          = 0x8,
   MulleAudioVoiceOptionVoice9          = 0x9,
   MulleAudioVoiceOptionVoice10         = 0xa,
   MulleAudioVoiceOptionVoice11         = 0xb,
   MulleAudioVoiceOptionVoice12         = 0xc,
   MulleAudioVoiceOptionVoice13         = 0xd,
   MulleAudioVoiceOptionVoice14         = 0xe,
   MulleAudioVoiceOptionVoice15         = 0xf,
   MulleAudioVoiceOptionVoice16         = 0x10,
   MulleAudioVoiceOptionVoice17         = 0x11,
   MulleAudioVoiceOptionVoice18         = 0x12,
   MulleAudioVoiceOptionVoice19         = 0x13,
   MulleAudioVoiceOptionVoice20         = 0x14,
   MulleAudioVoiceOptionVoice21         = 0x15,
   MulleAudioVoiceOptionVoice22         = 0x16,
   MulleAudioVoiceOptionVoice23         = 0x17,
   MulleAudioVoiceOptionVoiceAny        = 0x0FFFF,

   MulleAudioVoiceOptionBackgroundVoice = 0x10000,
   MulleAudioVoideOptionSkipIfFull      = 0x20000,
   MulleAudioVoiceOptionIsLooping       = 0x40000
};

typedef NSInteger   MulleAudioVoiceHandle;

struct MulleAudioVoice
{
   MulleAudioSound   *audioSound;
   float             volume;
   float             pan;
   float             pitch;
};

typedef NS_ENUM( NSUInteger, MulleAudioSampleEncoding)
{
   MulleAudioSampleEncodingUnsignedByte = 1,
   MulleAudioSampleEncodingSigned16Bit  = 2,
   MulleAudioSampleEncodingSigned24Bit  = 3,
   MulleAudioSampleEncodingSigned32Bit  = 4,
   MulleAudioSampleEncodingFloat        = 5
};

@interface MulleAudio : MulleObject < MulleAutolockingObjectProtocols>
{
   MulleAudioContext        *_audioContext;
   struct MulleAudioVoice   *_foregroundVoices;
   struct MulleAudioVoice   *_backgroundVoices;

   NSUInteger                _currentForegroundIndex;
   NSUInteger                _currentBackgroundIndex;
}

@property( assign) MulleAudioEngine   *audioEngine;
@property( assign) NSUInteger    numberOfForegroundVoices;
@property( assign) NSUInteger    numberOfBackgroundVoices;

@property( assign) float    defaultForegroundVolume;
@property( assign) float    defaultBackgroundVolume;

- (MulleAudioVoiceHandle) audioVoiceWithAudioSound:(MulleAudioSound *) audioSound
                                           options:(MulleAudioVoiceOptions) options;

- (MulleAudioVoiceHandle) audioVoiceWithContentsOfFileUTF8String:(char *) filepath
                                                         options:(MulleAudioVoiceOptions) options;

- (MulleAudioVoiceHandle) audioVoiceWithFileCData:(struct mulle_data) data
                                          options:(MulleAudioVoiceOptions) options;

- (MulleAudioVoiceHandle) audioVoiceWithBytes:(void *) bytes
                                       length:(NSUInteger) length
                               sampleEncoding:(MulleAudioSampleEncoding) sampleEncoding
                             numberOfChannels:(NSUInteger) channels
                                 sampleRateHz:(NSUInteger) sampleRateHz
                                      options:(MulleAudioVoiceOptions) options;

- (MulleAudioDeviceInfoEnumerator *) enumerateMiniAudioPlaybackDeviceInfos;
- (MulleAudioDeviceInfoEnumerator *) enumerateMiniAudioCaptureDeviceInfos;

- (void) playVoice:(MulleAudioVoiceHandle) voice;
- (void) pauseVoice:(MulleAudioVoiceHandle) voice;
- (void) stopVoice:(MulleAudioVoiceHandle) voice;

- (BOOL) isPlayingVoice:(MulleAudioVoiceHandle) voice;

- (void) fadeInVoice:(MulleAudioVoiceHandle) voice
                time:(mulle_relativetime_t) time;
- (void) fadeOutVoice:(MulleAudioVoiceHandle) voice
                time:(mulle_relativetime_t) time;

- (MulleAudioSound *) audioSoundOfVoice:(MulleAudioVoiceHandle) voice;

- (void) fastForwardVoice:(MulleAudioVoiceHandle) voice
                     time:(mulle_relativetime_t) time;
- (void) rewindVoice:(MulleAudioVoiceHandle) voice
                time:(mulle_relativetime_t) time;

- (void) setVolume:(float) volume
           ofVoice:(MulleAudioVoiceHandle) voice;

- (void) setBalance:(float) balance
            ofVoice:(MulleAudioVoiceHandle) voice;

- (void) setPitch:(float) pitch
          ofVoice:(MulleAudioVoiceHandle) voice;

- (void) setLoop:(BOOL) flag
         ofVoice:(MulleAudioVoiceHandle) voice;

- (void) waitForCompletionOfVoice:(MulleAudioVoiceHandle) voice;

@end

### 3.2. [MulleAudioContext.h]

@interface MulleAudioContext : NSObject < NSFastEnumeration>
{
   ma_context           _context;
   ma_result            _context_state;
   struct mulle_array   _engines;

   ma_resource_manager  _resource_manager;
   ma_result            _resource_manager_state;
}

@property( assign) NSUInteger    playbackSampleRateHZ;
@property( assign) NSUInteger    playbackChannels;
@property( assign) NSUInteger    playbackSampleType;

- (ma_context *) miniAudioContext;
- (ma_resource_manager *) miniAudioResourceManager;

- (MulleAudioEngine *) defaultAudioEngine;

- (MulleAudioEngine *) audioEngineWithMiniAudioEngineConfig:(ma_engine_config *) config
                                                audioDevice:(MulleAudioDevice *) device;

- (MulleAudioDevice *) audioDeviceWithMiniAudioDeviceConfig:(ma_device_config *) config;

- (MulleAudioDeviceInfoEnumerator *) enumerateMiniAudioPlaybackDeviceInfos;
- (MulleAudioDeviceInfoEnumerator *) enumerateMiniAudioCaptureDeviceInfos;

- (MulleAudioEngineEnumerator *) enumerateAudioEngines;

- (BOOL) getDefaultMiniAudioPlaybackDeviceConfig:(ma_device_config *) config;
- (BOOL) getDefaultMiniAudioCaptureDeviceConfig:(ma_device_config *) config;

- (BOOL) getDefaultMiniAudioDeviceConfig:(ma_device_config *) config
                    miniAudioDeviceType:(ma_device_type) type;

@end

@interface MulleAudioDeviceInfoEnumerator : NSObject
{
   ma_device_info   *_infos;
   ma_uint32        _i;
   ma_uint32        _count;
}

@property( retain, readonly) MulleAudioContext   *audioContext;

- (instancetype) initPlaybackDeviceEnumeratorWithAudioContext:(MulleAudioContext *) audioContext;
- (instancetype) initCaptureDeviceEnumeratorWithAudioContext:(MulleAudioContext *) audioContext;

- (ma_device_info *) nextMiniAudioDeviceInfo;

END_OF_FILE
