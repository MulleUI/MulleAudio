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
      audioDevice = [[[MulleAudioDevice alloc] initWithMiniAudioDevice:device
                                                          audioContext:audioContext] autorelease];
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
   MulleAudioSound        *audioSound;
   MulleAudioDataSource   *audioDataSource;

   audioDataSource = [MulleAudioDataSource alloc];
   audioDataSource = [audioDataSource initWithBytes:bytes
                                             length:length
                                    miniAudioFormat:format
                                   numberOfChannels:numberOfChannels
                                miniAudioSampleRate:sampleRate];
   audioDataSource = [audioDataSource autorelease];

   audioSound = [MulleAudioSound alloc];
   audioSound = [audioSound initWithAudioDataSource:audioDataSource
                                        audioEngine:self];
   audioSound = [audioSound autorelease];

   return( audioSound);
}

@end