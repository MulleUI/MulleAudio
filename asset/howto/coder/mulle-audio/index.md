<!-- keywords: mulle-audio, miniaudio, voices, engine, sound, datasource -->
# mulle-audio

Use this bundle when you are changing playback code in this repository. The local split is: high-level pooled playback with `MulleAudio`, explicit `MulleAudioContext`/`MulleAudioEngine`/`MulleAudioDevice` setup, and low-level `MulleAudioSound`/`MulleAudioDataSource` work for streaming, embedded bytes, and copying sounds.

## Understand first

```bash
mulle-sde code map
mulle-sde code search MulleAudio
mulle-sde code search MulleAudioContext
mulle-sde code search MulleAudioSound
mulle-sde code grep "audioVoiceWithContentsOfFileUTF8String"
mulle-sde code grep "initWithAudioDataSource"
```

## Main local surfaces

| Scenario | Prefer | Main refs |
| --- | --- | --- |
| Simple soundboard playback, pooled effects, quick volume/pan/pitch changes | `MulleAudio` voice handles | `src/MulleAudio.h`, `demo/src/main-play-voice.m`, `demo/src/main-play-voice-embedded-wave.m` |
| Explicit engine/device selection, custom context settings, playback device enumeration | `MulleAudioContext`, `MulleAudioEngine`, `MulleAudioDevice` | `src/MulleAudioContext.h`, `src/MulleAudioDevice.h`, `src/MulleAudioEngine.h`, `demo/src/main-enumerate-devices.m`, `test/10-first/device-noleak.m` |
| Direct sound control, streaming, embedded PCM/file bytes, sound cloning | `MulleAudioSound`, `MulleAudioDataSource` | `src/MulleAudioSound.h`, `src/MulleAudioDataSource.h`, `demo/src/main-play-sound.m`, `demo/src/main-play-voice-embedded-samples.m`, `test/20-copy/sound-mutablecopy-leak.m` |
| Engine-output recording to WAV, debug capture | `MulleAudioEngine+Recording` | `src/MulleAudioEngine+Recording.h`, `demo/src/main-record-output.m` |
| Sound completion callbacks, delegate protocol | `MulleAudioSoundDelegate` | `src/MulleAudioSound.h` (protocol declaration), `demo/src/main-play-sound.m` |

## Local references

- `README.md`
- `asset/dox/TOC.md`
- `src/MulleAudio.h`
- `src/MulleAudioContext.h`
- `src/MulleAudioDevice.h`
- `src/MulleAudioEngine.h`
- `src/MulleAudioSound.h`
- `src/MulleAudioDataSource.h`
- `demo/src/main-play-sound.m`
- `demo/src/main-play-voice.m`
- `demo/src/main-enumerate-devices.m`
- `demo/src/main-play-voice-embedded-samples.m`
- `demo/src/main-play-voice-embedded-wave.m`
- `demo/src/main-play-sine.m`
- `demo/src/main-demo-chiptune.m`
- `demo/src/main-record-output.m`
- `demo/src/main-decode-memory.m`
- `src/MulleAudioEngine+Recording.h`
- `test/10-first/context-noleak.m`
- `test/10-first/device-noleak.m`
- `test/10-first/engine-noleak.m`
- `test/10-first/sound-noleak.m`
- `test/10-first/voice-noleak.m`
- `test/10-first/datasource-noleak.m`
- `test/20-copy/sound-mutablecopy-leak.m`

## Local workflow

Start at the highest layer that fits:

1. Use `MulleAudio` when fixed voice pools are enough. Configure the engine and foreground/background voice counts before the first voice is created.
2. Drop to `MulleAudioContext` + `MulleAudioEngine` when you need device choice, custom playback format, or explicit ownership.
3. Drop to `MulleAudioSound` + `MulleAudioDataSource` when you need streaming, scheduled start/stop, embedded bytes, copying an existing sound, or direct miniaudio access through `miniAudio*`.

Local lifetime matters more than in the shared howtos: this repo expects explicit finalization of the audio stack on pedantic exit so miniaudio threads and owned sounds/devices unwind cleanly. The demos call `[context mullePerformFinalize]` or `[audio mullePerformFinalize]` for that reason.

## Verify/report

Use the existing tests that match the surface you touched:

```bash
mulle-sde test craft
mulle-sde test run test/10-first/decode-memory.m
mulle-sde test run test/10-first/device-noleak.m
mulle-sde test run test/10-first/engine-noleak.m
mulle-sde test run test/20-copy/sound-mutablecopy-leak.m
```

If you changed the high-level voice path, also sanity-check the demos under `demo/src/`, especially `main-play-voice.m` and the embedded-data variants.
