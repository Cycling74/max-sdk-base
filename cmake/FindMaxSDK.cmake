include(FindPackageHandleStandardArgs)

find_library(MaxSDK_Max_LIBRARY
  NAMES MaxAPI
  PATHS "${MAXSDK_SOURCE_DIR}/c74support/max-includes"
  PATH_SUFFIXES x64
  NO_DEFAULT_PATH)
find_library(MaxSDK_MSP_LIBRARY
  NAMES MaxAudioAPI
  PATHS "${MAXSDK_SOURCE_DIR}/c74support/msp-includes"
  PATH_SUFFIXES x64
  NO_DEFAULT_PATH)
find_library(MaxSDK_Jitter_LIBRARY
  NAMES JitterAPI
  PATHS "${MAXSDK_SOURCE_DIR}/c74support/jit-includes"
  PATH_SUFFIXES x64
  NO_DEFAULT_PATH)

find_package_handle_standard_args(MaxSDK
  REQUIRED_VARS
    MaxSDK_Max_LIBRARY
    MaxSDK_Max_INCLUDE_DIR
  HANDLE_COMPONENTS)

if (MaxSDK_Max_FOUND AND NOT TARGET Max::Max)
  add_library(Max::Max SHARED IMPORTED)
  target_include_directories(Max::Max
    INTERFACE
    $<BUILD_INTERFACE:${MaxSDK_Max_INCLUDE_DIRS}>)
  set_property(TARGET Max::Max
    PROPERTY
      IMPORTED_IMPLIB "${MaxSDK_Max_LIBRARY}")
endif()

if (MaxSDK_MSP_FOUND AND NOT TARGET Max::MSP)
  add_library(Max::MSP SHARED IMPORTED)
  target_include_directories(Max::MSP
    INTERFACE
      $<BUILD_INTERFACE:${MaxSDK_MSP_INCLUDE_DIRS}>)
  set_property(TARGET Max::MSP
    PROPERTY
      IMPORTED_IMPLIB "${MaxSDK_MSP_LIBRARY}")
endif()

if (MaxSDK_Jitter_FOUND AND NOT TARGET Max::Jitter)
  add_library(Max::Jitter SHARED IMPORTED)
  target_include_directories(Max::Jitter
    INTERFACE
      $<BUILD_INTERFACE:${MaxSDK_Jitter_INCLUDE_DIRS}>)
  set_property(TARGET Max::Jitter
    PROPERTY
      IMPORTED_IMPLIB "${MaxSDK_Jitter_LIBRARY}")
endif()

if (MaxSDK_FOUND AND NOT TARGET Max::SDK)
  add_library(Max::SDK INTERFACE IMPORTED)
  target_compile_definitions(Max::SDK
    INTERFACE
      $<$<PLATFORM_ID:Windows>:MAXAPI_USE_MSCRT>
      $<$<PLATFORM_ID:Windows>:WIN_VERSION>
      $<$<PLATFORM_ID:Windows>:_USE_MATH_DEFINES>)
  target_link_libraries(Max::SDK
      INTERFACE
        Max::Max
        Max::MSP
        Max::Jitter)
endif()
