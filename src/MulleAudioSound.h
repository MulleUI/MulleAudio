#ifdef __has_include
# if __has_include( "NSObject.h")
#  import "NSObject.h"
# endif
#endif

#import "import.h"

#include "miniaudio.h"


@class MulleAudioEngine;
@class MulleAudioSound;
@class MulleAudioDataSource;

@protocol MulleAudioSoundDelegate

@optional
- (void) audioSoundDidStop:(MulleAudioSound *) sound;

@end


//
// Objective-C interface over ma_sound with slight abstractions
//
// Uses mulle_relativetime_t instead of ms
// Uses mulle_absolutetime_t for start/stop
//
// No real support for spatial sounds (use -miniAudioSound) to get the
// ma_sound to play around with it.
//
// This class is as thread safe as ma_sound is, so declared as such
//
// The MulleAudioEngine probably needs to maintain an array of
// sounds and finalize them when it finalizes (like a UIView->subview thing)
//
@interface MulleAudioSound : NSObject < MulleObjCThreadSafe>
{
   ma_sound               *_sound;
   ma_sound                _sound_space;

   mulle_atomic_id_t      _atomicDelegate;
   MulleAudioDataSource   *_audioDataSource;
}

// TODO: delegate is not atomic though, change only when sound is not
//       playing..
@property( dynamic, assign) id <MulleAudioSoundDelegate>   delegate   MULLE_OBJC_THREADSAFE_PROPERTY;
@property( assign) MulleAudioEngine                 *audioEngine;
@property( readonly) BOOL                           didStop;
@property( readonly, getter=isStreaming) BOOL       streaming;

@property( assign) char                             *nameUTF8String;
@property( assign, readonly) char                   *pathUTF8String;
@property( assign, readonly) mulle_relativetime_t   sampleRate;


- (BOOL) isResourceManaged;  // tentative here, probably gone soon ?

// write only
- (void) setStartTime:(mulle_absolutetime_t) startTime;
- (void) setStopTime:(mulle_absolutetime_t) stopTime;

- (void) setFadeIn:(mulle_relativetime_t) time
       startVolume:(float) startVolume
         endVolume:(float) endVolume;

// volume
@property( dynamic, assign) float   volume;   // 0.0 to 1.0 and beyond!
@property( dynamic, assign) float   gainDB;   // same as volume, just decibel scale

// stereo positioning
@property( dynamic, assign) float   balance;  // -1.0 to 1.0
@property( dynamic, assign) float   pan;      // -1.0 to 1.0, use either pan or balance not both

@property( dynamic, assign) float   pitch;

@property( dynamic, assign) mulle_relativetime_t     seek;
@property( dynamic, assign, getter=isLooping) BOOL   loop;

// 3D sound
@property( dynamic, assign) ma_vec3f   velocityVector;
@property( dynamic, assign) ma_vec3f   positionVector;
@property( dynamic, assign, getter=isSpatializationEnabled) BOOL   spatializationEnabled;

- (instancetype) initWithStreamingContentsOfFileUTF8String:(char *) path
                                               audioEngine:(MulleAudioEngine *) audioEngine;

// streams using resource manager
- (instancetype) initWithContentsOfFileUTF8String:(char *) soundFilePath
                                      audioEngine:(MulleAudioEngine *) audioEngine;

// copying another sound
- (MulleAudioSound *) initWithAudioSound:(MulleAudioSound *) other;


// lowlevel and designated
// don't use thes usually
- (instancetype) initWithMiniAudioSound:(ma_sound *) sound
                            audioEngine:(MulleAudioEngine *) audioEngine
                         pathUTF8String:(char *) path
                            isStreaming:(BOOL) isStreaming;

- (instancetype) initWithContentsOfFileUTF8String:(char *) soundFilePath
                                      audioEngine:(MulleAudioEngine *) audioEngine
                                   miniAudioFlags:(NSUInteger) flags;


- (instancetype) initWithAudioDataSource:(MulleAudioDataSource *) dataSource
                             audioEngine:(MulleAudioEngine *) audioEngine;

- (ma_sound *) miniAudioSound;


- (BOOL) isPlaying;
- (mulle_relativetime_t) duration;

// with MulleAudioSound we try to stay technical and close to how miniaudio
// calls it. With MulleAudio we abstract things into more common terms and
// operations for play control.

// play control
- (BOOL) start;
- (void) stop;
- (void) fadeOut:(mulle_relativetime_t) time;

// a shabby busy wait for completion in tests
- (void) waitForCompletion;

// conveniences
- (float) gainDB; // same as volume but in Decibel
- (void) setGainDB:(float) db;


@end

