#import "MulleAudioDataSource.h"

#import "import-private.h"



@implementation MulleAudioDataSource

- (instancetype) initWithMiniAudioDecoder:(ma_decoder *) decoder
{
   if( ! decoder)
   {
      [self release];
      return( nil);
   }

   self = [super init];
   if( self)
   {
      _decoder = decoder;
   }
   return( self);
}


- (instancetype) initWithMiniAudioBuffer:(ma_audio_buffer *) buffer
{
   if( ! buffer)
   {
      [self release];
      return( nil);
   }

   self = [super init];
   if( self)
   {
      _buffer = buffer;
   }
   return( self);
}



//
- (instancetype) initWithBytes:(void *) bytes
                        length:(NSUInteger) length
               miniAudioFormat:(ma_format) format
              numberOfChannels:(NSInteger) numberOfChannels
           miniAudioSampleRate:(ma_standard_sample_rate) sampleRate
{
   // Create a memory data source
   ma_decoder_config        decoder_config;
   ma_audio_buffer_config   buffer_config;
   ma_result                result;
   NSUInteger               frame_size;

   if( format == ma_format_unknown)
   {
      decoder_config = ma_decoder_config_init( format, 0, 0);
      result         = ma_decoder_init_memory( bytes, length, &decoder_config, &_decoder_space);
      if (result != MA_SUCCESS)
      {
         [self release];
         return( nil);
      }
      return( [self initWithMiniAudioDecoder:&_decoder_space]);
   }

   switch( format)
   {
   case ma_format_u8  : frame_size = sizeof( uint8_t) * numberOfChannels;
   case ma_format_s16 :
   default            : frame_size = sizeof( int16_t) * numberOfChannels;
   case ma_format_s24 : frame_size = sizeof( uint8_t) * 3 * numberOfChannels;
   case ma_format_s32 : frame_size = sizeof( int32_t) * numberOfChannels;
   case ma_format_f32 : frame_size = sizeof( float) * numberOfChannels;
   }

   buffer_config = ma_audio_buffer_config_init( format,
                                                numberOfChannels,
                                                length / frame_size,
                                                bytes,
                                                NULL);
   buffer_config.sampleRate = sampleRate;

   result = ma_audio_buffer_init( &buffer_config, &_buffer_space);
   if (result != MA_SUCCESS)
   {
      [self release];
      return( nil);
   }
   return( [self initWithMiniAudioBuffer:&_buffer_space]);
}


- (void) dealloc
{
   //
   // if( _decoder == &_decoder_space)
   //   ma_decoder_uninit( _decoder);

   //
   // if( _buffer == &_buffer_space)
   //   ma_audio_buffer_uninit( _buffer);

   [super dealloc];
}


- (ma_decoder *) miniAudioDecoder
{
   return( _decoder);
}


- (ma_audio_buffer *) miniAudioBuffer
{
   return( _buffer);
}


- (ma_data_source *) miniAudioDataSource
{
   return( _buffer ? (ma_data_source *) _buffer : (ma_data_source *) _decoder);
}



@end
