<!-- keywords: mulle-audio, sequencing, notes, melody, chiptune, duration, timing -->
# sequencing

## Voice semantics — the most common mistake

A voice is a **slot**, not a queue. Calling `playVoice:duration:` on a voice
that is already playing **replaces** the current sound immediately. It does not
wait, does not queue, does not layer.

Consequence: if you fire notes in a loop without waiting, only the last note
is audible:

```objc
// WRONG — all notes play on the same voice instantly, only the last is heard
for( i = 0; i < noteCount; i++)
{
   [audio pitchToFrequency:notes[i].freq fromFrequency:BASE_FREQ ofVoice:voice];
   [audio playVoice:voice duration:notes[i].duration];
}
```

## Sequencing pattern: timer-driven note advance

Use a frame-tick timer. Track which note is current and how much time has
elapsed. Only advance to the next note when the current one's duration expires.

```objc
// state per melody channel
MelodyNote   *notes;
NSUInteger    noteCount;
NSUInteger    noteIndex;
CGFloat       noteTimer;     // seconds elapsed in current note
BOOL          playing;
```

```objc
// called every frame with delta time
- (void) tickWithDelta:(CGFloat) dt
{
   if( ! playing)
      return;

   noteTimer += dt;
   if( noteTimer < notes[ noteIndex].duration)
      return;   // current note still sounding — do nothing

   // advance
   noteTimer -= notes[ noteIndex].duration;
   noteIndex++;
   if( noteIndex >= noteCount)
   {
      playing = NO;   // melody finished (or loop: noteIndex = 0)
      return;
   }

   // play next note
   [audio pitchToFrequency:notes[ noteIndex].frequency
             fromFrequency:BASE_FREQ
                   ofVoice:melodyVoice];
   [audio playVoice:melodyVoice duration:notes[ noteIndex].duration];
}
```

Start playback by playing the first note immediately, then let the tick
handle the rest:

```objc
- (void) startMelody
{
   noteIndex = 0;
   noteTimer = 0.0f;
   playing   = YES;

   [audio pitchToFrequency:notes[ 0].frequency
             fromFrequency:BASE_FREQ
                   ofVoice:melodyVoice];
   [audio playVoice:melodyVoice duration:notes[ 0].duration];
}
```

## Duration must match intent

`playVoice:duration:` plays for **exactly** that many seconds, then stops.
Common mistakes:

| Mistake | Result | Fix |
|---------|--------|-----|
| Duration too short (e.g. 0.01s) | Note is inaudible — just a click | Use at least 0.05s for perceptible tones |
| Duration longer than tick interval | Notes overlap into next — sounds fine actually | Only a problem if you need staccato |
| Duration = 0 | Plays indefinitely until `stopVoice:` | Intentional for drones/BGM |

## Separate voices for separate concerns

Don't reuse one voice for both BGM melody and SFX. The SFX will cut off
the melody mid-note. Allocate distinct voices:

```objc
[audio setNumberOfForegroundVoices:4];

bgmVoice    = [audio audioVoiceWithBytes:... options:MulleAudioVoiceOptionVoice0];
sfxVoice    = [audio audioVoiceWithBytes:... options:MulleAudioVoiceOptionVoice1];
dieVoice    = [audio audioVoiceWithBytes:... options:MulleAudioVoiceOptionVoice2];
melodyVoice = [audio audioVoiceWithBytes:... options:MulleAudioVoiceOptionVoice3];
```

## Looping BGM with `setLoop:YES`

For a continuous drone or bass line, set loop and use `pitchToFrequency:` to
change notes without restarting:

```objc
[audio setLoop:YES ofVoice:bgmVoice];
[audio playVoice:bgmVoice];   // starts looping forever

// later, change pitch (no restart, seamless)
[audio pitchToFrequency:newFreq fromFrequency:BASE_FREQ ofVoice:bgmVoice];
```

To stop: `[audio stopVoice:bgmVoice]`.

## Multiple channels playing simultaneously

Each MulleAudio voice is mixed additively by miniaudio. Playing four voices
at once gives you four-part harmony with zero extra code. Just make sure
each channel has its own voice slot.

## Multi-oscillator per channel with separate voices

For richer sounds, split each channel into a tone voice and a noise voice.
`demo/src/main-demo-chiptune.m` runs 4 channels × 2 voices each:

```objc
channels[ 0].toneVoice   = [audio audioVoiceWithBytes:sineBuf ...
                                                options:MulleAudioVoiceOptionVoice0];
channels[ 0].noiseVoice  = [audio audioVoiceWithBytes:pokeyBuf ...
                                                options:MulleAudioVoiceOptionVoice1];
// per tick: play both with the same pitch
[audio pitchToFrequency:hz fromFrequency:BASE_FREQ ofVoice:ch->toneVoice];
[audio playVoice:ch->toneVoice duration:n->duration];
[audio pitchToFrequency:hz fromFrequency:BASE_FREQ ofVoice:ch->noiseVoice];
[audio playVoice:ch->noiseVoice duration:n->duration];
```

Adjust the tone/noise mix with `setVolume:ofVoice:`. The chiptune demo also
shows `MIDI note → Hz` with `440.0f * powf(2.0f, (note - 69.0f) / 12.0f)`.

## No duration means indefinite

`playVoice:` without a duration plays until `stopVoice:` is called. This is
used for looping background music or drones:

```objc
[audio playVoice:bgmVoice];  // indefinite, must be stopped explicitly
```

Use `playVoice:duration:` for timed notes in sequences.
