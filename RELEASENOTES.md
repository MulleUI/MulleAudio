## 0.1.0




feature: add factory construction methods for audio objects

* add `engineWithMiniAudioEngineConfig:`, `deviceWithMiniAudioDevice:` and `audioDeviceWithMiniAudioDevice:` factory methods on engine/device/context
* add `dataSourceWithBytes:` to create audio data sources from raw bytes and `audioDataSourceWithBytes:` wrapper on engine
* add `soundWithAudioDataSource:`, `soundWithAudioSound:` and `audioSoundWithAudioDataSource:`/`audioSoundByCopyingAudioSound:` factories for building and copying sounds without manual alloc/init/autorelease
* fix miniaudio decoder and audio buffer now being properly uninitialized in MulleAudioDataSource dealloc, preventing resource leaks
