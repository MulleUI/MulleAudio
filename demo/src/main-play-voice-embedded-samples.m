#import "MulleAudio.h"

static uint8_t    samples[] =
{
   128, 153, 177, 199, 219, 234, 244, 249,
   249, 244, 234, 219, 199, 177, 153, 128,
   102, 78, 56, 36, 21, 11, 6, 6,
   11, 21, 36, 56, 78, 102, 128, 153,
   177, 199, 219, 234, 244, 249, 249, 244,
   234, 219, 199, 177
};

int  main( int argc, char *argv[])
{
   MulleAudio             *audio;
   MulleAudioVoiceHandle  voice;
   char                   *filename;

   filename = "foreseen.inc";

   audio = [MulleAudio object];
   voice = [audio audioVoiceWithBytes:samples
                               length:sizeof( samples)
                       sampleEncoding:MulleAudioSampleEncodingUnsignedByte
                     numberOfChannels:1
                         sampleRateHz:44100
                              options:MulleAudioVoiceOptionVoiceAny];
   if( voice == MulleAudioVoiceOptionNoVoice)
   {
      switch( errno)
      {
      case ENODEV :
         mulle_fprintf( stderr, "No voice left\n");
         return( 1);

      case EBUSY :
         mulle_fprintf( stderr, "Desired voice is still playing\n");
         return( 1);

      default :
         mulle_fprintf( stderr, "Could not load \"%s\": %s\n", filename, strerror( errno));
         return( 1);
      }
   }

   [audio setLoop:YES
          ofVoice:voice];
   [audio playVoice:voice];
   mulle_relativetime_sleep( 1.5);

   // will never end because it loops so...
   [audio mullePerformFinalize];

   return( 0);
}
