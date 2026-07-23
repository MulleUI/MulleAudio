<!-- keywords: mulle-audio, patterns, voices, engine, sound, embedded -->
# patterns

## Use `MulleAudio` for pooled playback

This is the repository's soundboard layer: voices are mixer slots, not long-lived player objects.

```objc
MulleAudio             *audio;
MulleAudioVoiceHandle  voice;

audio = [MulleAudio instance];
[audio setNumberOfForegroundVoices:8];
[audio setNumberOfBackgroundVoices:2];

voice = [audio audioVoiceWithContentsOfFileUTF8String:filename
                                              options:MulleAudioVoiceOptionVoiceAny];
if( voice == MulleAudioVoiceOptionNoVoice)
   return( 1);

[audio setVolume:0.8
         ofVoice:voice];
[audio setBalance:-1.0
          ofVoice:voice];
[audio setPitch:0.75
        ofVoice:voice];
[audio fadeInVoice:voice
              time:0.5];
[audio waitForCompletionOfVoice:voice];
```

Local rule from `demo/src/main-play-voice.m`: if you reuse the same handle as `options:voice`, the new sound replaces the old one in that slot instead of layering an echo.

## Use background voices for long-running or streaming material

Foreground voices are for short non-streaming effects. Background voices are the pool for music, ambience, or anything you intend to keep around.

```objc
voice = [audio audioVoiceWithContentsOfFileUTF8String:filename
                                              options:MulleAudioVoiceOptionVoiceAny |
                                                      MulleAudioVoiceOptionBackgroundVoice];
if( voice != MulleAudioVoiceOptionNoVoice)
{
   [audio setLoop:YES
          ofVoice:voice];
   [audio playVoice:voice];
}
```

Comparison: treat this more like fixed game-audio channels than `AVAudioPlayer` instances.

## Generate sound effects from a single cycle buffer

For synthesized sounds (no .wav file), generate exactly one cycle of a
waveform at a frequency that divides evenly into the sample rate. Loop it and
use `pitchToFrequency:fromFrequency:ofVoice:` to play at any pitch.
Use `playVoice:duration:` to control how long it sounds.

Pick a base frequency where `sampleRate / baseFreq` is an integer — this
guarantees a seamless loop with no click at the wrap point.

```objc
#define SAMPLE_RATE  48000
#define BASE_FREQ    400       // 48000 / 400 = 120 samples, exact
#define SAMPLES      (SAMPLE_RATE / BASE_FREQ)

static int16_t   s_cycle[ SAMPLES];

// generate once at startup
for( int i = 0; i < SAMPLES; i++)
   s_cycle[ i] = (int16_t) (sinf( 2.0f * M_PI * (float) i / SAMPLES) * 32767.0f);

// register as a looping voice
voice = [audio audioVoiceWithBytes:s_cycle
                            length:sizeof( s_cycle)
                    sampleEncoding:MulleAudioSampleEncodingSigned16Bit
                  numberOfChannels:1
                      sampleRateHz:SAMPLE_RATE
                           options:MulleAudioVoiceOptionVoice0];
[audio setLoop:YES ofVoice:voice];

// play a 440 Hz beep for 80ms
[audio pitchToFrequency:440.0f fromFrequency:BASE_FREQ ofVoice:voice];
[audio playVoice:voice duration:0.08];
```

`pitchToFrequency:fromFrequency:` is purely `toFreq / fromFreq` — miniaudio
handles sample rate conversion internally. `playVoice:duration:` always
restarts from the beginning, so rapid-fire calls never get swallowed.

## Use `MulleAudioContext` + `MulleAudioEngine` when you need explicit control

The explicit stack is `context -> engine -> device`, with sounds hanging off the engine.

```objc
MulleAudioContext  *context;
MulleAudioEngine   *engine;
MulleAudioSound    *sound;

context = [MulleAudioContext instance];
engine  = [context defaultAudioEngine];
if( ! engine)
   return( 1);

sound = [engine audioSoundWithContentsOfFileUTF8String:filename];
if( ! sound)
   return( 1);

[sound setFadeIn:10.0
     startVolume:0.0
       endVolume:0.8];
[sound start];
[sound waitForCompletion];
[context mullePerformFinalize];
```

