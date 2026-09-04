//
//  MulleAudioEngine.h
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


@class MulleAudioContext;
@class MulleAudioDataSource;
@class MulleAudioDevice;
@class MulleAudioSound;


// the basic design is:
//
// Context => Engine -> Device
//             ^
//             ||
//            Sound
//
// So a Context owns the engines, each engine has a device. A sound
// owns the engine. When the engine is finalized, all sounds are finalized.
// When the context finalizes, all engines finalize.
//
struct MulleAudioRecordingTap;

@interface MulleAudioEngine : NSObject < MulleObjCThreadSafe>
{
   struct ma_engine               *_engine;
   struct ma_engine               _engine_space;

   struct mulle_pointerarray      _sounds;
   struct MulleAudioRecordingTap  *_recordingTap;
}

- (struct ma_engine *)    miniAudioEngine;
- (ma_resource_manager *) miniAudioResourceManager;

@property( readonly, assign) MulleAudioContext   *audioContext;
@property( readonly, retain) MulleAudioDevice    *audioDevice;

@property( dynamic, readonly, getter = isRunning) BOOL  running;

+ (instancetype) engineWithMiniAudioEngineConfig:(ma_engine_config *) config
                                     audioContext:(MulleAudioContext *) audioContext
                                      audioDevice:(MulleAudioDevice *) audioDevice;

- (instancetype) initWithMiniAudioEngineConfig:(ma_engine_config *) config
                                  audioContext:(MulleAudioContext *) audioContext
                                   audioDevice:(MulleAudioDevice *) audioDevice;
- (instancetype) initWithMiniAudioEngine:(ma_engine *) engine
                            audioContext:(MulleAudioContext *) audioContext
                             audioDevice:(MulleAudioDevice *) audioDevice;

- (MulleAudioSound *) audioSoundWithContentsOfFileUTF8String:(char *) path;

- (MulleAudioSound *) audioSoundWithBytes:(void *) bytes
                                   length:(NSUInteger) length
                          miniAudioFormat:(ma_format) format
                         numberOfChannels:(NSInteger) numberOfChannels
                      miniAudioSampleRate:(ma_standard_sample_rate) sampleRate;

- (MulleAudioDataSource *) audioDataSourceWithBytes:(void *) bytes
                                             length:(NSUInteger) length
                                    miniAudioFormat:(ma_format) format
                                   numberOfChannels:(NSInteger) numberOfChannels
                                miniAudioSampleRate:(ma_standard_sample_rate) sampleRate;

- (MulleAudioSound *) audioSoundWithAudioDataSource:(MulleAudioDataSource *) dataSource;

- (MulleAudioSound *) audioSoundByCopyingAudioSound:(MulleAudioSound *) sound;

@end
