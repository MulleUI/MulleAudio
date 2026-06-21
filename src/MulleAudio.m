#import "MulleAudio.h"

#import "import-private.h"

#import "MulleAudioContext.h"
#import "MulleAudioEngine.h"
#import "MulleAudioDevice.h"
#import "MulleAudioSound.h"
#import <MulleObjC/NSDebug.h>


@implementation MulleAudio

- (instancetype) init
{
   _audioContext             = [MulleAudioContext new];

   _numberOfForegroundVoices = 8;
   _numberOfBackgroundVoices = 2;

   _defaultForegroundVolume  = 0.8f;
   _defaultBackgroundVolume  = 0.5f;

   return( self);
}


- (void) dealloc
{
   NSUInteger               i;
   struct mulle_allocator   *allocator;

   allocator = MulleObjCInstanceGetAllocator( self);

   // super pedantic ?
   if( _foregroundVoices)
   {
      for( i = 0; i < _numberOfForegroundVoices; i++)
         [_foregroundVoices[ i].audioSound release];
      mulle_allocator_free( allocator, _foregroundVoices);
      _foregroundVoices = NULL;
   }

   if( _backgroundVoices)
   {
      for( i = 0; i < _numberOfBackgroundVoices; i++)
         [_backgroundVoices[ i].audioSound release];
      mulle_allocator_free( allocator, _backgroundVoices);
      _backgroundVoices = NULL;
   }

   [_audioContext release];

   [super dealloc];
}


- (void) finalize
{
   struct mulle_allocator   *allocator;
   NSUInteger               i;

   if( NSDebugEnabled)
      mulle_fprintf( stderr, "MulleAudio finalize\n");

   allocator = MulleObjCInstanceGetAllocator( self);
   if( _foregroundVoices)
   {
      for( i = 0; i < _numberOfForegroundVoices; i++)
      {
         [_foregroundVoices[ i].audioSound mullePerformFinalize];
         [_foregroundVoices[ i].audioSound autorelease];
      }
      mulle_allocator_free( allocator, _foregroundVoices);
      _foregroundVoices = NULL;
   }

   [_audioContext mullePerformFinalize];
   [super finalize];
}



- (MulleAudioEngine *) audioEngine
{
   // engine is retained by audio context
   if( ! _audioEngine)
      _audioEngine  = [_audioContext defaultAudioEngine];
   return( _audioEngine);
}


- (void) setAudioEngine:(MulleAudioEngine *) audioEngine
{
   if( _audioEngine && audioEngine)
      MulleObjCThrowInternalInconsistencyExceptionUTF8String( "can't change a running system");

   // nil can happen during -finalize
   // if( ! _audioEngine)
   //    MulleObjCThrowInternalInconsistencyExceptionUTF8String( "have no use for nil engine");

   assert( ! audioEngine || [audioEngine audioContext] == _audioContext);

   // engine is retained by audio context
   _audioEngine = audioEngine;
}


- (void) setNumberOfForegroundVoices:(NSUInteger) n
{
   if( _foregroundVoices && n)
      MulleObjCThrowInternalInconsistencyExceptionUTF8String( "can't change a running system");
   _numberOfForegroundVoices = n;
}


- (void) setNumberOfBackgroundVoices:(NSUInteger) n
{
   if( _backgroundVoices && n)
      MulleObjCThrowInternalInconsistencyExceptionUTF8String( "can't change a running system");
   _numberOfBackgroundVoices = n;
}



- (MulleAudioDeviceInfoEnumerator *) enumerateMiniAudioPlaybackDeviceInfos
{
   return( [_audioContext enumerateMiniAudioPlaybackDeviceInfos]);
}


- (MulleAudioDeviceInfoEnumerator *) enumerateMiniAudioCaptureDeviceInfos
{
   return( [_audioContext enumerateMiniAudioCaptureDeviceInfos]);
}


static struct MulleAudioVoice  *MulleAudioGetForegroundVoices( MulleAudio *self)
{
   struct mulle_allocator   *allocator;
   struct MulleAudioVoice   *p;
   struct MulleAudioVoice   *sentinel;

   if( self->_foregroundVoices || ! self->_numberOfForegroundVoices)
      return( self->_foregroundVoices);

   allocator = MulleObjCInstanceGetAllocator( self);
   self->_foregroundVoices = mulle_allocator_calloc( allocator,
                                                     self->_numberOfForegroundVoices,
                                                     sizeof( struct MulleAudioVoice));

   sentinel = &self->_foregroundVoices[ self->_numberOfForegroundVoices];
   for( p = self->_foregroundVoices; p < sentinel; p++)
   {
      p->volume = self->_defaultForegroundVolume;
      p->pan    = 0.0;
      p->pitch  = 1.0;
   }
   return( self->_foregroundVoices);
}


