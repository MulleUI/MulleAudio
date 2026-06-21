<!-- keywords: verifier, debugging, audio, device, voice, recording, callback -->
# mulle-audio

Use this bundle when you need to verify or debug application code that uses MulleAudio. This repo does **not** expose library-specific `MULLE_AUDIO_*` or `MULLE_*TRACE` knobs in its public headers, demos, or tests; the local verifier surfaces are device enumeration/status, `MulleAudioVoiceOptionNoVoice` plus `errno`, engine-output recording, and sound completion/finalization behavior.

## Understand first

```bash
mulle-sde code map
mulle-sde code search statusUTF8String
mulle-sde code search startRecordingToFileUTF8String
mulle-sde code grep "MulleAudioVoiceOptionNoVoice"
mulle-sde code grep "mullePerformFinalize"
```

## Main local surfaces

| Symptom | Check first | Main refs |
| --- | --- | --- |
| No sound, wrong backend, wrong playback/capture target | `MulleAudioContext`, `MulleAudioDeviceInfoEnumerator`, `MulleAudioDevice statusUTF8String` | `src/MulleAudioContext.h`, `src/MulleAudioDevice.h`, `demo/src/main-enumerate-devices.m`, `test/10-first/device-noleak.m`, `test/10-first/engine-noleak.m` |
| `MulleAudioVoiceOptionNoVoice`, slot reuse surprises, "pause" vs "stop" confusion | `MulleAudio` voice handles and `errno` | `src/MulleAudio.h`, `src/MulleAudio.m`, `demo/src/main-play-voice.m`, `demo/src/main-play-voice-embedded-wave.m`, `demo/src/main-play-voice-embedded-samples.m` |
| Memory/file decode works differently, PCM sounds wrong but does not hard-fail | `MulleAudioSound`, `MulleAudioDataSource` | `src/MulleAudioSound.h`, `src/MulleAudioDataSource.h`, `demo/src/main-decode-memory.m`, `test/10-first/decode-memory.m`, `test/10-first/datasource-noleak.m` |
| Need objective proof that audio reached the mixer | `MulleAudioEngine (Recording)` | `src/MulleAudioEngine+Recording.h`, `demo/src/main-record-output.m` |
| Completion callbacks, exit hangs, looping sounds never finish | `MulleAudioSoundDelegate`, `didStop`, explicit finalization | `src/MulleAudioSound.h`, `src/MulleAudioSound.m`, `demo/src/main-play-sound.m`, `demo/src/main-play-voice-embedded-samples.m` |

## Local references

- `README.md`
- `asset/dox/TOC.md`
- `src/MulleAudio.h`
- `src/MulleAudioContext.h`
- `src/MulleAudioDevice.h`
- `src/MulleAudioEngine+Recording.h`
- `src/MulleAudioSound.h`
- `src/MulleAudioDataSource.h`
- `demo/src/main-enumerate-devices.m`
- `demo/src/main-play-sound.m`
- `demo/src/main-play-voice.m`
- `demo/src/main-play-voice-embedded-samples.m`
- `demo/src/main-play-voice-embedded-wave.m`
- `demo/src/main-record-output.m`
- `test/10-first/device-noleak.m`
- `test/10-first/engine-noleak.m`
- `test/10-first/decode-memory.m`
- `test/10-first/datasource-noleak.m`

## Local workflow

1. Reproduce on the closest existing demo or focused test before adding instrumentation to your app.
2. For backend/device problems, enumerate playback and capture devices first, then print device state. `demo/src/main-enumerate-devices.m` shows the supported format/sample-rate view; `MulleAudioDevice` also exposes `statusUTF8String` for a quick active/inactive summary.
3. Treat `MulleAudioVoiceOptionNoVoice` as a routing signal, not a final diagnosis. The voice demos branch on `errno`: `ENODEV` means no usable slot/device, `EBUSY` means the requested slot is still occupied, and other errors usually mean load/decode/backend failure.
4. If playback is subjective or platform routing is suspect, record the engine output to WAV with `startRecordingToFileUTF8String:` and `stopRecording` first. `demo/src/main-record-output.m` is the local proof path for "did mixed audio actually reach the engine?"
5. Split in-memory failures by input type. `audioVoiceWithFileCData:` and `test/10-first/decode-memory.m` cover encoded file bytes; `audioVoiceWithBytes:...sampleEncoding...` / `MulleAudioDataSource` cover raw PCM. Wrong channel count or sample rate can sound wrong without looking like a decoder failure.
6. Treat completion and shutdown bugs separately from playback bugs. `waitForCompletion` and `waitForCompletionOfVoice:` are busy waits, looping sounds never finish on their own, and the demos call `[context mullePerformFinalize]` or `[audio mullePerformFinalize]` to unwind miniaudio threads. If you use `audioSoundDidStop:`, remember it runs on the miniaudio playback thread and `didStop` flips after the delegate callback.

## Verify/report

Use the focused comparison programs instead of inventing a new harness:

```bash
mulle-sde test craft
mulle-sde test run test/10-first/device-noleak.m
mulle-sde test run test/10-first/decode-memory.m
mulle-sde test run test/10-first/sound-noleak.m
```

When reporting, name the layer that failed: device/context discovery, voice-slot allocation, encoded-memory vs PCM input, engine-output recording, or shutdown/callback behavior.
