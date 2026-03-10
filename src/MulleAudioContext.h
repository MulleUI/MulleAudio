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



@class MulleAudioDeviceInfoEnumerator;
@class MulleAudioEngineEnumerator;

@class MulleAudioEngine;
@class MulleAudioDevice;

//
// The MulleAudioContext manages a single ma_context there should be only
// one per app AFAIK. But not a shared instance coz it will dangle off
// MulleAudio which is a sharedInstance. The AudioContext also has the
// resourceManager that is shared across engines.
//
@interface MulleAudioContext : NSObject < NSFastEnumeration>
{
   ma_context           _context;
   ma_result            _context_state;
   struct mulle_array   _engines;

   ma_resource_manager  _resource_manager;
   ma_result            _resource_manager_state;
}

@property( assign) NSUInteger    playbackSampleRateHZ;
@property( assign) NSUInteger    playbackChannels;
@property( assign) NSUInteger    playbackSampleType;

- (ma_context *) miniAudioContext;
- (ma_resource_manager *) miniAudioResourceManager;

// you usually want an engine not a device
- (MulleAudioEngine *) defaultAudioEngine;

- (MulleAudioEngine *) audioEngineWithMiniAudioEngineConfig:(ma_engine_config *) config
                                                audioDevice:(MulleAudioDevice *) device;

- (MulleAudioDevice *) audioDeviceWithMiniAudioDeviceConfig:(ma_device_config *) config;

- (MulleAudioDeviceInfoEnumerator *) enumerateMiniAudioPlaybackDeviceInfos;
- (MulleAudioDeviceInfoEnumerator *) enumerateMiniAudioCaptureDeviceInfos;

// you can also do a for( audioEngine in audioContext) which is nicer
- (MulleAudioEngineEnumerator *) enumerateAudioEngines;

//
// this is not a ma_device_info as returned by the enumerators, but a config
// you can pass to -audioDeviceWithMiniAudioDeviceConfig:
//
- (BOOL) getDefaultMiniAudioPlaybackDeviceConfig:(ma_device_config *) config;
- (BOOL) getDefaultMiniAudioCaptureDeviceConfig:(ma_device_config *) config;

- (BOOL) getDefaultMiniAudioDeviceConfig:(ma_device_config *) config
                    miniAudioDeviceType:(ma_device_type) type;

@end



// typedef struct
// {
//     /* Basic info. This is the only information guaranteed to be filled in during device enumeration. */
//     ma_device_id id;
//     char name[MA_MAX_DEVICE_NAME_LENGTH + 1];   /* +1 for null terminator. */
//     ma_bool32 isDefault;
//
//     ma_uint32 nativeDataFormatCount;
//     struct
//     {
//         ma_format format;       /* Sample format. If set to ma_format_unknown, all sample formats are supported. */
//         ma_uint32 channels;     /* If set to 0, all channels are supported. */
//         ma_uint32 sampleRate;   /* If set to 0, all sample rates are supported. */
//         ma_uint32 flags;        /* A combination of MA_DATA_FORMAT_FLAG_* flags. */
//     } nativeDataFormats[/*ma_format_count * ma_standard_sample_rate_count * MA_MAX_CHANNELS*/ 64];  /* Not sure how big to make this. There can be *many* permutations for virtual devices which can support anything. */
// } ma_device_info;


//
// this is not an object enumerators, therefore you can't do for in
// and there is no NSEnumerator protocol
//
@interface MulleAudioDeviceInfoEnumerator : NSObject
{
   ma_device_info   *_infos;
   ma_uint32        _i;
   ma_uint32        _count;
}

@property( retain, readonly) MulleAudioContext   *audioContext;


- (instancetype) initPlaybackDeviceEnumeratorWithAudioContext:(MulleAudioContext *) audioContext;
- (instancetype) initCaptureDeviceEnumeratorWithAudioContext:(MulleAudioContext *) audioContext;

- (ma_device_info *) nextMiniAudioDeviceInfo;

@end


@interface MulleAudioEngineEnumerator : NSObject
{
   struct mulle_array    *_engines;
   ma_uint32             _i;
   ma_uint32             _count;
}
@property( retain, readonly) MulleAudioContext   *audioContext;

- (instancetype) initAudioEngineEnumeratorWithAudioContext:(MulleAudioContext *) audioContext;
- (id) nextObject;

@end
