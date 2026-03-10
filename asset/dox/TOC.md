# MulleAudio Library Documentation for AI
<!-- Keywords: audio, soundboard, mixing, miniaudio, polyphony -->

## 1. Introduction & Purpose

MulleAudio is an Objective-C audio playback library that enables applications to load and play sounds from files or embedded data. It functions as a soundboard, capable of mixing multiple voices (polyphonic playback) simultaneously. The library provides a high-level Objective-C interface to the [miniaudio](https://miniaud.io/) audio engine, integrating it with the [mulle-objc](https://mulle-objc.github.io) runtime. MulleAudio is conceptually based on [Finch](https://github.com/zoul/Finch) but reimplemented for the mulle-objc ecosystem. It is part of the MulleUI project family and provides essential audio capabilities for UI applications.

## 2. Key Concepts & Design Philosophy

### Hierarchical Architecture

MulleAudio follows a clear ownership and responsibility hierarchy:

```
MulleAudioContext → MulleAudioEngine → MulleAudioDevice
                         ↑
                    MulleAudioSound
```

- **Context**: Manages the global miniaudio context and resource manager (singleton pattern recommended)
- **Engine**: Owns a device and manages sounds (multiple engines can exist per context)
- **Device**: Represents the actual audio hardware or virtual device
- **Sound**: Attached to an engine for playback

### Voice-Based Abstraction

MulleAudio introduces a "voice" abstraction similar to synthesizer voices. Each voice can play one sound at a time, providing polyphony through multiple voices. Voices are divided into:

- **Foreground voices**: For short effects and sounds (default: 8 voices, non-streaming)
- **Background voices**: For ambient sounds and music (default: 2 voices, can stream)

This design simplifies resource management for typical game or UI audio scenarios.

### Two API Levels

1. **High-level `MulleAudio` class**: Voice-based interface for simple soundboard-style playback
2. **Low-level classes**: Direct control through `MulleAudioContext`, `MulleAudioEngine`, and `MulleAudioSound`

### Design Principles

- **Objective-C wrapper over C**: Provides object-oriented interface to miniaudio's C API
- **Thread-safe where appropriate**: Classes marked with `<MulleObjCThreadSafe>` are safe for concurrent access
- **Resource management**: Follows mulle-objc lifecycle (alloc/init, autorelease, finalize)
- **No dot-syntax, no alloc/init patterns**: Adheres to mulle-objc conventions
- **Direct miniaudio access**: `miniAudio*` methods expose underlying structures for advanced usage

## 3. Core API & Data Structures

### 3.1. `MulleAudio.h` (High-Level API)

#### `@interface MulleAudio : MulleObject <MulleAutolockingObjectProtocols>`

The main high-level interface for simple audio playback using voices.

**Purpose:** Provides a soundboard-like interface where sounds are assigned to voices and played with minimal setup.

**Key Properties:**
- `audioEngine`: The audio engine to use (defaults to context's default engine)
- `numberOfForegroundVoices`: Concurrent effect sounds (default: 8)
- `numberOfBackgroundVoices`: Concurrent background sounds (default: 2)
- `defaultForegroundVolume`: Default volume for foreground voices
- `defaultBackgroundVolume`: Default volume for background voices

**Lifecycle:**
- Create via `[MulleAudio instance]` (singleton pattern)
- Configure voice counts before first playback
- Call `[audio mullePerformFinalize]` to cleanly shutdown miniaudio

**Voice Creation:**
- `-audioVoiceWithAudioSound:options:` - Create voice from existing sound
- `-audioVoiceWithContentsOfFileUTF8String:options:` - Load file into voice
- `-audioVoiceWithFileCData:options:` - Use embedded WAV data
- `-audioVoiceWithBytes:length:sampleEncoding:numberOfChannels:sampleRateHz:options:` - Raw sample data

**Playback Control:**
- `-playVoice:` - Start playback
- `-pauseVoice:` - Pause playback
- `-stopVoice:` - Stop playback
- `-isPlayingVoice:` - Check playback state

**Voice Manipulation:**
- `-setVolume:ofVoice:` - Set volume (0.0 to 1.0+)
- `-setBalance:ofVoice:` - Set stereo balance (-1.0 to 1.0)
- `-setPitch:ofVoice:` - Set pitch multiplier
- `-setLoop:ofVoice:` - Enable/disable looping
- `-fadeInVoice:time:` - Fade in over time
- `-fadeOutVoice:time:` - Fade out over time

**Navigation:**
- `-fastForwardVoice:time:` - Skip forward
- `-rewindVoice:time:` - Skip backward

**Utility:**
- `-audioSoundOfVoice:` - Get underlying sound object
- `-waitForCompletionOfVoice:` - Busy-wait for completion (testing only)

#### `typedef NSInteger MulleAudioVoiceHandle`

Opaque handle representing a voice. Returned by voice creation methods.

#### `enum MulleAudioVoiceOptions`

Options for voice creation:
- `MulleAudioVoiceOptionNoVoice` = -1 (error value)
- `MulleAudioVoiceOptionVoice0` through `MulleAudioVoiceOptionVoice23` - Specific voice indices
- `MulleAudioVoiceOptionVoiceAny` - Allocate any available voice
- `MulleAudioVoiceOptionBackgroundVoice` - Use background voice pool
- `MulleAudioVoideOptionSkipIfFull` - Don't wait if no voices available
- `MulleAudioVoiceOptionIsLooping` - Enable looping

#### `struct MulleAudioVoice`

Internal voice structure (public for technical reasons):
- `audioSound` - The sound being played
- `volume` - Current volume
- `pan` - Stereo position
- `pitch` - Pitch multiplier

#### `enum MulleAudioSampleEncoding`

Sample format enumeration:
- `MulleAudioSampleEncodingUnsignedByte` - 8-bit unsigned
- `MulleAudioSampleEncodingSigned16Bit` - 16-bit signed
- `MulleAudioSampleEncodingSigned24Bit` - 24-bit signed
- `MulleAudioSampleEncodingSigned32Bit` - 32-bit signed
- `MulleAudioSampleEncodingFloat` - Floating point

### 3.2. `MulleAudioContext.h`

#### `@interface MulleAudioContext : NSObject <NSFastEnumeration>`

Manages the global miniaudio context and resource manager.

**Purpose:** Root object managing miniaudio initialization and audio engine lifecycle. Should be singleton.

**Key Properties:**
- `playbackSampleRateHZ` - Playback sample rate
- `playbackChannels` - Number of playback channels
- `playbackSampleType` - Sample format type

**Lifecycle:**
- Create via `[MulleAudioContext instance]`
- Access throughout application lifecycle
- Finalizes automatically or via `mullePerformFinalize`

**Engine/Device Creation:**
- `-defaultAudioEngine` - Get/create default engine
- `-audioEngineWithMiniAudioEngineConfig:audioDevice:` - Custom engine
- `-audioDeviceWithMiniAudioDeviceConfig:` - Create device

**Device Enumeration:**
- `-enumerateMiniAudioPlaybackDeviceInfos` - List playback devices
- `-enumerateMiniAudioCaptureDeviceInfos` - List capture devices

**Configuration:**
- `-getDefaultMiniAudioPlaybackDeviceConfig:` - Get playback config
- `-getDefaultMiniAudioCaptureDeviceConfig:` - Get capture config
- `-getDefaultMiniAudioDeviceConfig:miniAudioDeviceType:` - Generic config getter

**Direct miniaudio Access:**
- `-miniAudioContext` - Returns `ma_context*`
- `-miniAudioResourceManager` - Returns `ma_resource_manager*`

**Engine Enumeration:**
- `-enumerateAudioEngines` - Returns enumerator
- Fast enumeration: `for (engine in context)`

#### `@interface MulleAudioDeviceInfoEnumerator : NSObject`

Enumerator for audio device information (not NSEnumerator-based).

**Properties:**
- `audioContext` (readonly, retain) - Owner context

**Lifecycle:**
- Create via context's enumeration methods
- Iterate with `-nextMiniAudioDeviceInfo`

**Methods:**
- `-initPlaybackDeviceEnumeratorWithAudioContext:` - Init for playback
- `-initCaptureDeviceEnumeratorWithAudioContext:` - Init for capture
- `-nextMiniAudioDeviceInfo` - Returns `ma_device_info*` or NULL when done

#### `@interface MulleAudioEngineEnumerator : NSObject`

Enumerator for audio engines.

**Properties:**
- `audioContext` (readonly, retain) - Owner context

**Methods:**
- `-initAudioEngineEnumeratorWithAudioContext:` - Designated initializer
- `-nextObject` - Returns next `MulleAudioEngine` or nil

### 3.3. `MulleAudioEngine.h`

#### `@interface MulleAudioEngine : NSObject <MulleObjCThreadSafe>`

The audio playback engine that manages sounds and interfaces with a device.

**Purpose:** Central playback controller. Owns a device and manages all sounds played through it.

**Key Properties:**
- `audioContext` (readonly, assign) - Parent context
- `audioDevice` (readonly, retain) - The device being used
- `running` (readonly, dynamic) - Whether engine is running

**Lifecycle:**
- `-initWithMiniAudioEngineConfig:audioContext:audioDevice:` - Designated initializer
- `-initWithMiniAudioEngine:audioContext:audioDevice:` - Use existing ma_engine

**Sound Creation:**
- `-audioSoundWithContentsOfFileUTF8String:` - Load sound from file
- `-audioSoundWithBytes:length:miniAudioFormat:numberOfChannels:miniAudioSampleRate:` - Create from raw samples

**Direct miniaudio Access:**
- `-miniAudioEngine` - Returns `ma_engine*`
- `-miniAudioResourceManager` - Returns `ma_resource_manager*`

**Design Notes:**
- Thread-safe for concurrent sound operations
- Maintains internal array of sounds for lifecycle management
- Finalizes all sounds when engine finalizes

### 3.4. `MulleAudioSound.h`

#### `@protocol MulleAudioSoundDelegate`

Delegate protocol for sound events.

**Optional Methods:**
- `-audioSoundDidStop:` - Called when sound stops playing

#### `@interface MulleAudioSound : NSObject <MulleObjCThreadSafe>`

Objective-C wrapper around `ma_sound` with high-level abstractions.

**Purpose:** Represents a playable audio sample with full control over playback parameters.

**Key Properties:**
- `delegate` (assign, atomic) - Delegate for callbacks
- `audioEngine` (assign) - Parent engine
- `didStop` (readonly) - Whether sound has stopped
- `streaming` (readonly) - Whether sound is streaming
- `nameUTF8String` (assign) - Debug name
- `pathUTF8String` (readonly, assign) - File path if loaded from file
- `sampleRate` (readonly) - Sample rate

**Volume/Gain:**
- `volume` (assign, dynamic) - Linear volume (0.0 to 1.0+)
- `gainDB` (assign, dynamic) - Decibel gain

**Stereo Positioning:**
- `balance` (assign, dynamic) - Stereo balance (-1.0 to 1.0)
- `pan` (assign, dynamic) - Stereo pan (-1.0 to 1.0)

**Playback:**
- `pitch` (assign, dynamic) - Pitch multiplier
- `seek` (assign, dynamic) - Current position as `mulle_relativetime_t`
- `loop` (assign, dynamic) - Looping enabled

**3D Audio:**
- `velocityVector` (assign, dynamic) - 3D velocity
- `positionVector` (assign, dynamic) - 3D position
- `spatializationEnabled` (assign, dynamic) - Enable 3D audio

**Lifecycle/Loading:**
- `-initWithStreamingContentsOfFileUTF8String:audioEngine:` - Streaming from file
- `-initWithContentsOfFileUTF8String:audioEngine:` - Non-streaming from file
- `-initWithAudioSound:` - Copy constructor
- `-initWithAudioDataSource:audioEngine:` - From data source
- `-initWithMiniAudioSound:audioEngine:pathUTF8String:isStreaming:` - Designated initializer
- `-initWithContentsOfFileUTF8String:audioEngine:miniAudioFlags:` - Low-level init

**Playback Control:**
- `-start` - Start playback (returns BOOL success)
- `-stop` - Stop playback
- `-fadeOut:` - Fade out over time

**Configuration:**
- `-setStartTime:` - Set start time (write-only)
- `-setStopTime:` - Set stop time (write-only)
- `-setFadeIn:startVolume:endVolume:` - Configure fade-in

**Inspection:**
- `-isPlaying` - Check if playing
- `-duration` - Get duration as `mulle_relativetime_t`
- `-isResourceManaged` - Check if using resource manager

**Direct miniaudio Access:**
- `-miniAudioSound` - Returns `ma_sound*`

**Utility:**
- `-waitForCompletion` - Busy-wait for completion (testing only)

### 3.5. `MulleAudioDevice.h`

#### `@interface MulleAudioDevice : NSObject <MulleObjCThreadSafe>`

Wrapper around `ma_device` representing audio hardware.

**Purpose:** Represents the physical or virtual audio device. Usually created automatically by engine.

**Key Properties:**
- `audioContext` (readonly, assign) - Parent context
- `audioEngine` (assign) - Associated engine (set by engine)

**Lifecycle:**
- `-initWithMiniAudioDeviceConfig:audioContext:` - Create from config
- `-initWithMiniAudioDevice:audioContext:` - Wrap existing device

**Control:**
- `-start` - Start device (returns BOOL)
- `-stop` - Stop device
- `-isRunning` - Check running state

**Inspection:**
- `-UTF8String` - Device name as C string
- `-statusUTF8String` - Status description
- `-ownsMiniAudioDevice` - Check ownership

**Direct miniaudio Access:**
- `-miniAudioDevice` - Returns `ma_device*`

### 3.6. `MulleAudioDataSource.h`

#### `@interface MulleAudioDataSource : NSObject <MulleObjCThreadSafe>`

Wrapper for miniaudio data sources (decoders and audio buffers).

**Purpose:** Encapsulates audio data that can be decoded or played directly from memory.

**Lifecycle:**
- `-initWithBytes:length:miniAudioFormat:numberOfChannels:miniAudioSampleRate:` - Designated initializer

**Parameters for initialization:**
- Pass `ma_format_unknown` and miniaudio will auto-detect
- For raw samples: specify format (e.g., `ma_format_f32`), channels, sample rate
- For embedded WAV: use `ma_encoding_format_wav`, channels=0, sampleRate=0

**Direct miniaudio Access:**
- `-miniAudioDecoder` - Returns `ma_decoder*`
- `-miniAudioBuffer` - Returns `ma_audio_buffer*`
- `-miniAudioDataSource` - Returns `ma_data_source*` (either decoder or buffer)

## 4. Performance Characteristics

### Memory

- **Streaming sounds**: Load incrementally, low memory footprint, suitable for music
- **Non-streaming sounds**: Loaded entirely to memory, fast playback, suitable for effects
- **Resource manager**: Caches loaded sounds, reduces redundant file I/O
- **Voice pools**: Fixed size arrays, O(1) allocation from foreground/background pools

### Playback

- **Sound mixing**: Hardware-accelerated by miniaudio engine
- **Voice allocation**: O(1) for specific voice, O(n) for any-voice (n = pool size)
- **Concurrent playback**: Limited by voice count and hardware capabilities
- **Latency**: Depends on device buffer size and sample rate

### Thread Safety

- **Thread-safe classes**: `MulleAudioEngine`, `MulleAudioSound`, `MulleAudioDevice`, `MulleAudioDataSource`
- **Context**: Safe for concurrent engine creation
- **MulleAudio**: Uses `<MulleAutolockingObjectProtocols>` for thread safety
- **Delegate callbacks**: Called from miniaudio thread (NSThread integration)

### Scalability

- **Foreground voices**: Typically 8-16 sufficient for UI/game effects
- **Background voices**: 1-2 sufficient for ambient audio
- **File I/O**: Resource manager handles caching and threading
- **3D audio**: Additional CPU cost for spatialization calculations

## 5. AI Usage Recommendations & Patterns

### Best Practices

1. **Use singleton pattern for context**: Create `MulleAudioContext` once via `[MulleAudioContext instance]`
2. **Configure voices early**: Set `numberOfForegroundVoices` and `numberOfBackgroundVoices` before first playback
3. **Choose appropriate abstraction level**: Use `MulleAudio` for simple cases, direct sound/engine control for complex scenarios
4. **Streaming vs. non-streaming**: Stream large files (music), load small files (effects) into memory
5. **Resource management**: Use resource manager for repeated sounds (automatically cached)
6. **Clean shutdown**: Call `[context mullePerformFinalize]` or `[audio mullePerformFinalize]` for clean exit
7. **Error handling**: Check return values; voice creation sets `errno` on failure

### Common Pitfalls

1. **Don't modify voice counts after playback starts**: Voice arrays are sized on first access
2. **Don't free returned `ma_*` pointers**: These are borrowed pointers to internal structures
3. **Background voices required for streaming**: Foreground voices cannot stream
4. **Delegate not truly atomic**: Only set delegate when sound is stopped
5. **waitForCompletion is blocking**: Use only in tests or simple scripts, not production UI
6. **Device enumeration is one-time**: Store results or re-enumerate as needed
7. **Finalization order**: Context finalizes engines, engines finalize sounds automatically

### Idiomatic Usage

**Simple playback pattern:**
```objc
MulleAudio  *audio;

audio = [MulleAudio instance];
voice = [audio audioVoiceWithContentsOfFileUTF8String:"sound.wav"
                                              options:MulleAudioVoiceOptionVoiceAny];
[audio playVoice:voice];
```

**Advanced control pattern:**
```objc
MulleAudioContext  *context;
MulleAudioEngine   *engine;
MulleAudioSound    *sound;

context = [MulleAudioContext instance];
engine  = [context defaultAudioEngine];
sound   = [engine audioSoundWithContentsOfFileUTF8String:"music.wav"];
[sound setVolume:0.8];
[sound setLoop:YES];
[sound start];
```

**Resource cleanup:**
```objc
// At application exit
[context mullePerformFinalize];
```

### Error Checking

Check `errno` after voice creation:
- `ENODEV` - No voice available
- `EBUSY` - Requested voice still playing
- Other - File loading or initialization error

## 6. Integration Examples

### Example 1: Simple Sound Effect Playback

```c
// Play a button click sound
int   play_button_click( void)
{
   MulleAudio             *audio;
   MulleAudioVoiceHandle   voice;

   audio = [MulleAudio instance];
   voice = [audio audioVoiceWithContentsOfFileUTF8String:"click.wav"
                                                  options:MulleAudioVoiceOptionVoiceAny];
   if( voice == MulleAudioVoiceOptionNoVoice)
   {
      mulle_fprintf( stderr, "Failed to load sound: %s\n", strerror( errno));
      return( -1);
   }

   [audio setVolume:0.5
            ofVoice:voice];
   [audio playVoice:voice];

   return( 0);
}
```

### Example 2: Background Music with Fade-In

```c
// Start background music with fade-in
MulleAudioVoiceHandle   start_background_music( char *filename)
{
   MulleAudio             *audio;
   MulleAudioVoiceHandle   voice;

   audio = [MulleAudio instance];
   
   // Configure for background playback
   [audio setNumberOfBackgroundVoices:2];

   voice = [audio audioVoiceWithContentsOfFileUTF8String:filename
                                                  options:MulleAudioVoiceOptionBackgroundVoice |
                                                          MulleAudioVoiceOptionIsLooping];
   if( voice == MulleAudioVoiceOptionNoVoice)
      return( voice);

   [audio setVolume:0.0
            ofVoice:voice];
   [audio playVoice:voice];
   [audio fadeInVoice:voice
                 time:2.0];   // 2 second fade-in

   return( voice);
}
```

### Example 3: Advanced Sound Control with Engine

```c
// Load and play with full control
void   play_with_effects( char *filepath)
{
   MulleAudioContext   *context;
   MulleAudioEngine    *engine;
   MulleAudioSound     *sound;

   context = [MulleAudioContext instance];
   engine  = [context defaultAudioEngine];
   if( ! engine)
   {
      mulle_fprintf( stderr, "Could not create audio engine\n");
      return;
   }

   sound = [engine audioSoundWithContentsOfFileUTF8String:filepath];
   if( ! sound)
   {
      mulle_fprintf( stderr, "Could not load \"%s\"\n", filepath);
      return;
   }

   // Configure playback parameters
   [sound setVolume:0.8];
   [sound setBalance:-0.5];   // Slightly to the left
   [sound setPitch:1.2];      // 20% faster/higher
   [sound setFadeIn:1.0
        startVolume:0.0
          endVolume:0.8];

   [sound start];
   [sound waitForCompletion];

   // Clean shutdown
   [context mullePerformFinalize];
}
```

### Example 4: Playing Embedded Audio Data

```c
// Play WAV data embedded in executable
static unsigned char   embedded_sound[] = 
{
   'R', 'I', 'F', 'F',    // RIFF header
   // ... rest of WAV file data ...
};

void   play_embedded_sound( void)
{
   MulleAudio             *audio;
   MulleAudioVoiceHandle   voice;
   struct mulle_data       data;

   audio = [MulleAudio instance];
   data  = mulle_data_make( embedded_sound, sizeof( embedded_sound));
   voice = [audio audioVoiceWithFileCData:data
                                  options:MulleAudioVoiceOptionVoiceAny];

   if( voice != MulleAudioVoiceOptionNoVoice)
      [audio playVoice:voice];
}
```

### Example 5: Enumerating Audio Devices

```c
// List all available audio devices
void   list_audio_devices( void)
{
   MulleAudioContext                *context;
   MulleAudioDeviceInfoEnumerator   *enumerator;
   ma_device_info                   *info;

   context    = [MulleAudioContext instance];
   enumerator = [context enumerateMiniAudioPlaybackDeviceInfos];

   mulle_printf( "Available playback devices:\n");
   while( info = [enumerator nextMiniAudioDeviceInfo])
   {
      mulle_printf( "   %s", info->name);
      if( info->isDefault)
         mulle_printf( " (default)");
      mulle_printf( "\n");
   }
}
```

### Example 6: Using Raw Sample Data

```c
// Create sound from raw 16-bit stereo samples at 48kHz
void   play_raw_samples( int16_t *samples, NSUInteger sample_count)
{
   MulleAudio             *audio;
   MulleAudioVoiceHandle   voice;
   NSUInteger              byte_length;

   audio       = [MulleAudio instance];
   byte_length = sample_count * 2 * sizeof( int16_t);  // stereo * 16-bit

   voice = [audio audioVoiceWithBytes:samples
                               length:byte_length
                       sampleEncoding:MulleAudioSampleEncodingSigned16Bit
                     numberOfChannels:2
                         sampleRateHz:48000
                              options:MulleAudioVoiceOptionVoiceAny];

   if( voice != MulleAudioVoiceOptionNoVoice)
      [audio playVoice:voice];
}
```

### Example 7: Sound Delegate for Completion Notification

```c
// Use delegate to know when sound finishes
@interface MySoundDelegate : NSObject <MulleAudioSoundDelegate>
@end

@implementation MySoundDelegate

- (void) audioSoundDidStop:(MulleAudioSound *) sound
{
   mulle_printf( "Sound '%s' finished playing\n", 
                [sound nameUTF8String]);
}

@end


void   play_with_delegate( void)
{
   MulleAudioContext   *context;
   MulleAudioEngine    *engine;
   MulleAudioSound     *sound;
   MySoundDelegate     *delegate;

   context  = [MulleAudioContext instance];
   engine   = [context defaultAudioEngine];
   sound    = [engine audioSoundWithContentsOfFileUTF8String:"sound.wav"];
   delegate = [MySoundDelegate object];

   [sound setDelegate:delegate];
   [sound start];
}
```

## 7. Dependencies

Direct mulle-sde library dependencies:

- **MulleObjC** - Core Objective-C runtime and foundation classes
- **mulle-objc-list** - Runtime information utilities
- **miniaudio** (embedded) - Cross-platform audio engine (single-header C library)
- **asound** (Linux only) - ALSA library for Linux audio support

MulleAudio sits at the UI layer of the mulle-objc ecosystem, building on the foundation runtime to provide audio playback capabilities.
