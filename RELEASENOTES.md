### 0.1.1






* NSFastEnumeration of audio engines now tracks mutations through ``mulle_array_get_mutation_pointer()`,` fixing missed mutation detection during enumeration
* enumeration is now robust under NDEBUG, where the accessor transparently falls back to the structural proxy

## 0.1.0




feature: add factory construction methods for audio objects

* add `engineWithMiniAudioEngineConfig:`, `deviceWithMiniAudioDevice:` and `audioDeviceWithMiniAudioDevice:` factory methods on engine/device/context
* add `dataSourceWithBytes:` to create audio data sources from raw bytes and `audioDataSourceWithBytes:` wrapper on engine
* add `soundWithAudioDataSource:`, `soundWithAudioSound:` and `audioSoundWithAudioDataSource:`/`audioSoundByCopyingAudioSound:` factories for building and copying sounds without manual alloc/init/autorelease
* fix miniaudio decoder and audio buffer now being properly uninitialized in MulleAudioDataSource dealloc, preventing resource leaks
