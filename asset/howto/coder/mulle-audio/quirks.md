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
