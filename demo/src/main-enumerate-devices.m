#import "MulleAudio.h"


static void   enumerate( char *title, MulleAudioDeviceInfoEnumerator   *rover)
{
   ma_device_info   *info;
   ma_uint32        i;

   mulle_printf( "%s:\n", title);

   while( info = [rover nextMiniAudioDeviceInfo])
   {

// typedef struct
// {
//     /* Basic info. This is the only information guaranteed to be filled in during device enumeration. */
//     ma_device_id id;
//     char name[MA_MAX_DEVICE_NAME_LENGTH + 1];   /* +1 for null terminator. */
//     ma_bool32 isDefault;
//
//     ma_uint32 nativeDataFormatCount;
//     struct
//     {
//         ma_format format;       /* Sample format. If set to ma_format_unknown, all sample formats are supported. */
//         ma_uint32 channels;     /* If set to 0, all channels are supported. */
//         ma_uint32 sampleRate;   /* If set to 0, all sample rates are supported. */
//         ma_uint32 flags;        /* A combination of MA_DATA_FORMAT_FLAG_* flags. */
//     } nativeDataFormats[/*ma_format_count * ma_standard_sample_rate_count * MA_MAX_CHANNELS*/ 64];  /* Not sure how big to make this. There can be *many* permutations for virtual devices which can support anything. */
// } ma_device_info;

      // id is basically unprintable...
      mulle_printf( "   \"%s\"\n", info->name);
      if( info->isDefault)
         mulle_printf( "      default : %bd\n", info->isDefault);

      for( i = 0; i < info->nativeDataFormatCount; i++)
      {
         mulle_printf( "         format     : %d\n", info->nativeDataFormats[ i].format);
         mulle_printf( "         channels   : %u\n", info->nativeDataFormats[ i].channels);
         mulle_printf( "         sampleRate : %u\n", info->nativeDataFormats[ i].sampleRate);
         mulle_printf( "         flags      : %u\n", info->nativeDataFormats[ i].flags);
      }
   }
}

int  main( void)
{
   MulleAudioContext                *context;
   MulleAudioDeviceInfoEnumerator   *rover;

   context = [MulleAudioContext object];
   rover   = [context enumerateMiniAudioPlaybackDeviceInfos];
   enumerate( "Playback", rover);
   mulle_printf("\n");
   rover   = [context enumerateMiniAudioCaptureDeviceInfos];
   enumerate( "Capture", rover);

   return( 0);
}