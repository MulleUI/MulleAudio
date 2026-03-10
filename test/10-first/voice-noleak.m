#import <MulleAudio/MulleAudio.h>
#import <mulle-objc-debug/mulle-objc-debug.h>


static char   foreseen[ 32] = "";

#define s_foreseen  (sizeof( foreseen) - 1)


int   main( int argc, char *argv[])
{
   MulleAudioVoiceHandle   voice;
   MulleAudio              *audio;

   audio = [MulleAudio instance];
   voice = [audio audioVoiceWithFileCData:mulle_data_make( foreseen, s_foreseen)
                                  options:MulleAudioVoiceOptionVoiceAny];

   return( 0);
}
