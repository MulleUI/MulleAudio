#ifdef __has_include
# if __has_include( "NSObject.h")
#  import "NSObject.h"
# endif
#endif

#import "import.h"

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

- (ma_decoder *) miniAudioDecoder;
- (ma_audio_buffer *) miniAudioBuffer;
- (ma_data_source *) miniAudioDataSource; // either ma_decoder or ma_audio_buffer

@end
