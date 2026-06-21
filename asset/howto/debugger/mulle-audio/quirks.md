<!-- keywords: debugger, mulle-audio, quirks, pitfalls, lifecycle, callbacks -->
# quirks

## `MulleAudio` slot behavior is stricter than the API names suggest

- Set `audioEngine`, `numberOfForegroundVoices`, and `numberOfBackgroundVoices` before the first voice is created. `src/MulleAudio.m` throws internal inconsistency exceptions if you change a running system.
- Foreground slots reject streaming sounds. Use the background-voice path for music or other streaming material.
- Voice handles are slots. Reusing a handle replaces the retained `MulleAudioSound`; it does not layer another player on top.
- `pauseVoice:` just stops the sound. `stopVoice:` stops and also resets seek to zero.
- `setBalance:ofVoice:` currently forwards to `setPan:` in `src/MulleAudio.m`, so high-level "balance" debugging is really pan-mode debugging here.
- `MulleAudioVoiceOptionIsLooping` is declared in `src/MulleAudio.h` but not consumed in `src/MulleAudio.m`. Set looping explicitly with `setLoop:ofVoice:`.
- `MulleAudioVoiceOptionSkipIfFull` is declared, but the current mask check in `src/MulleAudio.m` does not make it a reliable non-destructive full-pool option.
- Foreground voice default seeding currently loops to `_numberOfBackgroundVoices` in `src/MulleAudio.m`. If those counts differ, later foreground slots may keep calloc defaults instead of the configured foreground defaults.

## Shutdown behavior matters during debugging

- `waitForCompletion` and `waitForCompletionOfVoice:` are busy waits. Looping sounds never satisfy them on their own.
- The demos call `[context mullePerformFinalize]` or `[audio mullePerformFinalize]` to unwind miniaudio threads on pedantic exit. Missing that can look like a playback bug when it is really a shutdown bug.
- `audioSoundDidStop:` runs before `_didStop` flips, so delegate work can affect wait-based repros.

## Context / engine / device ownership has sharp edges

- Treat `MulleAudioContext` as app-global. It owns the single miniaudio context and shared resource manager.
- `playbackSampleType`, `playbackChannels`, and `playbackSampleRateHZ` are latched by the first `miniAudioResourceManager` initialization. Set them before the first resource-managed load.
- A standalone `MulleAudioDevice` can be started and stopped directly, but once an engine owns the device those methods assert if you call them.
- `MulleAudioDeviceInfoEnumerator` is not fast enumeration. Use `nextMiniAudioDeviceInfo`; only engine enumeration is object-style.

## Sound callbacks and controls have thread-sensitive behavior

- `audioSoundDidStop:` is invoked from the miniaudio playback thread after `MulleThreadGetOrCreateCurrentThread()`. Delegate code still needs to be thread-safe.
- `src/MulleAudioSound.h` explicitly warns that the delegate should only be changed while the sound is not playing.
- `setBalance:` and `setPan:` choose different miniaudio pan modes. Mixing both on one sound can hide whether the caller changed balance mode or pan mode.
- `seek`, `duration`, fade times, and start/stop scheduling use `mulle_relativetime_t` / `mulle_absolutetime_t`, not raw millisecond integers.

## In-memory audio has two distinct debug paths

- In `MulleAudioDataSource`, `ma_format_unknown` means "decode these bytes as an encoded file".
- Any concrete `ma_format_*` means raw interleaved PCM. Wrong channel count or sample rate will sound wrong without looking like a decode failure.
- **Neither path copies the bytes.** If the buffer is freed or stack-allocated and goes out of scope, playback will read garbage or crash. This is the most common cause of "plays noise" or "crashes mid-playback" for dynamically generated audio.
- `MulleAudio audioVoiceWithBytes:...` asserts that `sampleRateHz` is one of miniaudio's standard sample-rate constants.
- `initWithAudioSound:` copies differently by backing store: streaming sounds reopen the original path, resource-managed non-streaming sounds use `ma_sound_init_copy`, and data-source-backed sounds rebuild from the retained `MulleAudioDataSource`.
