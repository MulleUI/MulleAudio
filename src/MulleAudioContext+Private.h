@class MulleAudioEngine;
struct mulle_array;

@interface MulleAudioContext( Private)

- (void) _addEngine:(MulleAudioEngine *) engine;
- (void) _removeEngine:(MulleAudioEngine *) engine;
- (id) _engineAtIndex:(NSUInteger) i;
- (struct mulle_array *) _engines;

@end
