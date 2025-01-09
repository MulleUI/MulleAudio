#import "MulleAudio.h"


int  main( int argc, char *argv[])
{
   MulleAudioContext  *context;
   MulleAudioEngine   *engine;
   MulleAudioSound    *sound;
   char               *filename;

   filename = argc == 2 ? argv[ 1] : "ImperialMarch60.wav";

   context = [MulleAudioContext object];
   engine  = [context defaultAudioEngine];
   if( ! engine)
   {
      mulle_fprintf( stderr, "Could not create a playback engine\n");
      return( 1);
   }

   sound = [engine audioSoundWithContentsOfFileUTF8String:filename];
   if( ! sound)
   {
      mulle_fprintf( stderr, "Could not load \"%s\"\n", filename);
      return( 1);
   }

   [sound setFadeIn:10.0
        startVolume:0.0
          endVolume:0.8];
   [sound setBalance:-1.0];
   [sound setPitch:0.75];

   mulle_fprintf( stderr, "Playing \"%s\" on %@\n", filename,
                                                    [engine audioDevice]);

   [sound start];
   [sound waitForCompletion];

   // MEMO: as the miniaudio thread has been turned into a NSThread,
   //       when doing a pedantic exit, the universe will wait for
   //       it to finish. But it won't, unless we uninit miniaudio
   [context mullePerformFinalize];
   return( 0);
}