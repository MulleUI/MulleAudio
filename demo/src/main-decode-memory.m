#import "MulleAudio.h"



static int16_t  silence_samples[ 256][ 2];


int  main( int argc, char *argv[])
{
   ma_decoder          _decoder_space;
   ma_decoder_config   decoder_config;
   ma_result           result;

   decoder_config = ma_decoder_config_init( ma_format_s16, 2, ma_standard_sample_rate_48000);
   result         = ma_decoder_init_memory( silence_samples,
                                            sizeof( silence_samples),
                                            &decoder_config,
                                            &_decoder_space);
   if( result != MA_SUCCESS)
   {
      fprintf( stderr, "FAIL\n");
      return( 1);
   }
   ma_decoder_uninit( &_decoder_space);

   return( 0);
}

