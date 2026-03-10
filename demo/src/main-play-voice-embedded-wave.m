#import "MulleAudio.h"

static char  foreseen[] = ""
#include "foreseen.inc"
;
#define s_foreseen  (sizeof(foreseen) - 1)


int  main( int argc, char *argv[])
{
   MulleAudio             *audio;
   MulleAudioVoiceHandle  voice;
   char                   *filename;

   filename = "foreseen.inc";

   audio = [MulleAudio instance];
   voice = [audio audioVoiceWithFileCData:mulle_data_make( foreseen, s_foreseen)
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

   [audio setVolume:0.8
            ofVoice:voice];
   [audio setBalance:-1.0
            ofVoice:voice];
   [audio setPitch:0.75
            ofVoice:voice];
   [audio fadeInVoice:voice
                 time:0.5];
   mulle_relativetime_sleep( 1.5);

   [audio waitForCompletionOfVoice:voice];
   [audio mullePerformFinalize];

   return( 0);
}