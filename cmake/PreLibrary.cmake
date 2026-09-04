### Overrides cmake/share/PreLibrary.cmake.
### Picked up in preference over the cmake/share version and not clobbered by
### `mulle-sde upgrade`.
###
### Purpose: On Apple platforms the miniaudio implementation
### (src/miniaudio.m) pulls in CoreAudio / AudioToolbox, which drag in Apple's
### Objective-C runtime headers (<objc/objc.h>). These are hostile to
### mulle-clang / mulle-objc:
###
###    * redefine BOOL as `signed char` (clashes with mulle-c11 enum _MulleBool)
###    * apply nullability specifiers to the non-pointer SEL type
###    * use Apple ^blocks without -fblocks
###
### To keep those headers away from mulle-clang we compile just this one
### translation unit with Apple's own clang (via xcrun), producing an object
### file that is linked into the library. miniaudio's public API only uses
### ma_bool8 / ma_bool32 (== ma_uint8 / ma_uint32), never BOOL, so the object
### is ABI compatible with the mulle-clang compiled callers.
###
### On every other platform nothing changes: miniaudio.m stays in SOURCES and
### is compiled by mulle-clang as usual.

# can be included multiple times

if( MULLE_TRACE_INCLUDE)
   message( STATUS "# Include \"${CMAKE_CURRENT_LIST_FILE}\"" )
endif()

# Preserve the standard PreLibrary behaviour.
include( CompilerDetectionC)
include( CompilerWarningsC)   # after detection, before flags
include( CompilerFlagsC)

include( PreLibraryAuxC OPTIONAL)


if( APPLE)
   set( MULLE_AUDIO_MINIAUDIO_SRC "${CMAKE_CURRENT_SOURCE_DIR}/src/miniaudio.m")

   #
   # 1) Remove miniaudio.m from the sources compiled by mulle-clang.
   #    SOURCES comes from the reflected cmake/reflect/_Sources.cmake, which we
   #    must not edit by hand. Library.cmake has already copied SOURCES into
   #    LIBRARY_SOURCES (the actual compile input) before including us, so
   #    filter both.
   #
   list( REMOVE_ITEM SOURCES "src/miniaudio.m")
   list( REMOVE_ITEM LIBRARY_SOURCES "src/miniaudio.m")

   #
   # 2) Assemble the flags for the standalone Apple-clang compile. We mirror
   #    what mulle-clang would have used: project include directories,
   #    dependency include and framework directories, the macOS sysroot,
   #    architectures, PIC and the build-type debug/optimization flags.
   #
   set( _MA_FLAGS
      "-x" "objective-c"
      "-std=c11"
      "-fPIC"
      "-DMULLE_AUDIO_MINIAUDIO_STANDALONE=1"
      "-D${LIBRARY_UPCASE_IDENTIFIER}_BUILD"
   )

   # Project headers (matches the -I flags used by mulle-clang).
   list( APPEND _MA_FLAGS
      "-I${CMAKE_CURRENT_SOURCE_DIR}/src/reflect"
      "-I${CMAKE_CURRENT_SOURCE_DIR}/src/generic"
      "-I${CMAKE_CURRENT_SOURCE_DIR}/src"
   )

   # Dependency headers and frameworks. MULLE_SDK_PATH is a list of sdk roots
   # (e.g. test/dependency, test/addiction). Each may carry a plain include
   # dir and a per-configuration one, plus Frameworks directories.
   foreach( _sdk ${MULLE_SDK_PATH})
      if( IS_DIRECTORY "${_sdk}/include")
         list( APPEND _MA_FLAGS "-isystem" "${_sdk}/include")
      endif()
      if( CMAKE_BUILD_TYPE AND IS_DIRECTORY "${_sdk}/${CMAKE_BUILD_TYPE}/include")
         list( APPEND _MA_FLAGS "-isystem" "${_sdk}/${CMAKE_BUILD_TYPE}/include")
      endif()
      if( IS_DIRECTORY "${_sdk}/Frameworks")
         list( APPEND _MA_FLAGS "-F" "${_sdk}/Frameworks")
      endif()
      if( CMAKE_BUILD_TYPE AND IS_DIRECTORY "${_sdk}/${CMAKE_BUILD_TYPE}/Frameworks")
         list( APPEND _MA_FLAGS "-F" "${_sdk}/${CMAKE_BUILD_TYPE}/Frameworks")
      endif()
   endforeach()
   unset( _sdk)

   # macOS sysroot.
   if( CMAKE_OSX_SYSROOT)
      list( APPEND _MA_FLAGS "-isysroot" "${CMAKE_OSX_SYSROOT}")
   endif()

   # Architectures (may be empty, meaning "native").
   foreach( _arch ${CMAKE_OSX_ARCHITECTURES})
      list( APPEND _MA_FLAGS "-arch" "${_arch}")
   endforeach()
   unset( _arch)

   # Debug / optimization: mirror the build type.
   if( CMAKE_BUILD_TYPE STREQUAL "Debug" OR CMAKE_BUILD_TYPE STREQUAL "")
      list( APPEND _MA_FLAGS "-g" "-DDEBUG")
   else()
      list( APPEND _MA_FLAGS "-O2" "-DNDEBUG")
   endif()

   #
   # 3) Compile with Apple clang via xcrun into an object file inside the
   #    build tree. Use add_custom_command so ninja/make rebuild it when
   #    miniaudio.m (or its headers) change.
   #
   set( _MA_OBJ "${CMAKE_CURRENT_BINARY_DIR}/miniaudio.standalone.o")

   find_program( MULLE_AUDIO_XCRUN xcrun)
   if( NOT MULLE_AUDIO_XCRUN)
      message( FATAL_ERROR "xcrun not found; required to build miniaudio.m with Apple clang")
   endif()

   add_custom_command(
      OUTPUT  "${_MA_OBJ}"
      COMMAND "${MULLE_AUDIO_XCRUN}" clang ${_MA_FLAGS}
              -c "${MULLE_AUDIO_MINIAUDIO_SRC}"
              -o "${_MA_OBJ}"
      DEPENDS "${MULLE_AUDIO_MINIAUDIO_SRC}"
              "${CMAKE_CURRENT_SOURCE_DIR}/src/miniaudio.h"
      COMMENT "Compiling miniaudio.m with Apple clang (isolated from mulle-objc)"
      VERBATIM
   )

   #
   # 4) Hand the object to Library.cmake. It merges
   #    OTHER_<UPCASE>_OBJECT_FILES into ALL_OBJECT_FILES and links them into
   #    the final library. Because the object is a link input of the library
   #    target, CMake automatically makes the above custom command a build
   #    dependency, so the object is produced before the link. Mark it
   #    EXTERNAL so cmake does not try to compile it itself.
   #
   set_source_files_properties( "${_MA_OBJ}"
      PROPERTIES
         EXTERNAL_OBJECT TRUE
         GENERATED       TRUE
   )
   list( APPEND OTHER_${LIBRARY_UPCASE_IDENTIFIER}_OBJECT_FILES "${_MA_OBJ}")
endif()
