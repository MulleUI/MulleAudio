@class MulleAudioEngine;
struct mulle_array;

@interface MulleAudioContext( Private)

- (void) _addEngine:(MulleAudioEngine *) engine;
- (void) _removeEngine:(MulleAudioEngine *) engine;
- (struct mulle_array *) _engines;

@end