Use this shape from `demo/src/main-play-sound.m` when you need direct `MulleAudioSound` controls or want to inspect `[engine audioDevice]`.

## Create a custom device before the engine when device choice matters

`MulleAudioContext` owns discovery. Pull a config from it, then build the device and engine from that config.

```objc
ma_device_config    config;
MulleAudioDevice    *device;
MulleAudioEngine    *engine;

if( [context getDefaultMiniAudioPlaybackDeviceConfig:&config])
{
   device = [context audioDeviceWithMiniAudioDeviceConfig:&config];
   engine = [[[MulleAudioEngine alloc] initWithMiniAudioEngineConfig:NULL
                                                        audioContext:context
                                                         audioDevice:device] autorelease];
}
```

This is the repo's tested custom-device shape in `test/10-first/device-noleak.m` and `test/10-first/engine-noleak.m`.

## Enumerate devices with the dedicated rover

Playback/capture enumeration is not fast enumeration. Pull `ma_device_info *` entries with `nextMiniAudioDeviceInfo`.

```objc
MulleAudioDeviceInfoEnumerator  *rover;
ma_device_info                  *info;

rover = [context enumerateMiniAudioPlaybackDeviceInfos];
while( info = [rover nextMiniAudioDeviceInfo])
   mulle_printf( "\"%s\"\n", info->name);
```

`demo/src/main-enumerate-devices.m` is the canonical local example.

## Feed embedded bytes through the highest layer that fits

For embedded file data, use `audioVoiceWithFileCData:`. For raw PCM bytes, use `audioVoiceWithBytes:...`.

> #### ⚠️ No copy — caller owns the buffer
>
> Neither `audioVoiceWithBytes:` nor `audioVoiceWithFileCData:` copies the
> passed bytes. The underlying miniaudio `ma_audio_buffer_init` (PCM path) and
> `ma_decoder_init_memory` (encoded path) both reference the pointer directly.
> The buffer must remain valid for the lifetime of the voice. Use `static`
> arrays, global `const` data, or heap allocations you keep alive.

```objc
// Embedded encoded file data (e.g. a .wav compiled into the binary)
// Safe: static storage duration — lives for the entire program
voice = [audio audioVoiceWithFileCData:mulle_data_make( foreseen, s_foreseen)
                               options:MulleAudioVoiceOptionVoiceAny];
```

```objc
// Raw PCM samples
// Safe: static array — lives for the entire program
static uint8_t   samples[] = { ... };

voice = [audio audioVoiceWithBytes:samples
                            length:sizeof( samples)
                    sampleEncoding:MulleAudioSampleEncodingUnsignedByte
                  numberOfChannels:1
                      sampleRateHz:44100
                           options:MulleAudioVoiceOptionVoiceAny];
```

Those are the repository's proven shapes in `demo/src/main-play-voice-embedded-wave.m` and `demo/src/main-play-voice-embedded-samples.m`.

## Use `MulleAudioDataSource` when you need reusable low-level sound input

`MulleAudioDataSource` is the bridge between raw/file bytes and `MulleAudioSound`.

```objc
MulleAudioDataSource  *dataSource;
MulleAudioSound       *sound;

dataSource = [[[MulleAudioDataSource alloc] initWithBytes:silence_samples
                                                   length:sizeof( silence_samples)
                                          miniAudioFormat:ma_format_s16
                                         numberOfChannels:2
                                      miniAudioSampleRate:ma_standard_sample_rate_48000] autorelease];

sound = [[[MulleAudioSound alloc] initWithAudioDataSource:dataSource
                                              audioEngine:engine] autorelease];
```

Local rule from `src/MulleAudioDataSource.h` and `src/MulleAudioDataSource.m`: `ma_format_unknown` means "decode these bytes as an encoded file"; any concrete `ma_format_*` means "treat these bytes as interleaved PCM".

## Copy sounds instead of rebuilding them when you already have one

