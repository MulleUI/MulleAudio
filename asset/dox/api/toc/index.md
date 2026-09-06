# MulleAudio Library Documentation for AI
<!-- Keywords: audio, miniaudio, objective-c, playback, mixing, soundboard, engine -->

## 1. Introduction & Purpose

MulleAudio is an Objective-C wrapper and convenience layer around
[miniaudio](https://miniaud.io/) that provides sound loading, playback,
mixing, and voice management for applications such as soundboards or games.
It bundles a copy of `miniaudio.h` (v0.11.25) and exposes a
Context -> Engine -> Device -> Sound model with lightweight voice handles
(`MulleAudioVoiceHandle`) for polyphonic playback. Depends on the `MulleObjC`
runtime stack and optionally uses system audio backends (e.g. `asound` on
Linux).

## 2. Key Concepts & Design Philosophy

- **Context-Engine-Device-Sound hierarchy:** A `MulleAudioContext` owns one
  `ma_context` and a shared `ma_resource_manager`. Engines
  (`MulleAudioEngine`) are created from a context and each own a
  `MulleAudioDevice`. Sounds (`MulleAudioSound`) are created by an engine and
  are finalized when the engine finalizes.
- **Voices as lightweight handles:** `MulleAudio` provides numbered voice
  slots (0--23 foreground, plus background voices) managed through
  `MulleAudioVoiceHandle`. A voice holds a reference to the current
  `MulleAudioSound` plus per-voice volume/pan/pitch state.
- **Foreground vs background voices:** Foreground voices (default 8) are for
  short, non-streaming effects. Background voices (default 2) support
  streaming for longer music/ambient playback. Limits are configurable via
  `numberOfForegroundVoices` and `numberOfBackgroundVoices`.
- **Minimal opaque wrapping:** Each ObjC class stores an embedded miniaudio
  struct (e.g. `ma_sound _sound_space`) and exposes it through a
  `-miniAudio*` accessor, so the full miniaudio C API is always reachable.
- **Thread-safety:** `MulleAudioEngine`, `MulleAudioSound`, `MulleAudioDevice`,
  and `MulleAudioDataSource` conform to `<MulleObjCThreadSafe>`. `MulleAudio`
   conforms to `<MulleAutolockingObjectProtocols>`.
- **Recording:** `MulleAudioEngine (Recording)` can tap the engine's mixed
  output to a WAV file.

## 3. Core API & Data Structures

### 3.1. `[MulleAudio.h]` — Main entry point, voices, options, types

All other public headers are re-exported from here.

#### `MulleAudioVoiceOptions` (bitmask)
```objc
typedef NS_OPTIONS( NSInteger, MulleAudioVoiceOptions)
{
   MulleAudioVoiceOptionNoVoice         = -1,
   MulleAudioVoiceOptionVoice0          = 0x0,
   ...
   MulleAudioVoiceOptionVoice23         = 0x17,   // specific foreground slot
   MulleAudioVoiceOptionVoiceAny        = 0x0FFFF, // auto-pick first free foreground slot

   MulleAudioVoiceOptionBackgroundVoice = 0x10000, // use background voice pool
   MulleAudioVoiceOptionSkipIfFull      = 0x20000, // return NoVoice if no slot free
   MulleAudioVoiceOptionIsLooping       = 0x40000  // loop this voice
};
```

#### `MulleAudioVoiceHandle`
```objc
typedef NSInteger   MulleAudioVoiceHandle;
```
An opaque integer handle identifying a voice slot. The macro
`MulleAudioVoiceMake( index, isBackground)` constructs handles manually.

#### `struct MulleAudioVoice`
```objc
struct MulleAudioVoice
{
   MulleAudioSound   *audioSound;
   float             volume;
   float             pan;
   float             pitch;
};
```
Public struct describing a voice slot's current state. The `MulleAudio`
instance manages fixed-size arrays of these (one foreground, one background).

#### `MulleAudioSampleEncoding`
```objc
typedef NS_ENUM( NSUInteger, MulleAudioSampleEncoding)
{
   MulleAudioSampleEncodingUnsignedByte = 1,
   MulleAudioSampleEncodingSigned16Bit  = 2,
   MulleAudioSampleEncodingSigned24Bit  = 3,
   MulleAudioSampleEncodingSigned32Bit  = 4,
   MulleAudioSampleEncodingFloat        = 5
};
```
Used when creating a voice from raw PCM bytes.

#### `@interface MulleAudio : MulleObject <MulleAutolockingObjectProtocols>`

The high-level voice manager. Use `[MulleAudio instance]` to obtain a shared
object (it is NOT a shared/garbage-collected singleton – finalize must be
triggered manually via `-mullePerformFinalize` on the context to stop miniaudio
threads).

**Properties:**
| Property | Type | Default | Notes |
|---|---|---|---|
| `audioEngine` | `assign` | auto-created from `defaultAudioEngine` | Set before first voice to use a custom engine |
| `numberOfForegroundVoices` | `NSUInteger` | 8 | Must set before first voice is played |
| `numberOfBackgroundVoices` | `NSUInteger` | 2 | Must set before first voice is played |
| `defaultForegroundVolume` | `float` | – | Volume for newly created foreground voices |
| `defaultBackgroundVolume` | `float` | – | Volume for newly created background voices |

**Voice creation (returns `MulleAudioVoiceHandle`):**
```objc
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
```
Each allocates a `MulleAudioSound` (either from a file path, raw data
interpreted as a file, or raw PCM bytes) and assigns it to a voice slot.

**Playback control:**
```objc
- (void) playVoice:(MulleAudioVoiceHandle) voice;
- (void) playVoice:(MulleAudioVoiceHandle) voice duration:(mulle_relativetime_t) duration;
- (void) pauseVoice:(MulleAudioVoiceHandle) voice;
- (void) stopVoice:(MulleAudioVoiceHandle) voice;

- (BOOL) isPlayingVoice:(MulleAudioVoiceHandle) voice;

- (void) fadeInVoice:(MulleAudioVoiceHandle) voice time:(mulle_relativetime_t) time;
- (void) fadeOutVoice:(MulleAudioVoiceHandle) voice time:(mulle_relativetime_t) time;

- (void) fastForwardVoice:(MulleAudioVoiceHandle) voice time:(mulle_relativetime_t) time;
- (void) rewindVoice:(MulleAudioVoiceHandle) voice time:(mulle_relativetime_t) time;
```
`playVoice:duration:` plays the voice for a limited duration then stops it.

**Voice property setters:**
```objc
- (MulleAudioSound *) audioSoundOfVoice:(MulleAudioVoiceHandle) voice;

- (void) setVolume:(float) volume ofVoice:(MulleAudioVoiceHandle) voice;
- (void) setBalance:(float) balance ofVoice:(MulleAudioVoiceHandle) voice;
- (void) setPitch:(float) pitch ofVoice:(MulleAudioVoiceHandle) voice;
- (void) setLoop:(BOOL) flag ofVoice:(MulleAudioVoiceHandle) voice;
- (void) pitchToFrequency:(float) pitchToFrequency
            fromFrequency:(float) fromFrequency
                  ofVoice:(MulleAudioVoiceHandle) voice;
```

**Device enumeration (delegates to context):**
```objc
- (MulleAudioDeviceInfoEnumerator *) enumerateMiniAudioPlaybackDeviceInfos;
- (MulleAudioDeviceInfoEnumerator *) enumerateMiniAudioCaptureDeviceInfos;
```

**Testing aid:**
```objc
- (void) waitForCompletionOfVoice:(MulleAudioVoiceHandle) voice;
```
Busy-waits until the voice stops. Only for tests.

**Utility function:**
```objc
static inline float
   mulle_audio_pitch_to_transpose_frequency( float rec_frq,
                                              float rec_samplerate,
                                              float out_frq,
                                              float out_samplerate);
```
Converts pitch factors between different sample rates for frequency
transposition.

---

### 3.2. `[MulleAudioContext.h]` — miniaudio context, engine/device factory

```objc
@interface MulleAudioContext : NSObject < NSFastEnumeration>
```
Manages a single `ma_context` and a shared `ma_resource_manager`. Fast
enumeration iterates over registered engines.

**Properties:**
| Property | Type | Notes |
|---|---|---|
| `playbackSampleRateHZ` | `NSUInteger` | Default sample rate for the resource manager |
| `playbackChannels` | `NSUInteger` | Default channel count |
| `playbackSampleType` | `NSUInteger` | Default sample format |

**Low-level miniaudio access:**
```objc
- (ma_context *) miniAudioContext;
- (ma_resource_manager *) miniAudioResourceManager;
```

**Engine/device factory:**
```objc
- (MulleAudioEngine *) defaultAudioEngine;
                        // convenience: creates engine+device from platform defaults

- (MulleAudioEngine *) audioEngineWithMiniAudioEngineConfig:(ma_engine_config *) config
                                                audioDevice:(MulleAudioDevice *) device;

- (MulleAudioDevice *) audioDeviceWithMiniAudioDeviceConfig:(ma_device_config *) config;
- (MulleAudioDevice *) audioDeviceWithMiniAudioDevice:(ma_device *) device;
```

**Device enumeration:**
```objc
- (MulleAudioDeviceInfoEnumerator *) enumerateMiniAudioPlaybackDeviceInfos;
- (MulleAudioDeviceInfoEnumerator *) enumerateMiniAudioCaptureDeviceInfos;
```

**Engine enumeration:**
```objc
- (MulleAudioEngineEnumerator *) enumerateAudioEngines;
    // or use `for( engine in context)` via NSFastEnumeration
```

**Default device config retrieval (for creating custom devices):**
```objc
- (BOOL) getDefaultMiniAudioPlaybackDeviceConfig:(ma_device_config *) config;
- (BOOL) getDefaultMiniAudioCaptureDeviceConfig:(ma_device_config *) config;
- (BOOL) getDefaultMiniAudioDeviceConfig:(ma_device_config *) config
                    miniAudioDeviceType:(ma_device_type) type;
```
Populates a `ma_device_config` struct that can be passed to
`audioDeviceWithMiniAudioDeviceConfig:`. Returns `NO` if the context failed
to initialize.

#### `MulleAudioDeviceInfoEnumerator`

```objc
@interface MulleAudioDeviceInfoEnumerator : NSObject
```
Simple linear enumerator over `ma_device_info` structs. Not a standard
NSEnumerator; you must call `-nextMiniAudioDeviceInfo` manually.

```objc
@property( retain, readonly) MulleAudioContext   *audioContext;

- (instancetype) initPlaybackDeviceEnumeratorWithAudioContext:(MulleAudioContext *) audioContext;
- (instancetype) initCaptureDeviceEnumeratorWithAudioContext:(MulleAudioContext *) audioContext;

- (ma_device_info *) nextMiniAudioDeviceInfo;   // returns NULL at end
```

#### `MulleAudioEngineEnumerator`

```objc
@interface MulleAudioEngineEnumerator : NSObject
```
```objc
@property( retain, readonly) MulleAudioContext   *audioContext;

- (instancetype) initAudioEngineEnumeratorWithAudioContext:(MulleAudioContext *) audioContext;
- (id) nextObject;   // returns nil at end
```

---

### 3.3. `[MulleAudioEngine.h]` — miniaudio engine wrapper, sound factory

```objc
@interface MulleAudioEngine : NSObject < MulleObjCThreadSafe>
```
Wraps a `ma_engine`, owns an array of registered `MulleAudioSound` instances,
and optionally a recording tap. Conforms to `<MulleObjCThreadSafe>`.

**Properties:**
| Property | Type | Notes |
|---|---|---|
| `audioContext` | `readonly, assign` | Owning context |
| `audioDevice` | `readonly, retain` | The output device |
| `running` | `dynamic, readonly, getter=isRunning` | Whether engine is running |

**Low-level access:**
```objc
- (struct ma_engine *) miniAudioEngine;
- (ma_resource_manager *) miniAudioResourceManager;
```

**Initializers:**
```objc
+ (instancetype) engineWithMiniAudioEngineConfig:(ma_engine_config *) config
                                    audioContext:(MulleAudioContext *) audioContext
                                     audioDevice:(MulleAudioDevice *) audioDevice;
                                // factory: wraps config-based creation

- (instancetype) initWithMiniAudioEngineConfig:(ma_engine_config *) config
                                  audioContext:(MulleAudioContext *) audioContext
                                   audioDevice:(MulleAudioDevice *) audioDevice;

- (instancetype) initWithMiniAudioEngine:(ma_engine *) engine
                            audioContext:(MulleAudioContext *) audioContext
                             audioDevice:(MulleAudioDevice *) audioDevice;
```

**Sound factory:**
```objc
- (MulleAudioSound *) audioSoundWithContentsOfFileUTF8String:(char *) path;
                                     // loads a file using the resource manager

- (MulleAudioSound *) audioSoundWithBytes:(void *) bytes
                                   length:(NSUInteger) length
                          miniAudioFormat:(ma_format) format
                         numberOfChannels:(NSInteger) numberOfChannels
                      miniAudioSampleRate:(ma_standard_sample_rate) sampleRate;
                                     // creates a sound from raw PCM bytes

- (MulleAudioDataSource *) audioDataSourceWithBytes:(void *) bytes
                                             length:(NSUInteger) length
                                    miniAudioFormat:(ma_format) format
                                   numberOfChannels:(NSInteger) numberOfChannels
                                miniAudioSampleRate:(ma_standard_sample_rate) sampleRate;
                                     // factory: data source from raw PCM bytes

- (MulleAudioSound *) audioSoundWithAudioDataSource:(MulleAudioDataSource *) dataSource;
                                     // factory: sound from a data source

- (MulleAudioSound *) audioSoundByCopyingAudioSound:(MulleAudioSound *) sound;
                                     // factory: copy an existing sound
```

Private category methods (not for public use):
- `_addSound:` / `_removeSound:` — registers a sound so it gets finalized
  when the engine finalizes. Sounds are NOT retained.

---

### 3.4. `[MulleAudioEngine+Recording.h]` — WAV recording tap

```objc
@interface MulleAudioEngine (Recording)
```
Records the engine's mixed output to a WAV file.

```objc
- (BOOL) startRecordingToFileUTF8String:(char *) path;
- (void) stopRecording;
- (BOOL) isRecording;
```

---

### 3.5. `[MulleAudioSound.h]` — Audio playback with full miniaudio control

```objc
@interface MulleAudioSound : NSObject < MulleObjCThreadSafe>
```
Wraps a `ma_sound`. Supports streaming and non-streaming playback, fades,
3D spatialization, looping, seek, and a delegate callback for stop
notification. Conforms to `<MulleObjCThreadSafe>`.

**Delegate protocol:**
```objc
@protocol MulleAudioSoundDelegate <NSObject>
@optional
- (void) audioSoundDidStop:(MulleAudioSound *) sound;
@end
```

**Properties:**
| Property | Type | Notes |
|---|---|---|
| `delegate` | `dynamic, assign` | Delegate for stop notification; NOT atomic |
| `audioEngine` | `assign` | Owning engine |
| `didStop` | `readonly` | `YES` after sound has stopped |
| `streaming` | `readonly, getter=isStreaming` | `YES` when streaming from a file |
| `nameUTF8String` | `assign` | User-assigned name (`char *`) |
| `pathUTF8String` | `assign, readonly` | File path if loaded from file |
| `sampleRate` | `assign, readonly` | `mulle_relativetime_t` sample rate |
| `volume` | `dynamic, assign` | 0.0 to 1.0+ |
| `gainDB` | `dynamic, assign` | Volume in decibel scale |
| `balance` | `dynamic, assign` | Stereo balance -1.0 to 1.0 |
| `pan` | `dynamic, assign` | Pan -1.0 to 1.0 (use pan OR balance, not both) |
| `pitch` | `dynamic, assign` | Playback pitch |
| `seek` | `dynamic, assign` | Position in `mulle_relativetime_t` |
| `loop` | `dynamic, assign, getter=isLooping` | Loop playback |
| `velocityVector` | `dynamic, assign` | 3D velocity (`ma_vec3f`) |
| `positionVector` | `dynamic, assign` | 3D position (`ma_vec3f`) |
| `spatializationEnabled` | `dynamic, assign, getter=isSpatializationEnabled` | Enable 3D spatial audio |

**Initializers:**
```objc
- (instancetype) initWithStreamingContentsOfFileUTF8String:(char *) path
                                               audioEngine:(MulleAudioEngine *) audioEngine;
                                // streaming from file via resource manager

- (instancetype) initWithContentsOfFileUTF8String:(char *) soundFilePath
                                      audioEngine:(MulleAudioEngine *) audioEngine;
                                // non-streaming load via resource manager

- (MulleAudioSound *) initWithAudioSound:(MulleAudioSound *) other;
                                // copy an existing sound

- (instancetype) initWithMiniAudioSound:(ma_sound *) sound
                            audioEngine:(MulleAudioEngine *) audioEngine
                         pathUTF8String:(char *) path
                            isStreaming:(BOOL) isStreaming;
                                // designated: wrap an existing ma_sound

- (instancetype) initWithContentsOfFileUTF8String:(char *) soundFilePath
                                      audioEngine:(MulleAudioEngine *) audioEngine
                                   miniAudioFlags:(NSUInteger) flags;
                                // load with custom miniaudio flags

- (instancetype) initWithAudioDataSource:(MulleAudioDataSource *) dataSource
                             audioEngine:(MulleAudioEngine *) audioEngine;
                                // create from a MulleAudioDataSource

+ (instancetype) soundWithAudioDataSource:(MulleAudioDataSource *) dataSource
                             audioEngine:(MulleAudioEngine *) audioEngine;
                                // factory: create from a data source

+ (instancetype) soundWithAudioSound:(MulleAudioSound *) sound;
                                // factory: copy an existing sound
```

**Playback:**
```objc
- (BOOL) start;           // start playback, returns success
- (void) stop;            // stop playback
- (BOOL) isPlaying;       // currently playing?
- (mulle_relativetime_t) duration;   // total duration in relativetime

- (void) fadeOut:(mulle_relativetime_t) time;
- (void) setFadeIn:(mulle_relativetime_t) time
       startVolume:(float) startVolume
         endVolume:(float) endVolume;

- (void) setStartTime:(mulle_absolutetime_t) startTime;
- (void) setStopTime:(mulle_absolutetime_t) stopTime;
```

**Testing aid:**
```objc
- (void) waitForCompletion;  // busy-wait for completion (test use only)
```

**Low-level access:**
```objc
- (ma_sound *) miniAudioSound;
- (BOOL) isResourceManaged;  // tentative, may be removed
```

---

### 3.6. `[MulleAudioDevice.h]` — Audio device wrapper

```objc
@interface MulleAudioDevice : NSObject < MulleObjCThreadSafe>
```
Wraps a `ma_device` for playback or capture. Conforms to
`<MulleObjCThreadSafe>`. Usually created implicitly by the engine; direct
use is rare.

**Properties:**
| Property | Type | Notes |
|---|---|---|
| `audioContext` | `assign, readonly` | Owning context |
| `audioEngine` | `assign` | Do not set manually; engine sets this |

**Lifecycle:**
```objc
+ (instancetype) deviceWithMiniAudioDevice:(ma_device *) device
                             audioContext:(MulleAudioContext *) audioContext;
                  // factory that wraps an existing ma_device

- (id) initWithMiniAudioDeviceConfig:(ma_device_config *) config
                        audioContext:(MulleAudioContext *) audioContext;
                  // creates a new ma_device from config

- (instancetype) initWithMiniAudioDevice:(ma_device *) device
                            audioContext:(MulleAudioContext *) audioContext;
                  // wraps an existing ma_device
```

**Operations:**
```objc
- (ma_device *) miniAudioDevice;
- (BOOL) isRunning;
- (BOOL) start;
- (void) stop;
- (BOOL) ownsMiniAudioDevice;

- (char *) UTF8String;          // device description
- (char *) statusUTF8String;    // device status string
```

---

### 3.7. `[MulleAudioDataSource.h]` — Raw audio data or decoder source

```objc
@interface MulleAudioDataSource : NSObject < MulleObjCThreadSafe>
```
Wraps either a `ma_decoder` (for compressed/format-encoded data) or a
`ma_audio_buffer` (for raw PCM data). Used as input to
`-[MulleAudioSound initWithAudioDataSource:audioEngine:]`.

**Initializer:**
```objc
+ (instancetype) dataSourceWithBytes:(void *) bytes
                              length:(NSUInteger) length
                     miniAudioFormat:(ma_format) format
                    numberOfChannels:(NSInteger) numberOfChannels
                 miniAudioSampleRate:(ma_standard_sample_rate) sampleRate;
                                // factory: create from raw bytes

- (instancetype) initWithBytes:(void *) bytes
                        length:(NSUInteger) length
               miniAudioFormat:(ma_format) format
              numberOfChannels:(NSInteger) numberOfChannels
           miniAudioSampleRate:(ma_standard_sample_rate) sampleRate;
```
- Use `ma_format_unknown` to let miniaudio guess (e.g. embedded WAV).
- For raw PCM, specify format (e.g. `ma_format_f32`), channels, and sample rate.
- For embedded WAV, use `ma_encoding_format_wav` as format with channels=0,
  sampleRate=0.

**Low-level access:**
```objc
- (ma_decoder *) miniAudioDecoder;
- (ma_audio_buffer *) miniAudioBuffer;
- (ma_data_source *) miniAudioDataSource;   // returns either decoder or buffer
```

---

#### Version macro

```objc
#define MULLE_AUDIO_VERSION  ((0UL << 20) | (1 << 8) | 0)
```
Current version: 0.1.0. Encoded as `(major << 20) | (minor << 8) | patch`.

## 4. Performance Characteristics

- **Sound loading:** File-based sounds are loaded through miniaudio's
  resource manager which handles decoding and caching. Streaming sounds
  avoid loading the entire file into memory at the cost of disk I/O during
  playback.
- **Voice management:** Voice slot assignment is O(n) where n is the number
  of voice slots (typically ≤ 24). `VoiceAny` scans forward from
  `_currentForegroundIndex`.
- **Playback mixing:** handled entirely by `ma_engine` (miniaudio), which
  does software mixing on its internal thread. All ObjC wrappers delegate
  directly to `ma_sound` functions.
- **Thread-safety:** `MulleAudio` serializes access to voice arrays via
  `MulleAutolockingObjectProtocols`. `MulleAudioSound`, `MulleAudioEngine`,
  `MulleAudioDevice`, and `MulleAudioDataSource` are declared thread-safe
  and rely on miniaudio's internal locking.
- **Memory:** Voice struct arrays are malloc'd, sized by `numberOfForeground`
  / `numberOfBackgroundVoices`. Each voice stores only a pointer to its
  sound plus three floats.
- **Recording:** Writes uncompressed WAV via `ma_encoder` with minimal
  overhead.

## 5. AI Usage Recommendations & Patterns

- **Always finalize the context on app exit:** The miniaudio thread will
  block process termination unless `-mullePerformFinalize` is called on the
  context before exit. See README example.
- **Set voice counts before first play:** `numberOfForegroundVoices` and
  `numberOfBackgroundVoices` are only read during lazy initialization.
- **Foreground voices cannot stream:** Passing `MulleAudioVoiceOptionBackgroundVoice`
  is required for streaming sounds. Use `| MulleAudioVoiceOptionIsLooping`
  for looping.
- **Use `[MulleAudio instance]` (not `alloc/init`):** MulleAudio extends
  `MulleObject` and uses its singleton pattern.
- **Use `[MulleAudioContext instance]` (not `alloc/init`):** Context
  conforms to long-standing conventions.
- **Prefer factory methods over `alloc/init/autorelease`:** Use
  `engineWithMiniAudioEngineConfig:`, `deviceWithMiniAudioDevice:`,
  `dataSourceWithBytes:`, `soundWithAudioDataSource:`,
  `audioSoundByCopyingAudioSound:` and the other `*With*:` factories when
  available. The `alloc/init/autorelease` initializers also exist and work
  for Engine, Device, Sound, DataSource (none of them are singletons).
- **Prefer `audioVoiceWithContentsOfFileUTF8String:` etc. on `MulleAudio`
  for simple play-and-forget.** For fine-grained control (seek, spatial
  audio, fades), obtain the `MulleAudioSound` via `audioSoundOfVoice:` or
  create one directly from an engine.
- **`playVoice:duration:`** plays a voice for a fixed duration then
  automatically stops it (convenient for one-shot effects with known length).
- **Low-level escape hatch:** Every wrapper object exposes `-miniAudio*`
  accessors for direct miniaudio C API use.
- **Do not use `balance` and `pan` simultaneously** on the same sound;
  they control the same underlying stereo pan parameter.
- **Recording writes WAV only.** The format is fixed; use `-miniAudioEngine`
  to access the raw `ma_engine` for custom processing.

## 6. Integration Examples

### Example 1: Quick one-shot sound effect with MulleAudio

```objc
#import <MulleAudio/MulleAudio.h>

int   main( int argc, char *argv[])
{
   MulleAudio            *audio;
   MulleAudioVoiceHandle voice;

   audio = [MulleAudio instance];
   [audio setNumberOfForegroundVoices:8];
   [audio setNumberOfBackgroundVoices:2];

   voice = [audio audioVoiceWithContentsOfFileUTF8String:argv[ 1]
                                                 options:MulleAudioVoiceOptionVoiceAny];

   [audio playVoice:voice];
   [audio waitForCompletionOfVoice:voice];

   [[audio audioContext] mullePerformFinalize];
   return( 0);
}
```

### Example 2: Low-level sound creation with custom DataSource

```objc
#import <MulleAudio/MulleAudio.h>

int   main( int argc, char *argv[])
{
   MulleAudioContext      *audioContext;
   MulleAudioDevice       *audioDevice;
   MulleAudioEngine       *audioEngine;
   MulleAudioDataSource   *audioDataSource;
   MulleAudioSound        *audioSound;
   ma_device_config       device_config;
   static int16_t         pcm_samples[ 256][ 2];  // 16-bit stereo silence

   audioContext = [MulleAudioContext instance];
   if( ! [audioContext getDefaultMiniAudioPlaybackDeviceConfig:&device_config])
      return( 1);

   audioDevice     = [audioContext audioDeviceWithMiniAudioDeviceConfig:&device_config];
   audioEngine     = [MulleAudioEngine engineWithMiniAudioEngineConfig:NULL
                                                          audioContext:audioContext
                                                           audioDevice:audioDevice];

   audioDataSource = [MulleAudioDataSource dataSourceWithBytes:pcm_samples
                                                        length:sizeof( pcm_samples)
                                               miniAudioFormat:ma_format_s16
                                              numberOfChannels:2
                                           miniAudioSampleRate:ma_standard_sample_rate_48000];

   audioSound      = [MulleAudioSound soundWithAudioDataSource:audioDataSource
                                                    audioEngine:audioEngine];

   [audioSound setFadeIn:0.5  startVolume:0.0  endVolume:1.0];
   [audioSound setLoop:YES];
   [audioSound start];
   [audioSound waitForCompletion];

   [audioContext mullePerformFinalize];
   return( 0);
}
```

### Example 3: Looping background music with streaming

```objc
#import <MulleAudio/MulleAudio.h>

int   main( int argc, char *argv[])
{
   MulleAudio            *audio;
   MulleAudioVoiceHandle voice;

   audio = [MulleAudio instance];
   [audio setNumberOfBackgroundVoices:1];

   voice = [audio audioVoiceWithContentsOfFileUTF8String:argv[ 1]
                                                 options:MulleAudioVoiceOptionVoice0
                                                       | MulleAudioVoiceOptionBackgroundVoice
                                                       | MulleAudioVoiceOptionIsLooping];

   [audio playVoice:voice];
   [audio waitForCompletionOfVoice:voice];

   [[audio audioContext] mullePerformFinalize];
   return( 0);
}
```

### Example 4: Recording engine output to WAV

```objc
#import <MulleAudio/MulleAudio.h>

int   main( int argc, char *argv[])
{
   MulleAudioContext   *context;
   MulleAudioEngine    *engine;
   MulleAudioSound     *sound;

   context = [MulleAudioContext instance];
   engine  = [context defaultAudioEngine];
   sound   = [engine audioSoundWithContentsOfFileUTF8String:argv[ 1]];

   [engine startRecordingToFileUTF8String:argv[ 2]];
   [sound start];
   [sound waitForCompletion];
   [engine stopRecording];

   [context mullePerformFinalize];
   return( 0);
}
```

### Example 5: Device enumeration

```objc
MulleAudioContext                  *context;
MulleAudioDeviceInfoEnumerator     *iter;
ma_device_info                     *info;

context = [MulleAudioContext instance];
iter    = [context enumerateMiniAudioPlaybackDeviceInfos];
while( info = [iter nextMiniAudioDeviceInfo])
   mulle_fprintf( stderr, "Device: %s (default: %d)\n",
                  info->name, info->isDefault);
```

## 7. Dependencies

- **MulleObjC** — ObjC runtime, root classes, threading, autorelease
- **mulle-objc-list** — list runtime information (build-time only, no-link)
- **asound** — ALSA library (Linux only; `no-build,no-link`, used at runtime
  by miniaudio)
- **src/miniaudio.h** — bundled miniaudio v0.11.25 single-header library
  (fetched as a file dependency)

The full transitive dependency chain (via MulleObjC) includes `mulle-objc-runtime`,
`mulle-c11`, `mulle-allocator`, `mulle-atexit`, `mulle-atinit`, `mulle-container`,
`mulle-thread`, and others — see the `mulle-sde api list` output.
