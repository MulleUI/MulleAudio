#import <MulleAudio/MulleAudio.h>



@interface MulleAudioDataSource( Category)
@end

@implementation MulleAudioDataSource( Category)
@end


static int16_t  silence_samples[ 256][ 2];


int   main( int argc, char *argv[])
{
   MulleAudioDataSource   *audioDataSource;

   audioDataSource = [MulleAudioDataSource alloc];
   audioDataSource = [audioDataSource initWithBytes:silence_samples
                                             length:sizeof( silence_samples)
                                    miniAudioFormat:ma_format_s16
                                   numberOfChannels:2
                                miniAudioSampleRate:ma_standard_sample_rate_48000];
   audioDataSource = [audioDataSource autorelease];

   return( 0);
}
