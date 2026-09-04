### 0.1.0

* new factory construction methods for audio objects
  * `engineWithMiniAudioEngineConfig:`, `deviceWithMiniAudioDevice:` and `audioDeviceWithMiniAudioDevice:` factories
  * `dataSourceWithBytes:` and `audioDataSourceWithBytes:` to create audio data sources from raw bytes
  * `soundWithAudioDataSource:`, `soundWithAudioSound:` and `audioSoundWithAudioDataSource:`/`audioSoundByCopyingAudioSound:` factories for building and copying sounds
* fix miniaudio decoder and audio buffer being properly uninitialized in MulleAudioDataSource dealloc
* compile miniaudio.c standalone on Apple platforms
* added BSD license headers to all src files

### 0.0.1

Various small improvements
