//
//  MulleAudioDevice.h
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
@class MulleAudioEngine;

//
// the "engine" is playing on a "device", the "device" is part of the
// "context". The "context" is really just useful for "device" discovery
// and management, though you can not have a "device" serving two
// engines...
// The "MulleAudioDevice" object is retained by the engine. You often don't
// need to use this explicitly, as the engine will set up a device by
// default.
//
@interface MulleAudioDevice : NSObject < MulleObjCThreadSafe>
{
   ma_device   *_device;
   ma_device   _device_space;
}

+ (instancetype) deviceWithMiniAudioDevice:(ma_device *) device
                              audioContext:(MulleAudioContext *) audioContext;

@property( assign, readonly) MulleAudioContext   *audioContext;
// do not set this yourself
@property( assign) MulleAudioEngine              *audioEngine;

- (ma_device *) miniAudioDevice;


- (id) initWithMiniAudioDeviceConfig:(ma_device_config *) config
                        audioContext:(MulleAudioContext *) audioContext;

- (instancetype) initWithMiniAudioDevice:(ma_device *) device
                            audioContext:(MulleAudioContext *) audioContext;

- (BOOL) isRunning;

- (BOOL) start;
- (void) stop;

- (char *) UTF8String;
- (char *) statusUTF8String;

- (BOOL) ownsMiniAudioDevice;

@end
