#import <MulleAudio/MulleAudio.h>

// this is supposed to catch strange ivarhash problems
@interface MulleAudioContext( Category)
@end

@implementation MulleAudioContext( Category)
@end


int   main( int argc, char *argv[])
{
#if defined( __MULLE_OBJC__)
   if( mulle_objc_global_check_universe( __MULLE_OBJC_UNIVERSENAME__) != mulle_objc_universe_is_ok)
      return( 1);
#endif

   [MulleAudioContext instance];

   return( 0);
}