static struct MulleAudioVoice  *MulleAudioGetBackgroundVoices( MulleAudio *self)
{
   struct mulle_allocator   *allocator;
   struct MulleAudioVoice   *p;
   struct MulleAudioVoice   *sentinel;

   if( self->_backgroundVoices || ! self->_numberOfBackgroundVoices)
      return( self->_backgroundVoices);

   allocator = MulleObjCInstanceGetAllocator( self);
   self->_backgroundVoices = mulle_allocator_calloc( allocator,
                                                     self->_numberOfBackgroundVoices,
                                                     sizeof( struct MulleAudioVoice));

   sentinel = &self->_backgroundVoices[ self->_numberOfBackgroundVoices];
   for( p = self->_backgroundVoices; p < sentinel; p++)
   {
      p->volume = self->_defaultBackgroundVolume;
      p->pan    = 0.0;
      p->pitch  = 1.0;
   }

   return( self->_backgroundVoices);
}

// no worky, see header
// + (BOOL) playContentsOfFileUTF8String:(char *) filename;
// {
//    MulleAudio              *audio;
//    MulleAudioVoiceHandle   voice;
//
//    audio = [MulleAudio instance];
//    voice = [audio audioVoiceWithContentsOfFileUTF8String:filename
//                                                  options:MulleAudioVoiceOptionVoiceAny];
//    if( voice == MulleAudioVoiceOptionNoVoice)
//       return( NO);
//    [audio playVoice:voice];
//    return( YES);
// }
//

- (NSInteger) audioVoiceWithAudioSound:(MulleAudioSound *) audioSound
                               options:(MulleAudioVoiceOptions) options
{
   NSUInteger              i;
   NSUInteger              n;
   NSUInteger              *start_p;
   NSUInteger              end;
   NSUInteger              *n_p;
   struct MulleAudioVoice  *p;
   NSInteger               isBackground;

   if( ! audioSound)
      return( MulleAudioVoiceOptionNoVoice);

   isBackground = (options & MulleAudioVoiceOptionBackgroundVoice);
   if( isBackground)
   {
      p       = MulleAudioGetBackgroundVoices( self);
      n_p     = &_numberOfBackgroundVoices;
      start_p = &_currentBackgroundIndex;
   }
   else
   {
      if( [audioSound isStreaming])
         MulleObjCThrowInternalInconsistencyExceptionUTF8String( "can't play a streaming sound in the foreground");

      p       = MulleAudioGetForegroundVoices( self);
      n_p     = &_numberOfForegroundVoices;
      start_p = &_currentForegroundIndex;
   }

   i = options & 0xFFFF;
   if( i == MulleAudioVoiceOptionVoiceAny)
   {
      n   = *n_p;
      end = (i + n) % n;
      for( i = *start_p; i != end; ++i)
      {
         if( i >= n)
            n = 0;

         if( ! p[ i].audioSound)
            goto found;
      }

      // did not find something empty..

      i = *start_p;

      // dial to next (for next any)
      *start_p = *start_p + 1 % *n_p;
   }

   // we just dont play voices that have too high an index
   // superflous check for any, but shucks
   if( i >= *n_p)
   {
      errno = ENODEV;
      return( MulleAudioVoiceOptionNoVoice);
   }

   if( p[ i].audioSound)
   {
      if( (options & 0xFFFF) == MulleAudioVoiceOptionSkipIfFull)
      {
         errno = EBUSY;
         return( MulleAudioVoiceOptionNoVoice);
      }

      [p[ i].audioSound mullePerformFinalize];
      [p[ i].audioSound autorelease];
   }

found:
   p[ i].audioSound = [audioSound retain];

   [audioSound setVolume:p[ i].volume];
   [audioSound setPan:p[ i].pan];
   [audioSound setPitch:p[ i].pitch];

   return( i | isBackground);
}


- (struct MulleAudioVoice *) audioVoiceWithHandle:(MulleAudioVoiceHandle) voice
{
   NSUInteger               i;
   NSInteger                isBackground;
   struct MulleAudioVoice   *p;
   NSUInteger               *n_p;

   if( voice == MulleAudioVoiceOptionNoVoice)
      return( NULL);

   i            = voice & 0xFFFF;
   isBackground = (voice & MulleAudioVoiceOptionBackgroundVoice);
   if( isBackground)
   {
      p   = MulleAudioGetBackgroundVoices( self);
      n_p = &_numberOfBackgroundVoices;
   }
   else
   {
      p   = MulleAudioGetForegroundVoices( self);
      n_p = &_numberOfForegroundVoices;
   }

   if( i >= *n_p)
      return( NULL);

   return( &p[ i]);
}


