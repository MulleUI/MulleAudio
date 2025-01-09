#import "MulleAudioSound.h"

#import "import-private.h"

#import "MulleAudioEngine.h"
#import "MulleAudioEngine+Private.h"
#import "MulleAudioDataSource.h"


@implementation MulleAudioSound

static void   on_sound_end( void* pUserData, ma_sound* pSound)
{
   MulleAudioSound                *self = pUserData;
   id <MulleAudioSoundDelegate>   delegate;

   //
   // this is called by the miniaudio thread which plays the audio, which is
   // not a MulleObjC thread, therefore we can not just call Objective-C code
   // willy nilly, but have to do "MulleThreadGetOrCreateCurrentThread"
   // beforehand.
   // Ensure that the Objective-C methods you are calling are threadSafe
   // though TAO will do this for you
   if( MulleThreadGetOrCreateCurrentThread() == NULL)
   {
      mulle_fprintf( stderr, "argh\n");
      exit( 1);
   }

   delegate = [self delegate];
   [delegate audioSoundDidStop:self];

   // do this _after_ delegate otherwise our lame busy
   // waiter may preempt to early
   self->_didStop = YES;
}


- (instancetype) initWithMiniAudioSound:(ma_sound *) sound
                            audioEngine:(MulleAudioEngine *) audioEngine
                        pathUTF8String:(char *) path
                            isStreaming:(BOOL) isStreaming
{
   char         *name;
   char         *dot;
   ma_uint32    sampleRate;

   if( ! audioEngine || ! sound) 
   {
      [self release];
      return( nil);
   }

   self = [super init];
   if( ! self)
      return( self);

   if( path)
   {
      MulleObjCObjectSetDuplicatedUTF8String( self, &_pathUTF8String, path);
#ifdef __WIN32
      name = strrchr( path, '/');
#else         
      name = strrchr( path, '\\');
#endif         
      name = name ? name + 1 : path;
      dot  = strchr( name, '.');
      dot  = dot ? dot : &name[ strlen( name)];
      name = MulleObjC_asprintf( "%.*s", dot - name, name);
      MulleObjCObjectSetDuplicatedUTF8String( self, &_nameUTF8String, name);
   }

   _audioEngine = [audioEngine retain];
   [_audioEngine _addSound:self];

   _sound       = sound;
   _streaming   = isStreaming;

   ma_sound_get_data_format( _sound, NULL, NULL, &sampleRate, NULL, 0);
   assert( sampleRate);
   _sampleRate  = 1.0 / sampleRate;

   ma_sound_set_end_callback( sound, on_sound_end, self);
   return( self);
}


//
- (instancetype) initWithContentsOfFileUTF8String:(char *) path
                                      audioEngine:(MulleAudioEngine *) audioEngine
                                   miniAudioFlags:(NSUInteger) flags
{
   ma_result   result;

   result = ma_sound_init_from_file( [audioEngine miniAudioEngine],
                                     path,
                                     flags,
                                     NULL,
                                     NULL,
                                     &_sound_space);
   if( result != MA_SUCCESS) 
   {
      [self release];
      return( nil);
   }

   return( [self initWithMiniAudioSound:&_sound_space
                            audioEngine:audioEngine
                         pathUTF8String:path
                            isStreaming:flags & MA_SOUND_FLAG_STREAM ? YES : NO]);
}

- (instancetype) initWithContentsOfFileUTF8String:(char *) path
                                      audioEngine:(MulleAudioEngine *) audioEngine
{
   return( [self initWithContentsOfFileUTF8String:path
                                      audioEngine:audioEngine
                                   miniAudioFlags:0]);
}

- (instancetype) initWithStreamingContentsOfFileUTF8String:(char *) path
                                               audioEngine:(MulleAudioEngine *) audioEngine
{
   return( [self initWithContentsOfFileUTF8String:path
                                      audioEngine:audioEngine
                                   miniAudioFlags:MA_SOUND_FLAG_STREAM]);
}


