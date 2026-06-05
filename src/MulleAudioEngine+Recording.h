#import "MulleAudioEngine.h"


//
// Record the engine's mixed output to a WAV file.
//
// Usage:
//    [engine startRecordingToFileUTF8String:"/tmp/output.wav"];
//    ... play sounds ...
//    [engine stopRecording];
//
@interface MulleAudioEngine (Recording)

- (BOOL) startRecordingToFileUTF8String:(char *) path;
- (void) stopRecording;
- (BOOL) isRecording;

@end
