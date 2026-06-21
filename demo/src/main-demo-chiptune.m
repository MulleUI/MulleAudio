//
// Demo: MulleChipTune — 4-channel synth playing a short tune.
// Channel 0: Lead (sine + pokey noise)
// Channel 1: Bass (sawtooth)
// Channel 2: Drums (perlin noise hit)
// Channel 3: Arp (triangle + pokey noise)
//
#import "MulleAudio.h"

#include <math.h>
#include <stdlib.h>
#include <string.h>


#define ARP_VOLUME       0.2
#define DRUM_VOLUME      0.4
#define BASS_VOLUME      0.15
#define LEAD_VOLUME      0.25


// ============================================================================
// Constants
// ============================================================================
#define SAMPLE_RATE     48000
#define BASE_FREQ       400        // 48000 / 400 = 120 samples exact
#define BASE_SAMPLES    (SAMPLE_RATE / BASE_FREQ)

#define POKEY_PERIOD    465        // poly5(31) * poly4(15)
#define PERLIN_SAMPLES  256

#define NUM_CHANNELS    4
#define VOICES_PER_CHAN 2          // tone + noise
#define TOTAL_VOICES    (NUM_CHANNELS * VOICES_PER_CHAN)

#define BPM             120
#define BEAT_SEC        (60.0f / BPM)        // 0.5s per beat
#define SIXTEENTH       (BEAT_SEC / 4.0f)    // 0.125s
#define EIGHTH          (BEAT_SEC / 2.0f)    // 0.25s

// ============================================================================
// Waveform buffers
// ============================================================================
static int16_t   s_sineBuf[ BASE_SAMPLES];
static int16_t   s_sawBuf[ BASE_SAMPLES];
static int16_t   s_triBuf[ BASE_SAMPLES];
static int16_t   s_pokeyBuf[ POKEY_PERIOD];
static int16_t   s_perlinBuf[ PERLIN_SAMPLES];


// ============================================================================
// Waveform generation
// ============================================================================
static void   generate_sine( void)
{
   int   i;

   for( i = 0; i < BASE_SAMPLES; i++)
      s_sineBuf[ i] = (int16_t) (sinf( 2.0f * (float) M_PI * (float) i / BASE_SAMPLES) * 30000.0f);
}


static void   generate_saw( void)
{
   int   i;

   for( i = 0; i < BASE_SAMPLES; i++)
      s_sawBuf[ i] = (int16_t) ((2.0f * (float) i / BASE_SAMPLES - 1.0f) * 30000.0f);
}


static void   generate_triangle( void)
{
   int   i;

   for( i = 0; i < BASE_SAMPLES; i++)
   {
      float   t;

      t = (float) i / BASE_SAMPLES;
      if( t < 0.5f)
         s_triBuf[ i] = (int16_t) ((4.0f * t - 1.0f) * 30000.0f);
      else
         s_triBuf[ i] = (int16_t) ((3.0f - 4.0f * t) * 30000.0f);
   }
}


static void   generate_pokey( void)
{
   unsigned int   poly5;
   unsigned int   poly4;
   int            output;
   int            i;

   // poly5: x^5 + x^3 + 1, period 31, XNOR feedback
   poly5  = 0x1F;
   // poly4: x^4 + x^3 + 1, period 15, XNOR feedback
   poly4  = 0x0F;
   output = 1;

   for( i = 0; i < POKEY_PERIOD; i++)
   {
      unsigned int   fb5;

      // clock poly5
      fb5   = ~((poly5 >> 4) ^ (poly5 >> 2)) & 1;
      poly5 = ((poly5 << 1) | fb5) & 0x1F;

      // only clock poly4 when poly5 output bit is 1
      if( poly5 & 1)
      {
         unsigned int   fb4;

         fb4   = ~((poly4 >> 3) ^ (poly4 >> 2)) & 1;
         poly4 = ((poly4 << 1) | fb4) & 0x0F;
         output ^= (poly4 & 1);
      }

      s_pokeyBuf[ i] = output ? (int16_t) 24000 : (int16_t) -24000;
   }
}


static void   generate_perlin( void)
{
   // simple 1D value noise with cosine interpolation
   int     i, j;
   float   gradients[ 9];
   float   freq;

   freq = 8.0f;
   for( i = 0; i <= (int) freq; i++)
      gradients[ i] = ((float)(rand() % 20000) - 10000.0f) / 10000.0f;

   for( i = 0; i < PERLIN_SAMPLES; i++)
   {
      float   t, frac, a, b, val;

      t    = (float) i / PERLIN_SAMPLES * freq;
      j    = (int) t;
      frac = t - (float) j;

      a = gradients[ j];
      b = gradients[ j + 1];
      // cosine interpolation
      val = a + (b - a) * (1.0f - cosf( frac * (float) M_PI)) * 0.5f;

      s_perlinBuf[ i] = (int16_t) (val * 28000.0f);
   }
}


