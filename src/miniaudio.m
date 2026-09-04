//
//  miniaudio.m
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
#ifndef NO_MINIAUDIO_IMPLEMENTATION
# define MINIAUDIO_IMPLEMENTATION
#endif

// #define MA_NO_WAV
// #define MA_NO_MP3
// #define MA_NO_FLAC

//
// On Apple platforms the miniaudio implementation pulls in the CoreAudio and
// AudioToolbox umbrella headers, which drag in Apple's Objective-C runtime
// headers (<objc/objc.h>). Those are hostile to mulle-objc (they redefine
// BOOL, add nullability to SEL, use ^blocks). So on APPLE this translation
// unit is compiled separately with Apple's stock clang (see
// cmake/PreLibrary.cmake) and MULLE_AUDIO_MINIAUDIO_STANDALONE is defined.
//
// In that standalone case we must NOT include mulle-c11's BOOL definition,
// because it would clash with Apple's `typedef signed char BOOL` inside this
// very same translation unit. miniaudio's public API only uses ma_bool8 /
// ma_bool32 (== ma_uint8 / ma_uint32), so the resulting object file is ABI
// compatible with the mulle-clang compiled callers regardless of BOOL.
//
#ifndef MULLE_AUDIO_MINIAUDIO_STANDALONE
# include <mulle-c11/mulle-c11.h>
#endif

#include "miniaudio.h"
