#import "MulleAudioEngine+Recording.h"

#import "import-private.h"

#include "MulleAudioRecordingTap-private.h"

#include <string.h>


static void   recording_process( void *pUserData,
                                 float *pFramesOut,
                                 ma_uint64 frameCount)
{
   struct MulleAudioRecordingTap   *tap = (struct MulleAudioRecordingTap *) pUserData;

   if( tap->isRecording && pFramesOut && frameCount > 0)
   {
      ma_encoder_write_pcm_frames( &tap->encoder, pFramesOut, frameCount, NULL);
   }
}


@implementation MulleAudioEngine (Recording)

- (BOOL) startRecordingToFileUTF8String:(char *) path
{
   struct MulleAudioRecordingTap   *tap;
   ma_engine                       *engine;
   ma_encoder_config               encoderConfig;
   ma_uint32                       channels;
   ma_uint32                       sampleRate;
   ma_result                       result;
   struct mulle_allocator          *allocator;

   if( _recordingTap)
      return( NO);

   engine     = [self miniAudioEngine];
   channels   = ma_engine_get_channels( engine);
   sampleRate = ma_engine_get_sample_rate( engine);
   allocator  = MulleObjCInstanceGetAllocator( self);

   tap = mulle_allocator_calloc( allocator, 1, sizeof( struct MulleAudioRecordingTap));

   encoderConfig = ma_encoder_config_init( ma_encoding_format_wav,
                                           ma_format_f32,
                                           channels,
                                           sampleRate);
   result = ma_encoder_init_file( path, &encoderConfig, &tap->encoder);
   if( result != MA_SUCCESS)
   {
      mulle_allocator_free( allocator, tap);
      return( NO);
   }

   tap->channels    = channels;
   tap->isRecording = YES;

   // hook into the engine's process callback
   engine->onProcess       = recording_process;
   engine->pProcessUserData = tap;

   _recordingTap = tap;
   return( YES);
}


- (void) stopRecording
{
   struct MulleAudioRecordingTap   *tap;
   struct mulle_allocator          *allocator;
   ma_engine                       *engine;

   tap = _recordingTap;
   if( ! tap)
      return;

   tap->isRecording = NO;

   engine = [self miniAudioEngine];
   engine->onProcess        = NULL;
   engine->pProcessUserData = NULL;

   ma_encoder_uninit( &tap->encoder);

   allocator = MulleObjCInstanceGetAllocator( self);
   mulle_allocator_free( allocator, tap);

   _recordingTap = NULL;
}


- (BOOL) isRecording
{
   return( _recordingTap && _recordingTap->isRecording);
}


- (ma_node *) recordingTapNode
{
   return( NULL);  // not using node approach
}

@end