// ============================================================================
// Note / melody helpers
// ============================================================================
static float   midi_to_hz( int note)
{
   return( 440.0f * powf( 2.0f, ((float) note - 69.0f) / 12.0f));
}


typedef struct
{
   int     note;       // MIDI note, 0 = rest
   float   duration;   // seconds
} SeqNote;


// ============================================================================
// 4-bar tune (120 BPM, 4/4 = 8 beats = 4 bars of 2 beats each, 4 seconds)
// ============================================================================

// Lead: melody in C minor pentatonic
static SeqNote   s_lead[] =
{
   { 72, EIGHTH  },  // C5
   { 75, EIGHTH  },  // Eb5
   { 77, EIGHTH  },  // F5
   { 79, EIGHTH  },  // G5
   { 75, EIGHTH  },  // Eb5
   { 72, EIGHTH  },  // C5
   { 70, EIGHTH  },  // Bb4
   { 67, EIGHTH  },  // G4

   { 72, EIGHTH  },  // C5
   { 0,  SIXTEENTH}, // rest
   { 75, SIXTEENTH}, // Eb5
   { 77, EIGHTH  },  // F5
   { 79, BEAT_SEC},  // G5 held

   { 84, EIGHTH  },  // C6
   { 79, EIGHTH  },  // G5
   { 75, EIGHTH  },  // Eb5
   { 72, BEAT_SEC},  // C5 held
};
#define LEAD_COUNT  (sizeof( s_lead) / sizeof( SeqNote))

// Bass: root notes, longer
static SeqNote   s_bass[] =
{
   { 36, BEAT_SEC},  // C2
   { 36, BEAT_SEC},  // C2
   { 41, BEAT_SEC},  // F2
   { 41, BEAT_SEC},  // F2
   { 43, BEAT_SEC},  // G2
   { 43, BEAT_SEC},  // G2
   { 36, BEAT_SEC},  // C2
   { 36, BEAT_SEC},  // C2
};
#define BASS_COUNT  (sizeof( s_bass) / sizeof( SeqNote))

// Drums: noise hits on beat and offbeat
static SeqNote   s_drums[] =
{
   { 40, SIXTEENTH},  // hit
   { 0,  SIXTEENTH},  // rest
   { 0,  SIXTEENTH},  // rest
   { 30, SIXTEENTH},  // softer hit

   { 40, SIXTEENTH},
   { 0,  SIXTEENTH},
   { 30, SIXTEENTH},
   { 0,  SIXTEENTH},

   { 40, SIXTEENTH},
   { 0,  SIXTEENTH},
   { 0,  SIXTEENTH},
   { 30, SIXTEENTH},

   { 40, SIXTEENTH},
   { 0,  SIXTEENTH},
   { 30, SIXTEENTH},
   { 0,  SIXTEENTH},

   { 40, SIXTEENTH},
   { 0,  SIXTEENTH},
   { 0,  SIXTEENTH},
   { 30, SIXTEENTH},

   { 40, SIXTEENTH},
   { 0,  SIXTEENTH},
   { 30, SIXTEENTH},
   { 0,  SIXTEENTH},

   { 40, SIXTEENTH},
   { 0,  SIXTEENTH},
   { 0,  SIXTEENTH},
   { 30, SIXTEENTH},

   { 40, SIXTEENTH},
   { 0,  SIXTEENTH},
   { 30, SIXTEENTH},
   { 30, SIXTEENTH},
};
#define DRUMS_COUNT  (sizeof( s_drums) / sizeof( SeqNote))

