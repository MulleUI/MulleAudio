#import <MulleAudio/MulleAudio.h>



@interface MulleAudioEngine( Category)
@end

@implementation MulleAudioEngine( Category)
@end


int   main( int argc, char *argv[])
{
   ma_device_config    device_config;
   ma_engine_config    engine_config;
   MulleAudioContext   *audioContext;
   MulleAudioDevice    *audioDevice;
   MulleAudioEngine    *audioEngine;

   audioContext = [MulleAudioContext instance];
   if( [audioContext getDefaultMiniAudioPlaybackDeviceConfig:&device_config])
   {
      audioDevice = [audioContext audioDeviceWithMiniAudioDeviceConfig:&device_config];

      audioEngine = [[[MulleAudioEngine alloc] initWithMiniAudioEngineConfig:NULL
                                                                audioContext:audioContext
                                                                 audioDevice:audioDevice] autorelease];
      if( ! audioEngine)
         return( 1);

      mulle_fprintf( stderr, "%@", audioDevice);
   }

   return( 0);
}
