//
//  MulleAudioDataSource.h
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
#ifdef __has_include
# if __has_include( "NSObject.h")
#  import "NSObject.h"
# endif
#endif

#import "import.h"

#ifndef MULLE_BOOL_DEFINED
# error "you need to include <mulle-c11/mulle-c11-bool.h> before including \"miniaudio.h\""
#endif

#include "miniaudio.h"


@interface MulleAudioDataSource : NSObject < MulleObjCThreadSafe>
{
   ma_decoder        *_decoder;
   ma_decoder         _decoder_space;
   ma_audio_buffer   *_buffer;
   ma_audio_buffer    _buffer_space;
}

// as format pass `ma_format_unknown` and miniaudio will guess the rest
//
// or use for a raw sample buffer:
//       miniAudioFormat:ma_format_f32                // for float32
//      numberOfChannels:2                            // for stereo
//   miniAudioSampleRate:ma_standard_sample_rate_48000 // for 48Khz
//
// or for an embedded wave file try:
//       miniAudioFormat:ma_encoding_format_wav
//      numberOfChannels:0
//   miniAudioSampleRate:0
- (instancetype) initWithBytes:(void *) bytes
                        length:(NSUInteger) length
               miniAudioFormat:(ma_format) format
              numberOfChannels:(NSInteger) numberOfChannels
           miniAudioSampleRate:(ma_standard_sample_rate) sampleRate;

+ (instancetype) dataSourceWithBytes:(void *) bytes
                              length:(NSUInteger) length
                     miniAudioFormat:(ma_format) format
                    numberOfChannels:(NSInteger) numberOfChannels
                 miniAudioSampleRate:(ma_standard_sample_rate) sampleRate;

- (ma_decoder *) miniAudioDecoder;
- (ma_audio_buffer *) miniAudioBuffer;
- (ma_data_source *) miniAudioDataSource; // either ma_decoder or ma_audio_buffer

@end