// Arp: fast arpeggios
static SeqNote   s_arp[] =
{
   { 60, SIXTEENTH},  // C4
   { 63, SIXTEENTH},  // Eb4
   { 67, SIXTEENTH},  // G4
   { 72, SIXTEENTH},  // C5

   { 60, SIXTEENTH},
   { 63, SIXTEENTH},
   { 67, SIXTEENTH},
   { 72, SIXTEENTH},

   { 65, SIXTEENTH},  // F4
   { 68, SIXTEENTH},  // Ab4
   { 72, SIXTEENTH},  // C5
   { 77, SIXTEENTH},  // F5

   { 65, SIXTEENTH},
   { 68, SIXTEENTH},
   { 72, SIXTEENTH},
   { 77, SIXTEENTH},

   { 67, SIXTEENTH},  // G4
   { 70, SIXTEENTH},  // Bb4
   { 74, SIXTEENTH},  // D5
   { 79, SIXTEENTH},  // G5

   { 67, SIXTEENTH},
   { 70, SIXTEENTH},
   { 74, SIXTEENTH},
   { 79, SIXTEENTH},

   { 60, SIXTEENTH},  // C4
   { 63, SIXTEENTH},  // Eb4
   { 67, SIXTEENTH},  // G4
   { 72, SIXTEENTH},  // C5

   { 72, SIXTEENTH},
   { 67, SIXTEENTH},
   { 63, SIXTEENTH},
   { 60, SIXTEENTH},
};
#define ARP_COUNT  (sizeof( s_arp) / sizeof( SeqNote))


// ============================================================================
// Channel state
// ============================================================================
typedef struct
{
   MulleAudioVoiceHandle   toneVoice;
   MulleAudioVoiceHandle   noiseVoice;
   SeqNote                *notes;
   NSUInteger              noteCount;
   NSUInteger              noteIndex;
   float                   timer;
   float                   noiseMix;     // 0..1
   float                   volume;
} Channel;


