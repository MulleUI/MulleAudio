#import <MulleAudio/MulleAudio.h>
#import <mulle-objc-debug/mulle-objc-debug.h>


@interface MulleAudio( Category)
@end

@implementation MulleAudio( Category)
@end

- (MulleAudioVoiceHandle) audioVoiceWithEmbeddedFileBytes:(void *) bytes
                                                   length:(NSUInteger) length
                                                 options:(MulleAudioVoiceOptions) options;

int   main( int argc, char *argv[])
{
   MulleAudioVoice   voice;
   MulleAudio        *audio;

   audio = [MulleAudio object];
   voice = [audio audioVoiceWithEmbeddedFileBytes:foreseen
                                           length:s_foreseen
                                           options:MulleAudioVoiceOptionVoiceAny];

   return( 0);
}
