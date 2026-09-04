#import <MulleAudio/MulleAudio.h>



@interface MulleAudioSound( Category)
@end

@implementation MulleAudioSound( Category)
@end




static int16_t  silence_samples[ 256][ 2];


int   main( int argc, char *argv[])
{
   ma_device_config       device_config;
   MulleAudioContext      *audioContext;
   MulleAudioDevice       *audioDevice;
   MulleAudioEngine       *audioEngine;
   MulleAudioSound        *audioSound;
   MulleAudioSound        *audioSoundCopy;

   audioContext = [MulleAudioContext instance];
   if( ! audioContext)
   {
      mulle_fprintf( stderr, "got no context\n");
      return( 1);
   }

   if( ! [audioContext getDefaultMiniAudioPlaybackDeviceConfig:&device_config])
   {
      mulle_fprintf( stderr, "got no device config\n");
      return( 1);
   }

   audioDevice = [audioContext audioDeviceWithMiniAudioDeviceConfig:&device_config];
   if( ! audioDevice)
   {
      mulle_fprintf( stderr, "got no device\n");
      return( 1);
   }

   audioEngine = [MulleAudioEngine engineWithMiniAudioEngineConfig:NULL
                                                    audioContext:audioContext
                                                     audioDevice:audioDevice];
   if( ! audioEngine)
   {
      mulle_fprintf( stderr, "got no engine\n");
      return( 1);
   }

   audioSound = [audioEngine audioSoundWithBytes:silence_samples
                                          length:sizeof( silence_samples)
                                 miniAudioFormat:ma_format_s16
                                numberOfChannels:2
                             miniAudioSampleRate:ma_standard_sample_rate_48000];
   if( ! audioSound)
   {
      mulle_fprintf( stderr, "got no sound\n");
      return( 1);
   }

#if 1
   audioSoundCopy = [MulleAudioSound soundWithAudioSound:audioSound];
   if( ! audioSoundCopy)
   {
      mulle_fprintf( stderr, "got no sound copy\n");
      return( 1);
   }
#endif
   return( 0);
}