// ============================================================================
// main
// ============================================================================
int  main( int argc, char *argv[])
{
   MulleAudio   *audio;
   Channel       channels[ NUM_CHANNELS];
   float         totalTime;
   float         elapsed;
   float         dt;
   int           i;

   srand( 42);

   // generate waveforms
   generate_sine();
   generate_saw();
   generate_triangle();
   generate_pokey();
   generate_perlin();

   audio = [MulleAudio instance];
   [audio setNumberOfForegroundVoices:TOTAL_VOICES];

   memset( channels, 0, sizeof( channels));

   //
   // Channel 0: Lead — sine tone + pokey noise
   //
   channels[ 0].toneVoice = [audio audioVoiceWithBytes:s_sineBuf
                                                length:sizeof( s_sineBuf)
                                        sampleEncoding:MulleAudioSampleEncodingSigned16Bit
                                      numberOfChannels:1
                                          sampleRateHz:SAMPLE_RATE
                                               options:MulleAudioVoiceOptionVoice0];
   channels[ 0].noiseVoice = [audio audioVoiceWithBytes:s_pokeyBuf
                                                 length:sizeof( s_pokeyBuf)
                                         sampleEncoding:MulleAudioSampleEncodingSigned16Bit
                                       numberOfChannels:1
                                           sampleRateHz:SAMPLE_RATE
                                                options:MulleAudioVoiceOptionVoice1];
   channels[ 0].notes     = s_lead;
   channels[ 0].noteCount = LEAD_COUNT;
   channels[ 0].noiseMix  = 0.15f;
   channels[ 0].volume    = LEAD_VOLUME;

   //
   // Channel 1: Bass — sawtooth, no noise
   //
   channels[ 1].toneVoice = [audio audioVoiceWithBytes:s_sawBuf
                                                length:sizeof( s_sawBuf)
                                        sampleEncoding:MulleAudioSampleEncodingSigned16Bit
                                      numberOfChannels:1
                                          sampleRateHz:SAMPLE_RATE
                                               options:MulleAudioVoiceOptionVoice2];
   channels[ 1].noiseVoice = MulleAudioVoiceOptionNoVoice;
   channels[ 1].notes     = s_bass;
   channels[ 1].noteCount = BASS_COUNT;
   channels[ 1].noiseMix  = 0.0f;
   channels[ 1].volume    = BASS_VOLUME;

   //
   // Channel 2: Drums — perlin noise only (tone silent)
   //
   channels[ 2].toneVoice = MulleAudioVoiceOptionNoVoice;
   channels[ 2].noiseVoice = [audio audioVoiceWithBytes:s_perlinBuf
                                                 length:sizeof( s_perlinBuf)
                                         sampleEncoding:MulleAudioSampleEncodingSigned16Bit
                                       numberOfChannels:1
                                           sampleRateHz:SAMPLE_RATE
                                                options:MulleAudioVoiceOptionVoice4];
   channels[ 2].notes     = s_drums;
   channels[ 2].noteCount = DRUMS_COUNT;
   channels[ 2].noiseMix  = 1.0f;
   channels[ 2].volume    = DRUM_VOLUME;

   //
   // Channel 3: Arp — triangle + pokey noise
   //
   channels[ 3].toneVoice = [audio audioVoiceWithBytes:s_triBuf
                                                length:sizeof( s_triBuf)
                                        sampleEncoding:MulleAudioSampleEncodingSigned16Bit
                                      numberOfChannels:1
                                          sampleRateHz:SAMPLE_RATE
                                               options:MulleAudioVoiceOptionVoice5];
   channels[ 3].noiseVoice = [audio audioVoiceWithBytes:s_pokeyBuf
                                                 length:sizeof( s_pokeyBuf)
                                         sampleEncoding:MulleAudioSampleEncodingSigned16Bit
                                       numberOfChannels:1
                                           sampleRateHz:SAMPLE_RATE
                                                options:MulleAudioVoiceOptionVoice6];
   channels[ 3].notes     = s_arp;
   channels[ 3].noteCount = ARP_COUNT;
   channels[ 3].noiseMix  = 0.1f;
   channels[ 3].volume    = ARP_VOLUME;

   // set all voices to loop
   for( i = 0; i < NUM_CHANNELS; i++)
   {
      if( channels[ i].toneVoice != MulleAudioVoiceOptionNoVoice)
         [audio setLoop:YES ofVoice:channels[ i].toneVoice];
      if( channels[ i].noiseVoice != MulleAudioVoiceOptionNoVoice)
         [audio setLoop:YES ofVoice:channels[ i].noiseVoice];
   }

   // compute total duration (use lead as reference)
   totalTime = 0.0f;
   for( i = 0; i < (int) LEAD_COUNT; i++)
      totalTime += s_lead[ i].duration;

   mulle_fprintf( stderr, "Playing %d-bar chiptune (%.1fs at %d BPM)...\n",
                  4, totalTime, BPM);

   // start first note of each channel
   for( i = 0; i < NUM_CHANNELS; i++)
   {
      SeqNote   *n;

      channels[ i].noteIndex = 0;
      channels[ i].timer     = 0.0f;
      n = &channels[ i].notes[ 0];

      if( n->note > 0)
      {
         float   hz;

         hz = midi_to_hz( n->note);

         if( channels[ i].toneVoice != MulleAudioVoiceOptionNoVoice)
         {
            [audio setVolume:channels[ i].volume
                     ofVoice:channels[ i].toneVoice];
            [audio pitchToFrequency:hz fromFrequency:BASE_FREQ ofVoice:channels[ i].toneVoice];
            [audio playVoice:channels[ i].toneVoice duration:n->duration];
         }
         if( channels[ i].noiseVoice != MulleAudioVoiceOptionNoVoice)
         {
            [audio setVolume:channels[ i].volume * channels[ i].noiseMix
                     ofVoice:channels[ i].noiseVoice];
            [audio pitchToFrequency:hz fromFrequency:BASE_FREQ ofVoice:channels[ i].noiseVoice];
            [audio playVoice:channels[ i].noiseVoice duration:n->duration];
         }
      }
   }

   // tick loop
   dt      = 0.005f;   // 5ms tick
   elapsed = 0.0f;

   while( elapsed < totalTime)
   {
      mulle_relativetime_sleep( dt);
      elapsed += dt;

      for( i = 0; i < NUM_CHANNELS; i++)
      {
         Channel   *ch;
         SeqNote   *n;

         ch = &channels[ i];
         ch->timer += dt;

         n = &ch->notes[ ch->noteIndex];
         if( ch->timer < n->duration)
            continue;

         // advance
         ch->timer -= n->duration;
         ch->noteIndex++;
         if( ch->noteIndex >= ch->noteCount)
            ch->noteIndex = 0;   // loop

         n = &ch->notes[ ch->noteIndex];

         if( n->note > 0)
         {
            float   hz;

            hz = midi_to_hz( n->note);

            if( ch->toneVoice != MulleAudioVoiceOptionNoVoice)
            {
               [audio pitchToFrequency:hz fromFrequency:BASE_FREQ ofVoice:ch->toneVoice];
               [audio playVoice:ch->toneVoice duration:n->duration];
            }
            if( ch->noiseVoice != MulleAudioVoiceOptionNoVoice)
            {
               [audio pitchToFrequency:hz fromFrequency:BASE_FREQ ofVoice:ch->noiseVoice];
               [audio playVoice:ch->noiseVoice duration:n->duration];
            }
         }
         else
         {
            // rest — stop voices
            if( ch->toneVoice != MulleAudioVoiceOptionNoVoice)
               [audio stopVoice:ch->toneVoice];
            if( ch->noiseVoice != MulleAudioVoiceOptionNoVoice)
               [audio stopVoice:ch->noiseVoice];
         }
      }
   }

   mulle_fprintf( stderr, "Done.\n");
   [audio mullePerformFinalize];
   return( 0);
}
