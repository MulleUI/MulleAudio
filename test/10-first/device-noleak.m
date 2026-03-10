#import <MulleAudio/MulleAudio.h>


@interface MulleAudioDevice( Category)
@end

@implementation MulleAudioDevice( Category)
@end


int   main( int argc, char *argv[])
{
   ma_device_config    config;
   MulleAudioContext   *context;
   MulleAudioDevice    *device;

   context = [MulleAudioContext instance];
   if( [context getDefaultMiniAudioPlaybackDeviceConfig:&config])
   {
      device = [context audioDeviceWithMiniAudioDeviceConfig:&config];
      mulle_fprintf( stderr, "%@", device);
      [device start];
   }

   return( 0);
}
