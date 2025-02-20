#import <MulleAudio/MulleAudio.h>


// Simple WAV for 48kHz, 16-bit stereo
static unsigned char   silence_samples[ 44 + 1024] = 
{
    'R', 'I', 'F', 'F',             // RIFF chunk descriptor
    0x24, 0x04, 0x00, 0x00,         // Chunk size (file size - 8)
    'W', 'A', 'V', 'E',             // Format
    'f', 'm', 't', ' ',             // Subchunk1 ID
    0x10, 0x00, 0x00, 0x00,         // Subchunk1 size (16 bytes)
    0x01, 0x00,                     // Audio format (1 = PCM)
    0x02, 0x00,                     // Number of channels (2)
    0x80, 0xBB, 0x00, 0x00,         // Sample rate (48000)
    0x00, 0xEE, 0x02, 0x00,         // Byte rate (48000*2*2)
    0x04, 0x00,                     // Block align (2*2)
    0x10, 0x00,                     // Bits per sample (16)
    'd', 'a', 't', 'a',             // Subchunk2 ID
    0x00, 0x04, 0x00, 0x00          // Subchunk2 size (data size)
};


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

