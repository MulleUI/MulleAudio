//
//  MulleAudioDevice.m
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
#import "MulleAudioDevice.h"

#import "import-private.h"

#import "MulleAudioContext.h"
#import "MulleAudioContext+Private.h"
#import <MulleObjC/NSDebug.h>


@implementation MulleAudioDevice

- (id) initWithMiniAudioDevice:(ma_device *) device
                  audioContext:(MulleAudioContext *) audioContext
{
   //
   // for "convenience" just create an engine, and use the MulleAudioDevice
   // from it
   //
   if( ! device || ! audioContext)
   {
      [self release];
      return( nil);
   }

   self = [super init];
   if( self)
   {
      _audioContext = audioContext;
      _device       = device;
   }
   return( self);
}


- (id) initWithMiniAudioDeviceConfig:(ma_device_config *) config
                        audioContext:(MulleAudioContext *) audioContext
{
   ma_result          device_state;
   ma_device_config   device_config;

   if( ! config)
   {
      device_config = ma_device_config_init( ma_device_type_playback|ma_device_type_capture);
      config        = &device_config;
   }

   device_state = ma_device_init( [audioContext miniAudioContext], config, &_device_space);
   if( device_state != MA_SUCCESS)
   {
      [self release];
      return( nil);
   }

   return( [self initWithMiniAudioDevice:&_device_space
                            audioContext:audioContext]);
}


- (BOOL) start
{
   assert( ! _audioEngine);
   return( ma_device_start( _device) == MA_SUCCESS);     // The device is sleeping by default so you'll need to start it manually.
}


- (void) stop
{
   assert( ! _audioEngine);
   if( ma_device_get_state( _device) == ma_device_state_started)
      ma_device_stop( _device);     
}


- (BOOL) isRunning
{
   return( ma_device_is_started( _device));
}


- (void) finalize
{
   // only uninit if ours
   if( _device == &_device_space)
   {
      // otherwise we run into an assert in miniaudio
      if( ma_device_get_state( _device) == ma_device_state_started)
         ma_device_stop( _device);
      ma_device_uninit( _device);
      if( NSDebugEnabled)
         mulle_fprintf( stderr, "miniaudio device uninit\n");

      _device = NULL;
   }

   // assign only
   _audioContext = nil;
   _audioEngine  = nil;

   [super finalize];
}


- (void) dealloc
{
   [super dealloc];
}


- (ma_device *) miniAudioDevice
{
   return( _device);
}


- (BOOL) ownsMiniAudioDevice
{
   return( _device == &_device_space);
}


- (char *) UTF8String
{
   ma_result       rval;
   char            name[ 128];
   char            *s;
   ma_device_type  type;

   type = ma_device_type_playback;
   rval = ma_device_get_name( _device, type, name, sizeof( name), NULL);
   if( rval != MA_SUCCESS || ! name[ 0])
   {
      type = ma_device_type_capture;
      rval = ma_device_get_name( _device, type, name, sizeof( name), NULL);
   }

   if( rval != MA_SUCCESS || ! name[ 0])
      return( "???");

   // convert to malloced string
   s = MulleObjC_strdup( name);
   return( s);
}


- (char *) statusUTF8String
{
   ma_result       rval;
   char            name[ 128];
   char            *s;
   ma_device_type  type;

   if( _device)
   {
      type = ma_device_type_playback;
      rval = ma_device_get_name( _device, type, name, sizeof( name), NULL);
      if( rval != MA_SUCCESS || ! name[ 0])
      {
         type = ma_device_type_capture;
         rval = ma_device_get_name( _device, type, name, sizeof( name), NULL);
      }

      if( rval == MA_SUCCESS && name[ 0])
      {
         s = MulleObjC_asprintf( "%s on \"%s\" is %s\n",
                                    type == ma_device_type_playback ? "Playback" : "Capture",
                                    name,
                                    ma_device_is_started( _device) ? "active" : "inactive");
         return( s);
      }
   }
   return( [super UTF8String]);
}


+ (instancetype) deviceWithMiniAudioDevice:(ma_device *) device
                              audioContext:(MulleAudioContext *) audioContext
{
   MulleAudioDevice   *audioDevice;

   audioDevice = [MulleAudioDevice alloc];
   audioDevice = [audioDevice initWithMiniAudioDevice:device
                                         audioContext:audioContext];
   audioDevice = [audioDevice autorelease];
   return( audioDevice);
}

@end
