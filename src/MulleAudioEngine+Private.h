@class MulleAudioSound;


//
// sound will NOT be retained by the engine !
// but registered sounds will be finalized during -finalize
//
@interface MulleAudioEngine( Private)

- (void) _addSound:(MulleAudioSound *) sound;
- (void) _removeSound:(MulleAudioSound *) sound;

@end
