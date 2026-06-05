//
// Demo: generate a sine wave, play it, and record the engine output to a WAV.
// Verify the result with: audacity /tmp/recording-test.wav
//
#import "MulleAudio.h"
#import "MulleAudioEngine+Recording.h"

#include <math.h>

#define SAMPLE_RATE    48000
#define FREQ           440.0f
#define NUM_CYCLES     11
#define NUM_SAMPLES    (NUM_CYCLES * SAMPLE_RATE / (int) FREQ)  // = 1200, exact


int  main( int argc, char *argv[])
{
   MulleAudio             *audio;
   MulleAudioEngine       *engine;
   MulleAudioVoiceHandle  voice;
   int16_t                sineBuf[ NUM_SAMPLES];
   char                   *outPath;
   int                    i;

   outPath = argc >= 2 ? argv[ 1] : "/tmp/recording-test.wav";

   // generate a 440 Hz sine wave
   for( i = 0; i < NUM_SAMPLES; i++)
      sineBuf[ i] = (int16_t) (sinf( 2.0f * (float) M_PI * FREQ * (float) i / SAMPLE_RATE) * 32767.0f);

   audio  = [MulleAudio instance];
   engine = [audio audioEngine];

   // start recording before playing
   if( ! [engine startRecordingToFileUTF8String:outPath])
   {
      mulle_fprintf( stderr, "Failed to start recording to \"%s\"\n", outPath);
      return( 1);
   }

   voice = [audio audioVoiceWithBytes:sineBuf
                               length:sizeof( sineBuf)
                       sampleEncoding:MulleAudioSampleEncodingSigned16Bit
                     numberOfChannels:1
                         sampleRateHz:SAMPLE_RATE
                              options:MulleAudioVoiceOptionVoiceAny];
   if( voice == MulleAudioVoiceOptionNoVoice)
   {
      mulle_fprintf( stderr, "Could not create voice\n");
      return( 1);
   }

   [audio setLoop:YES ofVoice:voice];
   [audio playVoice:voice];

   mulle_fprintf( stderr, "Recording 2 seconds of 440 Hz sine to \"%s\"...\n", outPath);
   mulle_relativetime_sleep( 2.0);

   [engine stopRecording];
   mulle_fprintf( stderr, "Done. Check with: audacity %s\n", outPath);

   [audio mullePerformFinalize];
   return( 0);
}