- (MulleAudioSound *) audioSoundOfVoice:(MulleAudioVoiceHandle) voice
{
   struct MulleAudioVoice   *p;

   p = [self audioVoiceWithHandle:voice];
   if( ! p)
      return( nil);

   return( p->audioSound);
}


- (MulleAudioVoiceHandle) audioVoiceWithContentsOfFileUTF8String:(char *) filepath
                                                        options:(MulleAudioVoiceOptions) options
{
   MulleAudioEngine         *audioEngine;
   MulleAudioSound          *audioSound;
   MulleAudioVoiceHandle    voice;

   audioEngine = [self audioEngine];
   audioSound  = [audioEngine audioSoundWithContentsOfFileUTF8String:filepath];
   voice       = [self audioVoiceWithAudioSound:audioSound
                                        options:options];

   return( voice);
}


- (MulleAudioVoiceHandle) audioVoiceWithFileCData:(struct mulle_data) data
                                          options:(MulleAudioVoiceOptions) options
{
   MulleAudioEngine        *audioEngine;
   MulleAudioSound         *audioSound;
   MulleAudioVoiceHandle   voice;

   audioEngine = [self audioEngine];
   audioSound  = [audioEngine audioSoundWithBytes:data.bytes
                                           length:data.length
                                  miniAudioFormat:ma_format_unknown
                                 numberOfChannels:0
                              miniAudioSampleRate:0];
   voice       = [self audioVoiceWithAudioSound:audioSound
                                        options:options];

   return( voice);
}


- (MulleAudioVoiceHandle) audioVoiceWithBytes:(void *) bytes
                                       length:(NSUInteger) length
                               sampleEncoding:(MulleAudioSampleEncoding) sampleEncoding
                             numberOfChannels:(NSUInteger) channels
                                 sampleRateHz:(NSUInteger) sampleRateHz
                                      options:(MulleAudioVoiceOptions) options;
{
   MulleAudioEngine        *audioEngine;
   MulleAudioSound         *audioSound;
   MulleAudioVoiceHandle   voice;

   audioEngine = [self audioEngine];

   assert( (NSUInteger) MulleAudioSampleEncodingUnsignedByte == (NSUInteger) ma_format_u8);
   assert( (NSUInteger) MulleAudioSampleEncodingSigned16Bit  == (NSUInteger) ma_format_s16);
   assert( (NSUInteger) MulleAudioSampleEncodingSigned24Bit  == (NSUInteger) ma_format_s24);
   assert( (NSUInteger) MulleAudioSampleEncodingSigned32Bit  == (NSUInteger) ma_format_s32);
   assert( (NSUInteger) MulleAudioSampleEncodingFloat        == (NSUInteger) ma_format_f32);

   assert( sampleRateHz == ma_standard_sample_rate_8000
           || sampleRateHz == ma_standard_sample_rate_11025
           || sampleRateHz == ma_standard_sample_rate_16000
           || sampleRateHz == ma_standard_sample_rate_22050
           || sampleRateHz == ma_standard_sample_rate_24000
           || sampleRateHz == ma_standard_sample_rate_32000
           || sampleRateHz == ma_standard_sample_rate_44100
           || sampleRateHz == ma_standard_sample_rate_48000
           || sampleRateHz == ma_standard_sample_rate_88200
           || sampleRateHz == ma_standard_sample_rate_96000
           || sampleRateHz == ma_standard_sample_rate_176400
           || sampleRateHz == ma_standard_sample_rate_192000
           || sampleRateHz == ma_standard_sample_rate_352800
           || sampleRateHz == ma_standard_sample_rate_384000);

   audioSound  = [audioEngine audioSoundWithBytes:bytes
                                           length:length
                                  miniAudioFormat:sampleEncoding
                                 numberOfChannels:channels
                              miniAudioSampleRate:sampleRateHz];
   voice       = [self audioVoiceWithAudioSound:audioSound
                                        options:options];

   return( voice);
}


- (void) playVoice:(MulleAudioVoiceHandle) voice
{
   [[self audioSoundOfVoice:voice] start];
}


- (void) playVoice:(MulleAudioVoiceHandle) voice
           duration:(mulle_relativetime_t) duration
{
   MulleAudioSound   *audioSound;
   ma_sound          *miniSound;
   ma_engine         *engine;
   ma_uint64         stopFrame;

   audioSound = [self audioSoundOfVoice:voice];
   miniSound  = [audioSound miniAudioSound];
   engine     = [[self audioEngine] miniAudioEngine];

   // always restart: clear pending stop, rewind, set new stop, play
   ma_sound_stop( miniSound);
   ma_sound_reset_stop_time( miniSound);
   ma_sound_seek_to_pcm_frame( miniSound, 0);

   stopFrame = ma_engine_get_time_in_pcm_frames( engine)
             + (ma_uint64) (duration * ma_engine_get_sample_rate( engine));
   ma_sound_set_stop_time_in_pcm_frames( miniSound, stopFrame);
   [audioSound start];
}


