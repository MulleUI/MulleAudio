<!-- keywords: debugger, mulle-audio, voices, engine, device, sound, datasource -->
# mulle-audio

Use this bundle when you are debugging playback, device selection, decode failures, or shutdown hangs in this repository. The local split is pooled voice playback with `MulleAudio`, explicit `MulleAudioContext`/`MulleAudioEngine`/`MulleAudioDevice` setup, and low-level `MulleAudioSound`/`MulleAudioDataSource` input and callback behavior.

## Understand first

```bash
mulle-sde code map
mulle-sde code search MulleAudio
mulle-sde code search MulleAudioContext
mulle-sde code search MulleAudioSound
mulle-sde code grep "MulleAudioVoiceOptionNoVoice"
mulle-sde code grep "mullePerformFinalize"
```

## Main local surfaces

| Symptom | Check first | Main refs |
| --- | --- | --- |
| No playback engine, no device, wrong backend/device | `MulleAudioContext`, `MulleAudioDevice`, `MulleAudioEngine` | `src/MulleAudioContext.h`, `src/MulleAudioDevice.h`, `src/MulleAudioEngine.h`, `demo/src/main-enumerate-devices.m`, `test/10-first/device-noleak.m`, `test/10-first/engine-noleak.m` |
| `MulleAudioVoiceOptionNoVoice`, slot reuse surprises, pause/stop confusion | `MulleAudio` voice pool | `src/MulleAudio.h`, `src/MulleAudio.m`, `demo/src/main-play-voice.m`, `demo/src/main-play-voice-embedded-wave.m`, `test/10-first/voice-noleak.m` |
| Embedded file bytes or raw PCM behave differently | `MulleAudioSound`, `MulleAudioDataSource` | `src/MulleAudioSound.h`, `src/MulleAudioDataSource.h`, `demo/src/main-decode-memory.m`, `demo/src/main-play-voice-embedded-samples.m`, `test/10-first/decode-memory.m`, `test/10-first/datasource-noleak.m` |
| Hangs on exit, looping sounds never complete, stop callback/thread issues | `MulleAudioSound` finalization and delegate path | `demo/src/main-play-sound.m`, `demo/src/main-play-voice-embedded-samples.m`, `src/MulleAudioSound.h`, `src/MulleAudioSound.m`, `test/10-first/sound-noleak.m` |

## Local references

- `README.md`
- `asset/dox/TOC.md`
- `src/MulleAudio.h`
- `src/MulleAudioContext.h`
- `src/MulleAudioDevice.h`
- `src/MulleAudioEngine.h`
- `src/MulleAudioSound.h`
- `src/MulleAudioDataSource.h`
- `demo/src/main-enumerate-devices.m`
- `demo/src/main-play-sound.m`
- `demo/src/main-play-voice.m`
- `demo/src/main-play-voice-embedded-samples.m`
- `demo/src/main-play-voice-embedded-wave.m`
- `test/10-first/device-noleak.m`
- `test/10-first/engine-noleak.m`
- `test/10-first/sound-noleak.m`
- `test/10-first/decode-memory.m`
- `test/20-copy/sound-mutablecopy-leak.m`

## Local workflow

1. Reproduce on the smallest matching demo or test first. This repo already splits failures well: device startup, voice allocation, embedded bytes, and sound-copy lifetime all have dedicated examples.
2. If the failure happens before a `MulleAudioSound` exists, stay in `MulleAudioContext`/`MulleAudioDevice`/`MulleAudioEngine` and confirm device enumeration or default device config first.
3. If the failure is `MulleAudioVoiceOptionNoVoice` or wrong sound reuse, stay in `MulleAudio`. Its voice handles are fixed slots, not independent player objects.
4. If file bytes, raw PCM, or copy behavior differs, drop to `MulleAudioSound` and `MulleAudioDataSource`. That is where encoded-memory vs PCM-buffer decisions are made.
5. For shutdown, hang, or looping repros, include explicit `[context mullePerformFinalize]` or `[audio mullePerformFinalize]` before judging the failure. The demos use that to unwind miniaudio threads cleanly.

## Verify/report

Use the existing focused tests instead of writing new repro code:

```bash
mulle-sde test craft
mulle-sde test run test/10-first/device-noleak.m
mulle-sde test run test/10-first/decode-memory.m
mulle-sde test run test/10-first/sound-noleak.m
mulle-sde test run test/20-copy/sound-mutablecopy-leak.m
```

When reporting, say which layer failed: voice pool, context/device/engine, sound/data source, or shutdown/callback.
