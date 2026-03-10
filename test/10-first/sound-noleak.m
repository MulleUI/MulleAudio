#import <MulleAudio/MulleAudio.h>



@interface MulleAudioSound( Category)
@end

@implementation MulleAudioSound( Category)
@end




static int16_t  silence_samples[ 256][ 2];


int   main( int argc, char *argv[])
{
   ma_device_config    device_config;
   ma_engine_config    engine_config;
   MulleAudioContext   *audioContext;
   MulleAudioDevice    *audioDevice;
   MulleAudioEngine    *audioEngine;
   MulleAudioDataSource   *audioDataSource;
   MulleAudioSound     *audioSound;

   audioContext = [MulleAudioContext instance];
   if( [audioContext getDefaultMiniAudioPlaybackDeviceConfig:&device_config])
   {
      audioDevice = [audioContext audioDeviceWithMiniAudioDeviceConfig:&device_config];

      audioEngine = [[[MulleAudioEngine alloc] initWithMiniAudioEngineConfig:NULL
                                                                audioContext:audioContext
                                                                 audioDevice:audioDevice] autorelease];
      if( ! audioEngine)
         return( 1);

      audioDataSource = [MulleAudioDataSource alloc];
      audioDataSource = [audioDataSource initWithBytes:silence_samples
                                                length:sizeof( silence_samples)
                                       miniAudioFormat:ma_format_s16
                                      numberOfChannels:2
                                   miniAudioSampleRate:ma_standard_sample_rate_48000];
      audioDataSource = [audioDataSource autorelease];

      audioSound      = [MulleAudioSound alloc];
      audioSound      = [audioSound initWithAudioDataSource:audioDataSource
                                                audioEngine:audioEngine];
      audioSound      = [audioSound autorelease];

      mulle_fprintf( stderr, "%@ on %@", audioSound, audioDevice);
   }

   return( 0);
}
