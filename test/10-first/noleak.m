#import <MulleAudio/MulleAudio.h>
#import <mulle-objc-debug/mulle-objc-debug.h>


@interface MulleObject( Category)
@end

@implementation MulleObject( Category)
@end


int   main( int argc, char *argv[])
{
#if defined( __MULLE_OBJC__)
   if( mulle_objc_global_check_universe( __MULLE_OBJC_UNIVERSENAME__) != mulle_objc_universe_is_ok)
      return( 1);
#endif
   struct _mulle_objc_universe   *universe;
   mulle_objc_universeid_t       universeid;

   universe   = mulle_objc_global_get_universe( __MULLE_OBJC_UNIVERSEID__);
   if( universe)
      mulle_objc_universe_htmldump_to_directory( universe, ".");

   [MulleAudio instance];

   return( 0);
}