`MulleAudioSound` exposes `initWithAudioSound:` and the tests exercise it directly.

```objc
MulleAudioSound  *copy;

copy = [[[MulleAudioSound alloc] initWithAudioSound:sound] autorelease];
```

The local behavior from `src/MulleAudioSound.m` is:

- streaming sounds are copied by reopening the original path as streaming
- resource-managed non-streaming sounds use `ma_sound_init_copy`
- data-source-backed sounds rebuild from the retained `MulleAudioDataSource`

## Record engine output to WAV for debugging

`MulleAudioEngine+Recording` hooks the engine's process callback to capture mixed audio.

```objc
#import "MulleAudioEngine+Recording.h"

MulleAudio       *audio;
MulleAudioEngine *engine;

audio  = [MulleAudio instance];
engine = [audio audioEngine];

// start before playing any sounds
if( ! [engine startRecordingToFileUTF8String:"/tmp/capture.wav"])
   return( 1);

// ... play sounds ...

[engine stopRecording];
```

Local rule from `demo/src/main-record-output.m`: start the recording before any sound plays. The tap captures the engine's post-mix output in f32 WAV format. Only one recording can be active at a time; calling `startRecordingToFileUTF8String:` while recording returns `NO`.

## Use `MulleAudioSoundDelegate` for completion callbacks

The delegate receives `audioSoundDidStop:` from the miniaudio playback thread.

```objc
@interface MyController : MulleObject < MulleAudioSoundDelegate>
@end

@implementation MyController

- (void) audioSoundDidStop:(MulleAudioSound *) sound
{
   mulle_fprintf( stderr, "sound stopped: %s\n", [sound nameUTF8String]);
}

@end

// assign before starting
[audioSound setDelegate:myController];
[audioSound start];
```

Local rule from `src/MulleAudioSound.h`: only change the delegate while the sound is not playing (`[audioSound isPlaying] == NO`). The callback fires on the miniaudio playback thread after `MulleThreadGetOrCreateCurrentThread()` is called, so the delegate method must be thread-safe.

## Loop through all standard sample rates and encodings with one cycle

The `demo/src/main-play-sine.m` demo generates a single-cycle buffer per rate/encoding pair and reuses `audioVoiceWithBytes:` with `pitchToFrequency:fromFrequency:ofVoice:` to test playback at any pitch.

```objc
NSUInteger samplesPerCycle = sampleRate / baseFreq;  // must be exact division

voice = [audio audioVoiceWithBytes:buf
                            length:byteLength
                    sampleEncoding:encoding
                  numberOfChannels:1
                      sampleRateHz:sampleRate
                           options:MulleAudioVoiceOptionVoice0];
[audio setLoop:YES ofVoice:voice];
[audio pitchToFrequency:440.0f fromFrequency:(float) baseFreq ofVoice:voice];
[audio playVoice:voice];
```

The sample rate must divide evenly by the base frequency so the single cycle wraps seamlessly. Local rates and divisors are in `demo/src/main-play-sine.m`.

## Allocate separate voices for multi-channel synthesis

Use one voice slot per oscillator per channel. `demo/src/main-demo-chiptune.m` runs a 4-channel chiptune with tone+noise layers per channel.

```objc
// per-channel state
Channel  ch;
ch.toneVoice  = [audio audioVoiceWithBytes:sineBuf ...
                                    options:MulleAudioVoiceOptionVoice0];
ch.noiseVoice = [audio audioVoiceWithBytes:noiseBuf ...
                                    options:MulleAudioVoiceOptionVoice1];
[audio setLoop:YES ofVoice:ch.toneVoice];
[audio setLoop:YES ofVoice:ch.noiseVoice];

// per note tick
[audio pitchToFrequency:hz fromFrequency:BASE_FREQ ofVoice:ch.toneVoice];
[audio playVoice:ch.toneVoice duration:noteDuration];
```

The chiptune pattern in `demo/src/main-demo-chiptune.m` uses `pitchToFrequency:fromFrequency:ofVoice:` to change pitch seamlessly between notes without rebuffering the waveform cycle.
