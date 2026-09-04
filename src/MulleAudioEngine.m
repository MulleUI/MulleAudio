//
//  MulleAudioEngine.m
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
#import "MulleAudioEngine.h"
#import "MulleAudioEngine+Recording.h"

#import "import-private.h"

#import "MulleAudioContext.h"
#import "MulleAudioContext+Private.h"
#import "MulleAudioDevice.h"
#import "MulleAudioSound.h"
#import "MulleAudioDataSource.h"
#import <MulleObjC/NSDebug.h>


@implementation MulleAudioEngine

+ (instancetype) engineWithMiniAudioEngineConfig:(ma_engine_config *) config
                                     audioContext:(MulleAudioContext *) audioContext
                                      audioDevice:(MulleAudioDevice *) audioDevice
{
   MulleAudioEngine   *engine;

   engine = [MulleAudioEngine alloc];
   engine = [engine initWithMiniAudioEngineConfig:config
                                     audioContext:audioContext
                                      audioDevice:audioDevice];
   engine = [engine autorelease];
   return( engine);
}


- (instancetype) initWithMiniAudioEngine:(ma_engine *) engine
                            audioContext:(MulleAudioContext *) audioContext
                             audioDevice:(MulleAudioDevice *) audioDevice
{
   ma_device                *device;
   struct mulle_allocator   *allocator;

   if( ! audioContext)
   {
      [self release];
      return( nil);
   }

   if( ! audioDevice)
   {
      device = ma_engine_get_device( engine);
      if( ! device)
      {
         [self release];
         return( nil);
      }
      audioDevice = [MulleAudioDevice deviceWithMiniAudioDevice:device
                                                   audioContext:audioContext];
   }

   self = [super init];
   if( self)
   {
      _engine       = engine;

      _audioDevice  = [audioDevice retain];
      [_audioDevice setAudioEngine:self];

      _audioContext = audioContext;
      [_audioContext _addEngine:self];

      allocator = MulleObjCInstanceGetAllocator( self);
      mulle_pointerarray_init( &_sounds, 16, allocator);
   }

   return( self);
}


- (instancetype) initWithMiniAudioEngineConfig:(ma_engine_config *) config
                                  audioContext:(MulleAudioContext *) audioContext
                                   audioDevice:(MulleAudioDevice *) audioDevice
{
   ma_engine_config   engineConfig;
   ma_result          engine_state;

   if( ! audioContext)
      audioContext = [audioDevice audioContext];

   if( ! audioContext)
   {
      [self release];
      return( nil);
   }

   if( ! config)
   {
      engineConfig = ma_engine_config_init();
      config       = &engineConfig;
   }

   config->pContext         = [audioContext miniAudioContext];  // Use your own context
   config->pResourceManager = [audioContext miniAudioResourceManager];
   
   if( audioDevice)
      config->pDevice = [audioDevice miniAudioDevice];    // Set to the ID of the desired device

   engine_state = ma_engine_init( config, &_engine_space);
   if( engine_state != MA_SUCCESS)
   {
      [self release];
      return( nil);
   }

   return( [self initWithMiniAudioEngine:&_engine_space
                            audioContext:audioContext
                             audioDevice:audioDevice]);
}


- (id) initWithAudioContext:(MulleAudioContext *) audioContext
{
   return( [self initWithMiniAudioEngineConfig:NULL
                                  audioContext:audioContext
                                   audioDevice:nil]);
}


- (BOOL) start
{
   return( ma_engine_start( _engine) == MA_SUCCESS);
}


- (void) stop
{
   ma_engine_stop( _engine);
}


- (BOOL) isRunning
{
   return( [_audioDevice isRunning]);
}


- (void) finalize
{
   struct mulle_pointerarray  copy;
   MulleAudioSound            *audioSound;

   [_audioContext _removeEngine:self];

   // stop recording if active
   [self stopRecording];

   copy = _sounds;

   // sounds who remove themselves, will just not find themselves
   mulle_pointerarray_init( &_sounds, 0, _sounds.allocator);

   // audio engines will remove themselves from _engines
   // so operate on a copy
   mulle_pointerarray_for( &copy, audioSound)
   {
      [audioSound mullePerformFinalize];
   }

   mulle_pointerarray_done( &copy);

   // ensure no new engines suddenly appeared
   assert( mulle_pointerarray_get_count( &_sounds) == 0);

   // NOW do the rest

   if( _engine)
      ma_engine_stop( _engine);


   [_audioDevice mullePerformFinalize];
   [_audioDevice setAudioEngine:nil];

   if( _engine)
   {
      ma_engine_uninit( _engine);
      if( NSDebugEnabled)
         mulle_fprintf( stderr, "miniaudio engine uninit\n");
      _engine = NULL;
   }

   // get rid of readonly property
   [_audioDevice release];
   _audioDevice = nil;

   [super finalize];
}


- (void) dealloc
{
   [super dealloc];
}


- (void) _addSound:(MulleAudioSound *) sound
{
   assert( ! [self mulleIsFinalized]);

   mulle_pointerarray_add( &_sounds, sound);
}


- (void) _removeSound:(MulleAudioSound *) sound
{
   mulle_pointerarray_remove_unique( &_sounds, sound);
}


- (ma_engine *) miniAudioEngine
{
   return( _engine);
}


- (ma_resource_manager *) miniAudioResourceManager
{
   return( ma_engine_get_resource_manager( _engine));
}


- (MulleAudioSound *) audioSoundWithContentsOfFileUTF8String:(char *) path;
{
   MulleAudioSound  *audioSound;

   audioSound = [MulleAudioSound alloc];
   audioSound = [audioSound initWithContentsOfFileUTF8String:path
                                                 audioEngine:self];
   audioSound = [audioSound autorelease];
   return( audioSound);
}


- (MulleAudioSound *) audioSoundWithBytes:(void *) bytes
                                   length:(NSUInteger) length
                          miniAudioFormat:(ma_format) format
                         numberOfChannels:(NSInteger) numberOfChannels
                      miniAudioSampleRate:(ma_standard_sample_rate) sampleRate
{
   MulleAudioDataSource   *audioDataSource;
   MulleAudioSound        *audioSound;

   audioDataSource = [self audioDataSourceWithBytes:bytes
                                            length:length
                                   miniAudioFormat:format
                                  numberOfChannels:numberOfChannels
                               miniAudioSampleRate:sampleRate];

   audioSound = [self audioSoundWithAudioDataSource:audioDataSource];
   return( audioSound);
}


- (MulleAudioDataSource *) audioDataSourceWithBytes:(void *) bytes
                                             length:(NSUInteger) length
                                    miniAudioFormat:(ma_format) format
                                   numberOfChannels:(NSInteger) numberOfChannels
                                miniAudioSampleRate:(ma_standard_sample_rate) sampleRate
{
   return( [MulleAudioDataSource dataSourceWithBytes:bytes
                                              length:length
                                     miniAudioFormat:format
                                    numberOfChannels:numberOfChannels
                                 miniAudioSampleRate:sampleRate]);
}


- (MulleAudioSound *) audioSoundWithAudioDataSource:(MulleAudioDataSource *) dataSource
{
   return( [MulleAudioSound soundWithAudioDataSource:dataSource
                                          audioEngine:self]);
}


- (MulleAudioSound *) audioSoundByCopyingAudioSound:(MulleAudioSound *) sound
{
   return( [MulleAudioSound soundWithAudioSound:sound]);
}


@end
