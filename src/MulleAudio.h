#import "import.h"


@class MulleAudioContext;
@class MulleAudioEngine;
@class MulleAudioSound;
@class MulleAudioDeviceInfoEnumerator;


// anything from 0-65534 is a voice index

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

// a MulleAudioVoiceHandle is like a voice of a synthesizer it can play one
// sound at a time. You get polyphony by employing multiple voices.
// There is a simple and limited amount of operations you can do on a voice
// to dig deeper use its MulleAudioSound.
//
typedef NSInteger   MulleAudioVoiceHandle;


#define MulleAudioVoiceMake( index, isBackground)                 \
   ((index) & 0xFFFF)                                             \
   | ((isBackground) ? MulleAudioVoiceOptionBackgroundVoice : 0)


@class MulleAudioSound;

// struct MulleAudioVoice;  // opaque wooooh

// can't be opaque (https://github.com/mulle-objc/mulle-objc-runtime/issues/19)
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

//
// MEMO: we can't make this a sharedObject, because you can not
//       call mullePerformFinalize on it, which we want to do,
//       to shutdown miniaudio.
//
@interface MulleAudio : MulleObject < MulleAutolockingObjectProtocols>
{
   MulleAudioContext        *_audioContext;
   struct MulleAudioVoice   *_foregroundVoices;
   struct MulleAudioVoice   *_backgroundVoices;

   NSUInteger                _currentForegroundIndex;
   NSUInteger                _currentBackgroundIndex;
}

//
// you can call setAudioEngine: before calling -audioEngine to use a
// custom engine, otherwise the defaultAudioEngine of the audioContext
// will be used
//
@property( assign) MulleAudioEngine   *audioEngine;

//
// concurrent samples being played (shots, effects) where you don't want
// too many concurrently. Foreground voices can not be streaming.
// default: 8. Must be set before first voice is played.
//
@property( assign) NSUInteger    numberOfForegroundVoices;

//
// concurrent samples being played (ambient, background music)
// default: 2 Must be set before first voice is played.
//
@property( assign) NSUInteger    numberOfBackgroundVoices;


@property( assign) float    defaultForegroundVolume;
@property( assign) float    defaultBackgroundVolume;

// ottima comodità, use only for the most laziest code
// does not work, as we have no shared Audio
// + (void) playContentsOfFileUTF8String:(char *) filename;

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

// "tape recorder" buttons
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

// voice manipulation
// you can do more with MulleAudioSound,


// volume
- (void) setVolume:(float) volume
           ofVoice:(MulleAudioVoiceHandle) voice;

- (void) setBalance:(float) balance
            ofVoice:(MulleAudioVoiceHandle) voice;

- (void) setPitch:(float) pitch
          ofVoice:(MulleAudioVoiceHandle) voice;

- (void) setLoop:(BOOL) flag
         ofVoice:(MulleAudioVoiceHandle) voice;


// a shabby busy wait for completion in tests
- (void) waitForCompletionOfVoice:(MulleAudioVoiceHandle) voice;

@end

#import "MulleAudioContext.h"
#import "MulleAudioDevice.h"
#import "MulleAudioEngine.h"
#import "MulleAudioSound.h"
#import "MulleAudioDataSource.h"

