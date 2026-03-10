#import <MulleAudio/MulleAudio.h>



@interface MulleAudioSound( Category)
@end

@implementation MulleAudioSound( Category)
@end




static int16_t  silence_samples[ 256][ 2];


int   main( int argc, char *argv[])
{
   ma_device_config       device_config;
   ma_engine_config       engine_config;
   MulleAudioContext      *audioContext;
   MulleAudioDevice       *audioDevice;
   MulleAudioEngine       *audioEngine;
   MulleAudioDataSource   *audioDataSource;
   MulleAudioSound        *audioSound;
   MulleAudioSound        *audioSoundCopy;

   audioContext = [MulleAudioContext instance];
   if( ! audioContext)
   {
      mulle_fprintf( stderr, "got no context\n");
      return( 1);
   }

   audioDevice  = [audioContext audioDeviceWithMiniAudioDeviceConfig:NULL];
   if( ! audioDevice)
   {
      mulle_fprintf( stderr, "got no device\n");
      return( 1);
   }

   audioEngine = [MulleAudioEngine alloc];
   audioEngine = [audioEngine initWithMiniAudioEngineConfig:NULL
                                               audioContext:audioContext
                                                audioDevice:audioDevice];
   audioEngine = [audioEngine autorelease];

   if( ! audioEngine)
   {
      mulle_fprintf( stderr, "got no engine\n");
      return( 1);
   }

   audioDataSource = [MulleAudioDataSource alloc];
   audioDataSource = [audioDataSource initWithBytes:silence_samples
                                             length:sizeof( silence_samples)
                                    miniAudioFormat:ma_format_s16
                                   numberOfChannels:2
                                miniAudioSampleRate:ma_standard_sample_rate_48000];
   audioDataSource = [audioDataSource autorelease];
   if( ! audioDataSource)
   {
      mulle_fprintf( stderr, "got no dataSource\n");
      return( 1);
   }

   audioSound = [MulleAudioSound alloc];
   audioSound = [audioSound initWithAudioDataSource:audioDataSource
                                        audioEngine:audioEngine];
   audioSound = [audioSound autorelease];
   if( ! audioSound)
   {
      mulle_fprintf( stderr, "got no sound\n");
      return( 1);
   }

#if 1
   audioSoundCopy = [MulleAudioSound alloc];
   audioSoundCopy = [audioSoundCopy initWithAudioSound:audioSound];
   audioSoundCopy = [audioSoundCopy autorelease];
   if( ! audioSoundCopy)
   {
      mulle_fprintf( stderr, "got no sound copy\n");
      return( 1);
   }
#endif
   return( 0);
}
