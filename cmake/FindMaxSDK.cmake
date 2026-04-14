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

set(MaxSDK_Max_INCLUDE_DIR "${MAXSDK_SOURCE_DIR}/c74support/max-includes" CACHE PATH "")
set(MaxSDK_MSP_INCLUDE_DIR "${MAXSDK_SOURCE_DIR}/c74support/msp-includes" CACHE PATH "")
set(MaxSDK_Jitter_INCLUDE_DIR "${MAXSDK_SOURCE_DIR}/c74support/jit-includes" CACHE PATH "")

if (MaxSDK_Max_LIBRARY AND MaxSDK_Max_INCLUDE_DIR)
  set(MaxSDK_Max_FOUND TRUE)
  set(MaxSDK_Max_INCLUDE_DIRS "${MaxSDK_Max_INCLUDE_DIR}")
endif()

if (MaxSDK_MSP_LIBRARY AND MaxSDK_MSP_INCLUDE_DIR)
  set(MaxSDK_MSP_FOUND TRUE)
  set(MaxSDK_MSP_INCLUDE_DIRS "${MaxSDK_MSP_INCLUDE_DIR}")
endif()

if (MaxSDK_Jitter_LIBRARY AND MaxSDK_Jitter_INCLUDE_DIR)
  set(MaxSDK_Jitter_FOUND TRUE)
  set(MaxSDK_Jitter_INCLUDE_DIRS "${MaxSDK_Jitter_INCLUDE_DIR}")
endif()

find_package_handle_standard_args(MaxSDK
  REQUIRED_VARS
    MaxSDK_Max_LIBRARY
    MaxSDK_Max_INCLUDE_DIR
  HANDLE_COMPONENTS)

if (MaxSDK_Max_FOUND AND NOT TARGET Max::Max)
  # UNKNOWN allows us to return a framework bundle or an import .lib
  # GLOBAL to make the target visible to all callers regardless of where
  # the module is included (imported targets are directory-scoped by default)
  add_library(Max::Max UNKNOWN IMPORTED GLOBAL)
  target_include_directories(Max::Max
    INTERFACE
    $<BUILD_INTERFACE:${MaxSDK_Max_INCLUDE_DIRS}>)
  if (WIN32)
    set_property(TARGET Max::Max PROPERTY IMPORTED_IMPLIB "${MaxSDK_Max_LIBRARY}")
  else()
    set_property(TARGET Max::Max PROPERTY IMPORTED_LOCATION "${MaxSDK_Max_LIBRARY}")
  endif()
endif()

if (MaxSDK_MSP_FOUND AND NOT TARGET Max::MSP)
  add_library(Max::MSP UNKNOWN IMPORTED GLOBAL)
  target_include_directories(Max::MSP
    INTERFACE
      $<BUILD_INTERFACE:${MaxSDK_MSP_INCLUDE_DIRS}>)
  if (WIN32)
    set_property(TARGET Max::MSP PROPERTY IMPORTED_IMPLIB "${MaxSDK_MSP_LIBRARY}")
  else()
    set_property(TARGET Max::MSP PROPERTY IMPORTED_LOCATION "${MaxSDK_MSP_LIBRARY}")
  endif()
endif()

if (MaxSDK_Jitter_FOUND AND NOT TARGET Max::Jitter)
  add_library(Max::Jitter UNKNOWN IMPORTED GLOBAL)
  target_include_directories(Max::Jitter
    INTERFACE
      $<BUILD_INTERFACE:${MaxSDK_Jitter_INCLUDE_DIRS}>)
  if (WIN32)
    set_property(TARGET Max::Jitter PROPERTY IMPORTED_IMPLIB "${MaxSDK_Jitter_LIBRARY}")
  else()
    set_property(TARGET Max::Jitter PROPERTY IMPORTED_LOCATION "${MaxSDK_Jitter_LIBRARY}")
  endif()
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