- (instancetype) initWithAudioDataSource:(MulleAudioDataSource *) dataSource
                             audioEngine:(MulleAudioEngine *) audioEngine
{
   ma_result   result;

   if( ! dataSource)
   {
      [self release];
      return( nil);
   }

   // Initialize a sound from the data source
   result = ma_sound_init_from_data_source( [audioEngine miniAudioEngine],
                                            [dataSource miniAudioDataSource],
                                            0,
                                            NULL,
                                            &_sound_space);
   if (result != MA_SUCCESS)
   {
      [self release];
      return( nil);
   }

   _audioDataSource = [dataSource retain];

   return( [self initWithMiniAudioSound:&_sound_space
                            audioEngine:audioEngine
                         pathUTF8String:NULL
                            isStreaming:NO]);
}

- (void) finalize
{
   [_audioEngine _removeSound:self];

   // stop it, but it's managed by the resource manager
   if( _sound)
   {
      ma_sound_set_end_callback( _sound, 0, 0);  // dont want no callback in finalize
      ma_sound_stop( _sound);
   }

   if( _sound == &_sound_space)
   {
      ma_sound_uninit( _sound);
      _sound = NULL;
   }

   [_audioEngine autorelease];
   _audioEngine = nil;


   [super finalize];
}


- (void) dealloc 
{
   [_audioDataSource release];

   MulleObjCObjectSetDuplicatedUTF8String( self, &_nameUTF8String, NULL);
   MulleObjCObjectSetDuplicatedUTF8String( self, &_pathUTF8String, NULL);

   [super dealloc];
}


- (ma_sound *) miniAudioSound
{
   return( _sound);
}


- (char *) nameUTF8String
{
   return( _nameUTF8String);
}


- (void) setNameUTF8String:(char *) s
{
   MulleObjCObjectSetDuplicatedUTF8String( self, &_nameUTF8String, s);
}


- (char *) pathUTF8String
{
   return( _pathUTF8String);
}


- (id <MulleAudioSoundDelegate>) delegate
{
   return( MulleObjCAtomicIdGet( &_atomicDelegate));
}


- (void) setDelegate:(id <MulleAudioSoundDelegate>) delegate
{
   MulleObjCAtomicIdSetAssign( &_atomicDelegate, delegate);
}
// 


- (BOOL) start
{
   assert( _audioEngine);
   _didStop = NO;
   return( ma_sound_start( _sound) == MA_SUCCESS);
}


- (void) stop
{
   ma_sound_stop( _sound);
}


// ma_sound_stop_with_fade_in_milliseconds: Stops the sound with a fade-out effect.
- (void) fadeOut:(mulle_relativetime_t) time
{
   ma_sound_stop_with_fade_in_milliseconds( _sound, (ma_uint64) time * 1000.0);
}



- (BOOL) isPlaying
{
   return( ma_sound_is_playing( _sound));
}


- (BOOL) isResourceManaged
{
   return( [_audioEngine miniAudioResourceManager] != NULL);
}



- (void) waitForCompletion
{
   while( ! _didStop) // [self isPlaying])
   {
      mulle_thread_yield();
   }
}


- (MulleAudioSound *) mutableCopy
{
   ma_result         result;
   MulleAudioSound   *copy;
   char              *name;

   // can't ma_sound_init_copy streaming sounds
   copy = [[self class] alloc];
   if( _streaming)
   {
      copy = [copy initWithStreamingContentsOfFileUTF8String:_pathUTF8String
                                                 audioEngine:_audioEngine];
   }
   else
   {
      // Cloning only works for data buffers (not streams) that are loaded from
      // the resource manager
      result = ma_sound_init_copy( [_audioEngine miniAudioEngine], _sound, 0, NULL, &copy->_sound_space);
      if( result != MA_SUCCESS)
      {
         [copy release];
         return( nil);
      }

      copy = [copy initWithMiniAudioSound:&_sound_space
                              audioEngine:_audioEngine
                           pathUTF8String:_pathUTF8String
                              isStreaming:NO];
      // if sharing a dataSource retain it
      copy->_audioDataSource = [_audioDataSource retain];
   }


   // MEMO: need to change the name here to ... lets just wipe it for now
   name = NULL;   // wipe name unless..
   if( _nameUTF8String)
      name = MulleObjC_asprintf( "Copy of %s", _nameUTF8String);
   [copy setNameUTF8String:name];

   return( copy);
}


