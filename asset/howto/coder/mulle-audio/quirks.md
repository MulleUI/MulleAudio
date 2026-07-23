<!-- keywords: mulle-audio, quirks, lifecycle, voices, threading, pitfalls -->
# quirks

## `MulleAudio` voice pool rules

- Set `audioEngine`, `numberOfForegroundVoices`, and `numberOfBackgroundVoices` before the first voice is created. `src/MulleAudio.m` throws internal inconsistency exceptions if you try to change a running system.
- Foreground voices must not receive streaming sounds. `src/MulleAudio.m` explicitly throws if `[audioSound isStreaming]` is true and the background flag is not set.
- Voice handles are slots. Reusing a slot replaces the retained `MulleAudioSound` in that slot; it is not additive playback.
- `pauseVoice:` is really a stop without seek reset. `stopVoice:` stops and also resets seek to zero.
- `waitForCompletionOfVoice:` is a busy wait used by demos/tests. Do not use it for looping voices unless you are also finalizing the audio stack.

## Current option wiring is incomplete

- `MulleAudioVoiceOptionIsLooping` is declared in `src/MulleAudio.h` but is not consumed in `src/MulleAudio.m`. Set looping explicitly with `setLoop:ofVoice:`.
- `MulleAudioVoiceOptionSkipIfFull` is declared in `src/MulleAudio.h`, but the current check in `src/MulleAudio.m` masks it away. Do not rely on it to preserve a full voice pool; expect occupied slots to be finalized and replaced.

## Context / engine / device lifetime

- Treat `MulleAudioContext` as app-global. `src/MulleAudioContext.h` and `asset/dox/TOC.md` both frame it as the single miniaudio context/resource-manager owner.
- `MulleAudioContext` lazily creates the resource manager using `playbackSampleType`, `playbackChannels`, and `playbackSampleRateHZ`. Set those before the first engine/sound path that touches the resource manager.
- Finalization cascades downward here: context finalizes engines, engine finalizes sounds and its device, and the high-level `MulleAudio` finalizes its context.
- A standalone `MulleAudioDevice` can be started with `[device start]`, but once an engine owns the device, `MulleAudioDevice`'s `start`/`stop` paths assert that no engine is attached.

## Enumerator behavior is uneven by design

- `MulleAudioDeviceInfoEnumerator` is not an `NSEnumerator` and does not support fast enumeration. Use `nextMiniAudioDeviceInfo`.
- `MulleAudioEngineEnumerator` does implement `nextObject`, and `MulleAudioContext` itself supports fast enumeration over engines.

## `MulleAudioSound` threading and callback rules

- `audioSoundDidStop:` runs from the miniaudio playback thread. `src/MulleAudioSound.m` explicitly creates/attaches a Mulle thread first, so delegate code still needs to be thread-safe.
- `src/MulleAudioSound.h` notes that the delegate property should only be changed while the sound is not playing.
- `setBalance:` and `setPan:` select different miniaudio pan modes. Use one model consistently instead of mixing both on the same sound.
- `seek`, `duration`, fade, start time, and stop time all use `mulle_relativetime_t` / `mulle_absolutetime_t`, not raw milliseconds in the Objective-C surface.

## In-memory audio input has two modes

- For `MulleAudioDataSource`, `ma_format_unknown` means decoder mode for encoded file bytes; any concrete format means raw PCM buffer mode.
- **Neither mode copies the bytes.** `ma_audio_buffer_init` (PCM) stores the pointer with `ownsData = MA_FALSE`; `ma_decoder_init_memory` (encoded) reads from the pointer on demand. The caller must keep the buffer alive for the lifetime of the voice/sound.
- `MulleAudio audioVoiceWithBytes:... sampleRateHz:` asserts a standard miniaudio sample rate in `src/MulleAudio.m`. Stick to the standard enum values used there.
- Embedded looping samples in `demo/src/main-play-voice-embedded-samples.m` never finish on their own; the demo exits with `[audio mullePerformFinalize]` instead of waiting for completion.

## Recording is single-session, engine-owned, and f32-only

- `MulleAudioEngine+Recording` installs a raw C callback (`engine->onProcess`) that writes `ma_format_f32` frames to a WAV encoder. The format is always `ma_format_f32` regardless of the engine's internal format.
- Only one recording at a time. Calling `startRecordingToFileUTF8String:` while `isRecording` returns `YES` returns `NO` (`src/MulleAudioEngine+Recording.m`).
- The recording tap allocates a `struct MulleAudioRecordingTap` with `mulle_allocator_calloc` and frees it on `stopRecording`. The engine finalizer calls `[self stopRecording]` during teardown (`src/MulleAudioEngine.m`).
- `demo/src/main-record-output.m` shows the canonical start-before-playback pattern. Starting the recording after sounds already play may miss initial frames.

## `MulleAudioSoundDelegate` fires on the audio thread

- `audioSoundDidStop:` is invoked from the miniaudio playback thread after `MulleThreadGetOrCreateCurrentThread()`. The delegate must be thread-safe.
- `didStop` property flips to `YES` *after* the delegate callback returns (`src/MulleAudioSound.m`).
- The delegate property in `src/MulleAudioSound.h` is marked `MULLE_OBJC_THREADSAFE_PROPERTY` but the header comment warns: only change the delegate while `[sound isPlaying] == NO`.

## `MulleAudioSound` exposes miniaudio spatial properties without a convenience wrapper

- `sound.velocityVector`, `sound.positionVector`, and `sound.spatializationEnabled` pass through to the underlying `ma_sound` fields directly. There is no high-level "set listener position" on `MulleAudioContext` or `MulleAudioEngine` — the miniaudio engine manages the listener internally.
- Spatial audio is not covered in any demo or test. The properties exist because `ma_sound` exposes them. For any serious spatial work, use `[sound miniAudioSound]` and program the `ma_engine` listener directly through the miniaudio C API. Refer to miniaudio docs for the listener model.

## `MulleAudio setBalance:ofVoice:` uses `setPan:` internally

In `src/MulleAudio.m:517`, `setBalance:ofVoice:` calls `[audioSound setPan:balance]`, which selects `ma_pan_mode_pan` instead of `ma_pan_mode_balance`. The two pan modes differ in how miniaudio distributes energy:
- `MulleAudioSound.setBalance:` → `ma_pan_mode_balance` (constant-power, for stereo positioning)
- `MulleAudio.setBalance:ofVoice:` → `ma_pan_mode_pan` (simple left/right attenuation)

If you need consistent balance behavior, set it directly on the `MulleAudioSound` retrieved via `[audio audioSoundOfVoice:voice]`.

## The inline `mulle_audio_pitch_to_transpose_frequency` helper exists

Declared in `src/MulleAudio.h:197-204`, this C inline computes a pitch factor when source and target sample rates differ:

```c
float factor = mulle_audio_pitch_to_transpose_frequency(
                  rec_frq, rec_samplerate,
                  out_frq, out_samplerate);
```

This is the formula behind the demos' sample-rate-aware pitch calculations. It is directly usable when building custom oscillator buffers.

## iOS audio session interruptions are handled inside miniaudio

`ma_ios_notification_handler` in `src/miniaudio.h:35585` is a vendored Objective-C class that listens for `AVAudioSessionRouteChangeNotification` and `AVAudioSessionInterruptionNotification` on iOS. It is **not** a public MulleAudio type — it lives inside the vendored `miniaudio.h`. No MulleAudio wrapper exposes it. iOS users do not need to handle interruptions manually; miniaudio's handler already pauses/resumes the device.
