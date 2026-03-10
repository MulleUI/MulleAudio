#import "MulleAudioContext.h"

#import "import-private.h"

#import "MulleAudioContext+Private.h"
#import "MulleAudioDevice.h"
#import "MulleAudioEngine.h"
#import <MulleObjC/NSDebug.h>


@implementation MulleAudioContext

- (instancetype) init
{
   struct mulle_allocator  *allocator;

   _context_state = ma_context_init( NULL, 0, NULL, &_context);
   if( _context_state != MA_SUCCESS)
   {
      [self release];
      return( nil);
   }

   // empty so far
   _resource_manager_state = MA_ERROR;
   _playbackSampleType     = ma_format_f32;
   _playbackChannels       = 2;
   _playbackSampleRateHZ   = ma_standard_sample_rate_48000;

   allocator = MulleObjCInstanceGetAllocator( self);
   mulle_array_init( &_engines, 0, &MulleObjCContainerRetainKeyCallback, allocator);

   return( self);
}


- (void) finalize
{
   MulleAudioEngine    *audioEngine;
   struct mulle_array  copy;

   copy = _engines;

   // engines who remove themselves, will just not find themselves
   mulle_array_init( &_engines, 0, _engines.callback, _engines.allocator);

   // audio engines will remove themselves from _engines
   // so operate on a copy
   mulle_array_for( &copy, audioEngine)
   {
      [audioEngine mullePerformFinalize];
   }

   // now this sends a release to all the engines
   mulle_array_done( &copy);

   // ensure no new engines suddenly appeared
   assert( mulle_array_get_count( &_engines) == 0);

   [super finalize];
}


- (void) dealloc
{
   if( _resource_manager_state == MA_SUCCESS)
   {
      ma_resource_manager_uninit( &_resource_manager);
      if( NSDebugEnabled)
         mulle_fprintf( stderr, "miniaudio resoure manager uninit\n");
   }

   if( _context_state == MA_SUCCESS)
   {
      ma_context_uninit( &_context);
      if( NSDebugEnabled)
         mulle_fprintf( stderr, "miniaudio context uninit\n");
   }
   [super dealloc];
}


- (void) _addEngine:(MulleAudioEngine *) engine
{
   assert( ! [self mulleIsFinalized]);

   mulle_array_add( &_engines, engine);
}


- (void) _removeEngine:(MulleAudioEngine *) engine
{
   mulle_array_remove( &_engines, engine);
}


- (struct mulle_array *) _engines
{
   return( &_engines);
}



- (MulleAudioEngine *) audioEngineWithMiniAudioEngineConfig:(ma_engine_config *) config
                                                audioDevice:(MulleAudioDevice *) audioDevice
{
   MulleAudioEngine   *engine;

   engine = [MulleAudioEngine alloc];
   engine = [engine initWithMiniAudioEngineConfig:config
                                     audioContext:self
                                      audioDevice:audioDevice];
   engine = [engine autorelease];

   return( engine);
}


- (MulleAudioEngine *) defaultAudioEngine
{
   MulleAudioEngine   *engine;

   engine = [self audioEngineWithMiniAudioEngineConfig:NULL
                                           audioDevice:nil];
   return( engine);
}


//
// devices
//

- (MulleAudioDevice *) audioDeviceWithMiniAudioDeviceConfig:(ma_device_config *) config
{
   MulleAudioDevice   *device;

   device = [MulleAudioDevice alloc];
   device = [device initWithMiniAudioDeviceConfig:config
                                     audioContext:self];
   device = [device autorelease];
   return( device);
}




- (MulleAudioDeviceInfoEnumerator *) enumerateMiniAudioPlaybackDeviceInfos;
{
   MulleAudioDeviceInfoEnumerator   *rover;

   rover = [MulleAudioDeviceInfoEnumerator alloc];
   rover = [rover initPlaybackDeviceEnumeratorWithAudioContext:self];
   rover = [rover autorelease];
   return( rover);
}


- (MulleAudioDeviceInfoEnumerator *) enumerateMiniAudioCaptureDeviceInfos
{
   MulleAudioDeviceInfoEnumerator   *rover;

   rover = [MulleAudioDeviceInfoEnumerator alloc];
   rover = [rover initCaptureDeviceEnumeratorWithAudioContext:self];
   rover = [rover autorelease];
   return( rover);
}


- (MulleAudioEngineEnumerator *) enumerateAudioEngines
{
   MulleAudioEngineEnumerator   *rover;

   rover = [MulleAudioEngineEnumerator alloc];
   rover = [rover initAudioEngineEnumeratorWithAudioContext:self];
   rover = [rover autorelease];
   return( rover);
}


- (ma_resource_manager *) miniAudioResourceManager
{
   ma_resource_manager_config   config;

   if( _resource_manager_state == MA_SUCCESS)
      return( &_resource_manager);

    // Initialize the resource manager configuration.
   config                   = ma_resource_manager_config_init();
   // how we want loaded waves decoded
   config.decodedFormat     = [self playbackSampleType];
   config.decodedChannels   = [self playbackChannels];
   config.decodedSampleRate = [self playbackSampleRateHZ];

    // Initialize the resource manager.
    _resource_manager_state = ma_resource_manager_init( &config, &_resource_manager);
    if( _resource_manager_state != MA_SUCCESS) 
      return( NULL);

   return( &_resource_manager);
}


