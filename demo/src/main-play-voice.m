#import "MulleAudio.h"



int  main( int argc, char *argv[])
{
   MulleAudio             *audio;
   MulleAudioVoiceHandle  voice;
   char                   *filename;

   filename = argc == 2 ? argv[ 1] : "ImperialMarch60.wav";

   audio  = [MulleAudio object];
   voice  = [audio audioVoiceWithContentsOfFileUTF8String:filename
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

   // reload same into new sound and same voice, so we should not have an echo
   voice  = [audio audioVoiceWithContentsOfFileUTF8String:filename
                                                  options:voice];
   [audio setBalance:+1.0
             ofVoice:voice];
   [audio setPitch:+1.0
           ofVoice:voice];
   [audio playVoice:voice];
   [audio waitForCompletionOfVoice:voice];

   return( 0);
}