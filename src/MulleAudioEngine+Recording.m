//
//  MulleAudioEngine+Recording.m
//  MulleAudio
//
//  Copyright (c) 2026 Nat! - Mulle kybernetiK.
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