- (ma_context *) miniAudioContext
{
   return( &_context);
}


- (NSUInteger) count
{
   NSUInteger           length;
   struct mulle_array   *array;

   array  = &_engines;
   length = mulle_array_get_count( array);
   return( length);
}


- (NSUInteger) countByEnumeratingWithState:(NSFastEnumerationState *) state
                                   objects:(id *) objects
                                     count:(NSUInteger) count
{
   NSUInteger           length;
   struct mulle_range   range;
   struct mulle_array   *array;

   array  = &_engines;
   length = mulle_array_get_count( array);

   // Check if the enumeration has just started
   if( state->state == 0)
   {
      // Initialize the state
      state->mutationsPtr = (NSUInteger *) &array->_curr;
      state->extra[ 0]    = 0; // Position in the array
   }

   // Get the current position in the array

   // Calculate the number of elements to copy
   range.location = state->extra[ 0];
   range.length   = length - range.location;
   if( range.length > count)
      range.length = count;

   if( range.length)
   {
      mulle_array_get_in_range( array, range, objects);

      // Update the state
      state->itemsPtr  = objects;
      state->state    += count;
      state->extra[ 0] = range.location + range.length;
   }
   else
   {
     // No more elements to enumerate
     state->itemsPtr = NULL;
     state->state    = 0;
   }

   return( count);
}


- (BOOL) getDefaultMiniAudioDeviceConfig:(ma_device_config *) config
                     miniAudioDeviceType:(ma_device_type) type
{
   ma_uint32        i;
   ma_uint32        play_count;
   ma_device_info   *play_infos;
   ma_uint32        capture_count;
   ma_device_info   *capture_infos;

   if( ! config)
      return( NO);

   *config = ma_device_config_init( type);

   if( ma_context_get_devices( [self miniAudioContext], &play_infos, &play_count, &capture_infos, &capture_count) != MA_SUCCESS)
   {
      errno = EINVAL;
      return( NO);
   }

   if( type & ma_device_type_playback)
   {
      // config->playback.format   = ma_format_f32;
      // config->playback.channels = 2;
      // config->sampleRate        = ma_standard_sample_rate_48000;

      for( i = 0; i < play_count; i++)
         if( play_infos[ i].isDefault)
         {
            config->playback.pDeviceID = &play_infos[ i].id;
            break;
         }
   }

   if( type & ma_device_type_capture)
   {
      //config->capture.format   = ma_format_s16;
      //config->capture.channels = 2;
      //config->sampleRate       = ma_standard_sample_rate_48000;

      for( i = 0; i < capture_count; i++)
         if( capture_infos[ i].isDefault)
         {
            config->capture.pDeviceID = &capture_infos[ i].id;
            break;
         }
   }

   // not sure what to do for loopback
   return( YES);
}



- (BOOL) getDefaultMiniAudioPlaybackDeviceConfig:(ma_device_config *) config
{
   return( [self getDefaultMiniAudioDeviceConfig:config
                             miniAudioDeviceType:ma_device_type_playback]);
}


- (BOOL) getDefaultMiniAudioCaptureDeviceConfig:(ma_device_config *) config
{
   return( [self getDefaultMiniAudioDeviceConfig:config
                             miniAudioDeviceType:ma_device_type_capture]);
}

@end



@implementation MulleAudioDeviceInfoEnumerator

- (instancetype) initPlaybackDeviceEnumeratorWithAudioContext:(MulleAudioContext *) audioContext
{
   if( ! audioContext)
   {
      [self release];
      return( nil);
   }

   if( ma_context_get_devices( [audioContext miniAudioContext], &_infos, &_count, NULL, NULL) != MA_SUCCESS)
   {
      [self release];
      return( nil);
   }

   _audioContext = [audioContext retain];
   return( self);
}


- (instancetype) initCaptureDeviceEnumeratorWithAudioContext:(MulleAudioContext *) audioContext
{
   if( ! audioContext)
   {
      [self release];
      return( nil);
   }

   if( ma_context_get_devices( [audioContext miniAudioContext], NULL, NULL, &_infos, &_count) != MA_SUCCESS)
   {
      [self release];
      return( nil);
   }
   _audioContext = [audioContext retain];
   return( self);
}


- (void) dealloc
{
   [_audioContext release];
   [super dealloc];
}


- (ma_device_info *) nextMiniAudioDeviceInfo
{
   if( _i >= _count)
      return( NULL);
   return( &_infos[ _i++]);
}


- (NSUInteger) count
{
   return( _count);
}


- (id) nextObject
{
   abort();
}

@end


@implementation MulleAudioEngineEnumerator

- (instancetype) initAudioEngineEnumeratorWithAudioContext:(MulleAudioContext *) audioContext
{
   if( ! audioContext)
   {
      [self release];
      return( nil);
   }

   _audioContext = [audioContext retain];
   _engines      = [audioContext _engines];
   return( self);
}


- (void) dealloc
{
   [_audioContext release];
   [super dealloc];
}


- (NSUInteger) count
{
   return( mulle_array_get_count( _engines));
}


- (id) nextObject
{
   if( _i >= mulle_array_get_count( _engines))
      return( NULL);
   return( mulle_array_get( _engines, _i));
}


@end
