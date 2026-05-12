include(FindPackageHandleStandardArgs)

find_library(MaxSDK_Max_LIBRARY
  NAMES MaxAPI
  PATHS "${MAXSDK_SOURCE_DIR}/c74support/max-includes"
  PATH_SUFFIXES x64
  NO_DEFAULT_PATH)
find_library(MaxSDK_MSP_LIBRARY
  NAMES MaxAudio MaxAudioAPI
  PATHS "${MAXSDK_SOURCE_DIR}/c74support/msp-includes"
  PATH_SUFFIXES x64
  NO_DEFAULT_PATH)
find_library(MaxSDK_Jitter_LIBRARY
  NAMES jitlib JitterAPI
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
  # GLOBAL to make the target visible to all callers regardless of where
  # the module is included (imported targets are directory-scoped by default)
  if (APPLE)
    # On macOS, Max API symbols are resolved at load time by the Max host
    # via the weak-undefined (-Wl,-U) linker flags. Linking directly against
    # MaxAPI.framework would introduce an unsatisfiable runtime dependency on
    # MaxAPIImpl.framework, so Max::Max is INTERFACE-only on macOS.
    #
    # This can be a proper non-INTERFACE library in the future if a .tbd is
    # created alongside a framework.
    add_library(Max::Max INTERFACE IMPORTED GLOBAL)
    target_include_directories(Max::Max
      INTERFACE
        "${MaxSDK_Max_INCLUDE_DIRS}")
    set_property(TARGET Max::Max PROPERTY
      _MAX_LINKER_FLAGS_FILE
      "${MAXSDK_SOURCE_DIR}/c74support/max-includes/c74_linker_flags.txt")
  else()
    add_library(Max::Max UNKNOWN IMPORTED GLOBAL)
    target_include_directories(Max::Max
      INTERFACE
        "${MaxSDK_Max_INCLUDE_DIRS}")
    set_property(TARGET Max::Max PROPERTY IMPORTED_LOCATION "${MaxSDK_Max_LIBRARY}")
  endif()
endif()

if (MaxSDK_MSP_FOUND AND NOT TARGET Max::MSP)
  add_library(Max::MSP UNKNOWN IMPORTED GLOBAL)
  target_include_directories(Max::MSP
    INTERFACE
      "${MaxSDK_MSP_INCLUDE_DIRS}")
  if (WIN32)
    set_property(TARGET Max::MSP PROPERTY IMPORTED_LOCATION "${MaxSDK_MSP_LIBRARY}")
  else()
    set_property(TARGET Max::MSP PROPERTY IMPORTED_LOCATION "${MaxSDK_MSP_LIBRARY}")
  endif()
endif()

if (MaxSDK_Jitter_FOUND AND NOT TARGET Max::Jitter)
  add_library(Max::Jitter UNKNOWN IMPORTED GLOBAL)
  target_include_directories(Max::Jitter
    INTERFACE
      "${MaxSDK_Jitter_INCLUDE_DIRS}")
  if (WIN32)
    set_property(TARGET Max::Jitter PROPERTY IMPORTED_LOCATION "${MaxSDK_Jitter_LIBRARY}")
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
