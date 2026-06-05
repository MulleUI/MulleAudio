#ifndef MULLE_AUDIO_RECORDING_TAP_H
#define MULLE_AUDIO_RECORDING_TAP_H

#include "miniaudio.h"

//
// Internal struct for the recording tap.
// Used by MulleAudioEngine+Recording.m
//
struct MulleAudioRecordingTap
{
   ma_encoder     encoder;
   ma_uint32      channels;
   BOOL           isRecording;
};

#endif
