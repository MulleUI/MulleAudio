<!-- keywords: debugger, mulle-audio, patterns, repro, voices, device, decode -->
# patterns

## Bisect `MulleAudio` against explicit engine/sound setup

If `demo/src/main-play-voice.m` fails but `demo/src/main-play-sound.m` works with the same asset, stay in `src/MulleAudio.m`. That usually means voice-slot handling, not decode or device startup.

```objc
audio = [MulleAudio instance];
voice = [audio audioVoiceWithContentsOfFileUTF8String:filename
                                              options:MulleAudioVoiceOptionVoiceAny];
if( voice == MulleAudioVoiceOptionNoVoice)
   mulle_fprintf( stderr, "voice failed: %d\n", errno);
```

## Treat `MulleAudioVoiceOptionNoVoice` as a routing signal

The voice demos already split the common failure classes:

```objc
if( voice == MulleAudioVoiceOptionNoVoice)
{
   switch( errno)
   {
   case ENODEV : /* no slot or no device */
   case EBUSY  : /* desired slot still active */
   default     : /* load/decode/backend failure */
   }
}
```

Use the demo shape from `demo/src/main-play-voice.m` and `demo/src/main-play-voice-embedded-wave.m` before adding new logging.

## Reproduce backend/device issues with the explicit stack

Use the tested `context -> device -> engine` shape when you need to separate device creation from sound playback:

```objc
ma_device_config   config;
MulleAudioDevice   *device;
MulleAudioEngine   *engine;

context = [MulleAudioContext instance];
if( [context getDefaultMiniAudioPlaybackDeviceConfig:&config])
{
   device = [context audioDeviceWithMiniAudioDeviceConfig:&config];
   engine = [[[MulleAudioEngine alloc] initWithMiniAudioEngineConfig:NULL
                                                        audioContext:context
                                                         audioDevice:device] autorelease];
}
```

That is the local debug baseline in `test/10-first/device-noleak.m` and `test/10-first/engine-noleak.m`. If this path fails, do not keep chasing voice-pool bugs.

## Split encoded-memory failures from raw-PCM failures

This repo has separate reproducers for both in-memory modes:

- `demo/src/main-play-voice-embedded-wave.m` and `test/10-first/decode-memory.m` cover encoded file bytes.
- `demo/src/main-play-voice-embedded-samples.m` and `test/10-first/datasource-noleak.m` cover raw PCM bytes.

```objc
voice = [audio audioVoiceWithFileCData:mulle_data_make( foreseen, s_foreseen)
                               options:MulleAudioVoiceOptionVoiceAny];
```

```objc
audioDataSource = [[[MulleAudioDataSource alloc] initWithBytes:silence_samples
                                                        length:sizeof( silence_samples)
                                               miniAudioFormat:ma_format_s16
                                              numberOfChannels:2
                                           miniAudioSampleRate:ma_standard_sample_rate_48000] autorelease];
```

If encoded-memory works and PCM does not, stay in format/channel/sample-rate handling instead of the decoder path.

## Use slot reuse to confirm replace-vs-mix behavior

`demo/src/main-play-voice.m` intentionally reloads the same handle:

```objc
voice = [audio audioVoiceWithContentsOfFileUTF8String:filename
                                              options:voice];
```

Use that pattern when debugging "double playback" or "echo" reports. In this repo, reusing a handle replaces the sound in that slot.

## Use the copy test for lifetime regressions

When a bug appears only after cloning or reusing a sound, use the existing copy path instead of inventing a new harness:

```objc
audioSoundCopy = [[[MulleAudioSound alloc] initWithAudioSound:audioSound] autorelease];
```

`test/20-copy/sound-mutablecopy-leak.m` is the local reproducer for sound-copy ownership and retained-source behavior.

## Finalize explicitly when debugging loops or exit hangs

The looping embedded-sample demo never completes on its own:

```objc
[audio setLoop:YES
       ofVoice:voice];
[audio playVoice:voice];
[audio mullePerformFinalize];
```

Use the same shutdown shape from `demo/src/main-play-voice-embedded-samples.m` and `demo/src/main-play-sound.m` when the symptom is "hangs on exit" instead of "no audio".
