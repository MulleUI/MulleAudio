#import <MulleAudio/MulleAudio.h>



@interface MulleAudioEngine( Category)
@end

@implementation MulleAudioEngine( Category)
@end


int   main( int argc, char *argv[])
{
   ma_device_config    device_config;
   MulleAudioContext   *audioContext;
   MulleAudioDevice    *audioDevice;
   MulleAudioEngine    *audioEngine;

   audioContext = [MulleAudioContext instance];
   if( [audioContext getDefaultMiniAudioPlaybackDeviceConfig:&device_config])
   {
      audioDevice = [audioContext audioDeviceWithMiniAudioDeviceConfig:&device_config];

      audioEngine = [MulleAudioEngine engineWithMiniAudioEngineConfig:NULL
                                                         audioContext:audioContext
                                                          audioDevice:audioDevice];
      if( ! audioEngine)
         return( 1);

      mulle_fprintf( stderr, "%@", audioDevice);
   }

   return( 0);
}