- (void) pauseVoice:(MulleAudioVoiceHandle) voice
{
   [[self audioSoundOfVoice:voice] stop];
}


- (void) stopVoice:(MulleAudioVoiceHandle) voice;
{
   MulleAudioSound   *audioSound;

   audioSound = [self audioSoundOfVoice:voice];
   [audioSound stop];
   [audioSound setSeek:0];
}


- (BOOL) isPlayingVoice:(MulleAudioVoiceHandle) voice;
{
   MulleAudioSound   *audioSound;

   audioSound = [self audioSoundOfVoice:voice];
   return( [audioSound isPlaying]);
}


- (void) fadeInVoice:(MulleAudioVoiceHandle)voice
                time:(mulle_relativetime_t) time
{
   MulleAudioSound   *audioSound;

   audioSound = [self audioSoundOfVoice:voice];
   [audioSound setFadeIn:time
             startVolume:0.0
               endVolume:[audioSound volume]];
   [audioSound start];
}


- (void) fadeOutVoice:(MulleAudioVoiceHandle) voice
                 time:(mulle_relativetime_t) time
{
   [[self audioSoundOfVoice:voice] fadeOut:time];
}



// volume
- (void) setVolume:(float) volume
           ofVoice:(MulleAudioVoiceHandle) voice;
{
   MulleAudioSound          *audioSound;
   struct MulleAudioVoice   *audioVoice;

   audioVoice = [self audioVoiceWithHandle:voice];
   if( ! audioVoice)
      return;
      
   audioSound = audioVoice->audioSound;
   audioVoice->volume = volume;
   [audioSound setVolume:volume];
}


- (void) setBalance:(float) balance
            ofVoice:(MulleAudioVoiceHandle) voice;
{
   MulleAudioSound          *audioSound;
   struct MulleAudioVoice   *audioVoice;

   audioVoice = [self audioVoiceWithHandle:voice];
   if( ! audioVoice)
      return;

   audioSound = audioVoice->audioSound;
   audioVoice->pan = balance;
   [audioSound setPan:balance];  // sic!
}


- (void) setPitch:(float) pitch
          ofVoice:(MulleAudioVoiceHandle) voice;
{
   MulleAudioSound          *audioSound;
   struct MulleAudioVoice   *audioVoice;

   audioVoice = [self audioVoiceWithHandle:voice];
   if( ! audioVoice)
      return;

   audioSound = audioVoice->audioSound;
   audioVoice->pitch = pitch;
   [audioSound setPitch:pitch];
}



- (void) pitchToFrequency:(float) toFrequency
            fromFrequency:(float) fromFrequency
                  ofVoice:(MulleAudioVoiceHandle) voice
{
   MulleAudioSound          *audioSound;
   struct MulleAudioVoice   *audioVoice;
   float                    pitch;

   audioVoice = [self audioVoiceWithHandle:voice];
   if( ! audioVoice)
      return;

   audioSound = audioVoice->audioSound;
   if( ! audioSound || fromFrequency <= 0.0f)
      return;

   // miniaudio already resamples source→engine rate internally,
   // so pitch is purely the frequency ratio
   pitch = toFrequency / fromFrequency;

   audioVoice->pitch = pitch;
   [audioSound setPitch:pitch];
}


- (void) setLoop:(BOOL) flag
         ofVoice:(MulleAudioVoiceHandle) voice
{
   [[self audioSoundOfVoice:voice] setLoop:flag];
}


- (void) fastForwardVoice:(MulleAudioVoiceHandle) voice
                     time:(mulle_relativetime_t) time
{
   MulleAudioSound        *audioSound;
   mulle_relativetime_t   seek;

   audioSound = [self audioSoundOfVoice:voice];
   seek       = [audioSound seek];
   [audioSound setSeek:seek + time];
   [audioSound start];
}


- (void) rewindVoice:(MulleAudioVoiceHandle) voice
                time:(mulle_relativetime_t) time
{
   MulleAudioSound        *audioSound;
   mulle_relativetime_t   seek;

   audioSound = [self audioSoundOfVoice:voice];
   seek       = [audioSound seek];
   [audioSound setSeek:seek - time];
   [audioSound start];
}


- (void) waitForCompletionOfVoice:(MulleAudioVoiceHandle) voice
{
   [[self audioSoundOfVoice:voice] waitForCompletion];
}

@end
