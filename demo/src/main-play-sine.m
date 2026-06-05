//
// Demo: for each standard sample rate AND each sample encoding, generate
// exactly ONE cycle of a sine at a frequency that divides evenly into that
// rate. Then use pitchToFrequency:fromFrequency:ofVoice: to play at
// 440, 220, 880 Hz. All should sound identical.
//
#import "MulleAudio.h"

#include <math.h>


struct sample_rate_info
{
   NSUInteger   sampleRate;
   NSUInteger   baseFreq;
};

static struct sample_rate_info   rates[] =
{
   {   8000,  400 },
   {  11025,  441 },
   {  16000,  400 },
   {  22050,  441 },
   {  24000,  400 },
   {  32000,  400 },
   {  44100,  441 },
   {  48000,  400 },
   {  88200,  441 },
   {  96000,  400 },
};

#define NUM_RATES  (sizeof( rates) / sizeof( rates[ 0]))


struct encoding_info
{
   MulleAudioSampleEncoding   encoding;
   NSUInteger                 bytesPerSample;
   char                       *name;
};

static struct encoding_info   encodings[] =
{
   { MulleAudioSampleEncodingUnsignedByte, 1, "u8"  },
   { MulleAudioSampleEncodingSigned16Bit,  2, "s16" },
   { MulleAudioSampleEncodingSigned24Bit,  3, "s24" },
   { MulleAudioSampleEncodingSigned32Bit,  4, "s32" },
   { MulleAudioSampleEncodingFloat,        4, "f32" },
};

#define NUM_ENCODINGS  (sizeof( encodings) / sizeof( encodings[ 0]))
#define MAX_SAMPLES_PER_CYCLE  240   // 96000 / 400


static void   generate_cycle( void *buf,
                              MulleAudioSampleEncoding encoding,
                              NSUInteger samplesPerCycle)
{
   NSUInteger   j;
   float        v;

   for( j = 0; j < samplesPerCycle; j++)
   {
      v = sinf( 2.0f * (float) M_PI * (float) j / (float) samplesPerCycle);

      switch( encoding)
      {
      case MulleAudioSampleEncodingUnsignedByte:
         ((uint8_t *) buf)[ j] = (uint8_t) ((v * 0.5f + 0.5f) * 255.0f);
         break;

      case MulleAudioSampleEncodingSigned16Bit:
         ((int16_t *) buf)[ j] = (int16_t) (v * 32767.0f);
         break;

      case MulleAudioSampleEncodingSigned24Bit:
         {
            int32_t   s = (int32_t) (v * 8388607.0f);
            uint8_t   *p = &((uint8_t *) buf)[ j * 3];
            p[ 0] = (uint8_t) (s & 0xFF);
            p[ 1] = (uint8_t) ((s >> 8) & 0xFF);
            p[ 2] = (uint8_t) ((s >> 16) & 0xFF);
         }
         break;

      case MulleAudioSampleEncodingSigned32Bit:
         // use double: float can't represent 2147483647 exactly (rounds to
         // 2^31, overflowing int32_t). double has enough mantissa bits.
         ((int32_t *) buf)[ j] = (int32_t) ((double) v * 2147483647.0);
         break;

      case MulleAudioSampleEncodingFloat:
         ((float *) buf)[ j] = v;
         break;
      }
   }
}


int  main( int argc, char *argv[])
{
   MulleAudio             *audio;
   MulleAudioVoiceHandle  voice;
   uint8_t                buf[ MAX_SAMPLES_PER_CYCLE * 4];  // worst case: 240 * 4 bytes
   NSUInteger             samplesPerCycle;
   NSUInteger             byteLength;
   NSUInteger             i;
   NSUInteger             e;

   audio = [MulleAudio instance];
   [audio setNumberOfForegroundVoices:1];

   for( i = 0; i < NUM_RATES; i++)
   {
      for( e = 0; e < NUM_ENCODINGS; e++)
      {
         samplesPerCycle = rates[ i].sampleRate / rates[ i].baseFreq;
         byteLength      = samplesPerCycle * encodings[ e].bytesPerSample;

         generate_cycle( buf, encodings[ e].encoding, samplesPerCycle);

         voice = [audio audioVoiceWithBytes:buf
                                     length:byteLength
                             sampleEncoding:encodings[ e].encoding
                           numberOfChannels:1
                               sampleRateHz:rates[ i].sampleRate
                                    options:MulleAudioVoiceOptionVoice0];
         if( voice == MulleAudioVoiceOptionNoVoice)
         {
            mulle_fprintf( stderr, "%s @ %ld Hz: no voice\n",
                           encodings[ e].name, (long) rates[ i].sampleRate);
            continue;
         }

         [audio setLoop:YES ofVoice:voice];
         [audio setVolume:0.5 ofVoice:voice];

         mulle_fprintf( stderr, "%s @ %ld Hz (%ld spc%s) -> 440\n",
                        encodings[ e].name, (long) rates[ i].sampleRate,
                        (long) samplesPerCycle,
                        samplesPerCycle < 25 ? " LOFI" : "");
         [audio pitchToFrequency:440.0f
                   fromFrequency:(float) rates[ i].baseFreq
                         ofVoice:voice];
         [audio playVoice:voice];
         mulle_relativetime_sleep( 0.5);

         mulle_fprintf( stderr, "%s @ %ld Hz (%ld spc%s) -> 220\n",
                        encodings[ e].name, (long) rates[ i].sampleRate,
                        (long) samplesPerCycle,
                        samplesPerCycle < 25 ? " LOFI" : "");
         [audio pitchToFrequency:220.0f
                   fromFrequency:(float) rates[ i].baseFreq
                         ofVoice:voice];
         mulle_relativetime_sleep( 0.5);

         mulle_fprintf( stderr, "%s @ %ld Hz (%ld spc%s) -> 880\n",
                        encodings[ e].name, (long) rates[ i].sampleRate,
                        (long) samplesPerCycle,
                        samplesPerCycle < 25 ? " LOFI" : "");
         [audio pitchToFrequency:880.0f
                   fromFrequency:(float) rates[ i].baseFreq
                         ofVoice:voice];
         mulle_relativetime_sleep( 0.5);

         [audio stopVoice:voice];
      }
   }

   [audio mullePerformFinalize];
   return( 0);
}
