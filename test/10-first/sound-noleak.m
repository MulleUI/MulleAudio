#import <MulleAudio/MulleAudio.h>



@interface MulleAudioSound( Category)
@end

@implementation MulleAudioSound( Category)
@end




static int16_t  silence_samples[ 256][ 2];


int   main( int argc, char *argv[])
{
   ma_device_config    device_config;
   MulleAudioContext   *audioContext;
   MulleAudioDevice    *audioDevice;
   MulleAudioEngine    *audioEngine;
   MulleAudioSound     *audioSound;

   audioContext = [MulleAudioContext instance];
   if( [audioContext getDefaultMiniAudioPlaybackDeviceConfig:&device_config])
   {
      audioDevice = [audioContext audioDeviceWithMiniAudioDeviceConfig:&device_config];

      audioEngine = [MulleAudioEngine engineWithMiniAudioEngineConfig:NULL
                                                         audioContext:audioContext
                                                          audioDevice:audioDevice];
      if( ! audioEngine)
         return( 1);

      audioSound = [audioEngine audioSoundWithBytes:silence_samples
                                             length:sizeof( silence_samples)
                                    miniAudioFormat:ma_format_s16
                                   numberOfChannels:2
                                miniAudioSampleRate:ma_standard_sample_rate_48000];

      mulle_fprintf( stderr, "%@ on %@", audioSound, audioDevice);
   }

   return( 0);
}
