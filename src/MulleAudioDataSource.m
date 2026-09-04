//
//  MulleAudioDataSource.m
//  MulleAudio
//
//  Copyright (c) 2024 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
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
   case ma_format_u8  : frame_size = sizeof( uint8_t) * numberOfChannels; break;
   case ma_format_s16 : frame_size = sizeof( int16_t) * numberOfChannels; break;
   case ma_format_s24 : frame_size = sizeof( uint8_t) * 3 * numberOfChannels; break;
   case ma_format_s32 : frame_size = sizeof( int32_t) * numberOfChannels; break;
   case ma_format_f32 : frame_size = sizeof( float) * numberOfChannels; break;
   default            : frame_size = sizeof( int16_t) * numberOfChannels; break;
   }

   buffer_config = ma_audio_buffer_config_init( format,
                                                numberOfChannels,
                                                length / frame_size,
                                                bytes,
                                                NULL);
   buffer_config.sampleRate = sampleRate;

   result = ma_audio_buffer_init_copy( &buffer_config, &_buffer_space);
   if (result != MA_SUCCESS)
   {
      [self release];
      return( nil);
   }
   return( [self initWithMiniAudioBuffer:&_buffer_space]);
}


- (void) dealloc
{
   if( _decoder == &_decoder_space)
      ma_decoder_uninit( _decoder);

   if( _buffer == &_buffer_space)
      ma_audio_buffer_uninit( _buffer);

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



+ (instancetype) dataSourceWithBytes:(void *) bytes
                              length:(NSUInteger) length
                     miniAudioFormat:(ma_format) format
                    numberOfChannels:(NSInteger) numberOfChannels
                 miniAudioSampleRate:(ma_standard_sample_rate) sampleRate
{
   MulleAudioDataSource   *dataSource;

   dataSource = [MulleAudioDataSource alloc];
   dataSource = [dataSource initWithBytes:bytes
                                   length:length
                          miniAudioFormat:format
                         numberOfChannels:numberOfChannels
                      miniAudioSampleRate:sampleRate];
   dataSource = [dataSource autorelease];
   return( dataSource);
}

@end
