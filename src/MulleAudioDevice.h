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