// ma_sound_set_end_callback: Sets a callback that is triggered when the sound finishes playing.
// ma_sound_start: Starts playing the sound.
// ma_sound_stop: Stops the sound playback.

// ma_sound_set_volume: Sets the volume of the sound.
- (void) setVolume:(float) volume
{
   ma_sound_set_volume( _sound, volume);
}


- (float) volume
{
   return( ma_sound_get_volume( _sound));
}


- (void) setGainDB:(float) gainDB
{
   ma_sound_set_volume( _sound, ma_volume_db_to_linear( gainDB));
}


- (float) gainDB
{
   return( ma_volume_linear_to_db( ma_sound_get_volume( _sound)));
}


// ma_sound_set_pan: Sets the panning of the sound.
- (void) setBalance:(float) balance
{
   ma_sound_set_pan_mode( _sound, ma_pan_mode_balance);
   ma_sound_set_pan( _sound, balance);
}


- (float) balance
{
   return( ma_sound_get_pan( _sound));
}


- (void) setPan:(float) pan
{
   ma_sound_set_pan_mode( _sound, ma_pan_mode_pan);
   ma_sound_set_pan( _sound, pan);
}

- (float) pan
{
   return( ma_sound_get_pan( _sound));
}


// ma_sound_set_pitch: Adjusts the pitch of the sound.
- (void) setPitch:(float) pitch
{
   ma_sound_set_pitch( _sound, pitch);
}


- (float) pitch
{
   return( ma_sound_get_pitch( _sound));
}


- (mulle_relativetime_t) seek
{
   ma_uint64   frameIndex;

   frameIndex = ma_sound_get_time_in_pcm_frames( _sound);
   return( frameIndex * _sampleRate);
}


- (void) setSeek:(mulle_relativetime_t) seek
{
   ma_uint64   frameIndex;

   frameIndex = (ma_uint64) (seek / _sampleRate);
   ma_sound_seek_to_pcm_frame( _sound, frameIndex);
}


- (mulle_relativetime_t) duration
{
   ma_uint64   frames;

   ma_sound_get_length_in_pcm_frames( _sound, &frames);
   return( frames * _sampleRate);
}


// ma_sound_set_looping: Enables or disables looping for the sound.
- (void) setLoop:(BOOL) flag
{
   ma_sound_set_looping( _sound, flag);
}


- (BOOL) isLooping
{
   return( ma_sound_is_looping( _sound));
}


// ma_sound_set_fade_in_milliseconds: Sets a fade-in effect for the sound.
// ma_sound_set_fade_in_pcm_frames: Similar to the above, but uses PCM frames.
- (void) setFadeIn:(mulle_relativetime_t) time
       startVolume:(float) startVolume
         endVolume:(float) endVolume
{
   ma_sound_set_fade_in_milliseconds( _sound, startVolume, endVolume, (ma_uint64) time * 1000.0);
}


// ma_sound_set_start_time_in_milliseconds: Sets the start time for playback.
- (void) setStartTime:(mulle_absolutetime_t) time
{
   ma_sound_set_start_time_in_milliseconds( _sound, (ma_uint64) time * 1000.0);
}


// ma_sound_set_stop_time_in_milliseconds: Sets the stop time for playback.
- (void) setStopTime:(mulle_absolutetime_t) time
{
   ma_sound_set_stop_time_in_milliseconds( _sound, (ma_uint64) time * 1000.0);
}


// ma_sound_set_velocity: Sets the velocity of the sound (for Doppler effect).
- (void) setVelocityVector:(ma_vec3f) v
{
   ma_sound_set_velocity( _sound, v.x, v.y, v.z);
}


- (ma_vec3f) velocityVector
{
   return( ma_sound_get_velocity( _sound));
}


// ma_sound_set_position: Sets the 3D position of the sound (for spatial audio).
- (void) setPositionVector:(ma_vec3f) v
{
   ma_sound_set_position( _sound, v.x, v.y, v.z);
}


- (ma_vec3f) positionVector
{
   return( ma_sound_get_position( _sound));
}


- (BOOL) isSpatializationEnabled
{
   return( ma_sound_is_spatialization_enabled( _sound));
}


- (void) setSpatializationEnabled:(BOOL) flag
{
   assert( _sound);
   ma_sound_set_spatialization_enabled( _sound, flag);
}

@end
