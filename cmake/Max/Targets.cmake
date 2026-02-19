include_guard(GLOBAL)

# Derive the SDK root from this file's location (cmake/Max/ -> ../../) so that
# Targets.cmake works whether included directly or via add_subdirectory/FetchContent.
get_filename_component(_maxsdk_base "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)
if(NOT DEFINED MAXSDK_BASE_DIR)
    set(MAXSDK_BASE_DIR "${_maxsdk_base}" CACHE PATH "Root of max-sdk-base")
endif()
unset(_maxsdk_base)

set(_c74 "${MAXSDK_BASE_DIR}/c74support")

# Max::Max
add_library(Max::Max INTERFACE IMPORTED GLOBAL)
target_include_directories(Max::Max INTERFACE "${_c74}" "${_c74}/max-includes")
if(WIN32)
    target_link_libraries(Max::Max INTERFACE "${_c74}/max-includes/x64/MaxAPI.lib")
    target_compile_definitions(Max::Max INTERFACE MAXAPI_USE_MSCRT WIN_VERSION _USE_MATH_DEFINES)
elseif(APPLE)
    # Stored as property; applied per-target in After.cmake (too large for INTERFACE_LINK_OPTIONS)
    set_property(TARGET Max::Max PROPERTY _MAX_LINKER_FLAGS_FILE "${MAXSDK_BASE_DIR}/script/max-linker-flags.txt")
endif()

# Max::MSP
add_library(Max::MSP INTERFACE IMPORTED GLOBAL)
target_include_directories(Max::MSP INTERFACE "${_c74}/msp-includes")
target_link_libraries(Max::MSP INTERFACE Max::Max)
if(WIN32)
    target_link_libraries(Max::MSP INTERFACE "${_c74}/msp-includes/x64/MaxAudio.lib")
elseif(APPLE)
    find_library(
        MaxAudioAPI_LIB MaxAudioAPI
        PATHS "${_c74}/msp-includes"
        NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH REQUIRED)
    target_link_libraries(Max::MSP INTERFACE "${MaxAudioAPI_LIB}")
endif()

# Max::Jitter
add_library(Max::Jitter INTERFACE IMPORTED GLOBAL)
target_include_directories(Max::Jitter INTERFACE "${_c74}/jit-includes")
target_link_libraries(Max::Jitter INTERFACE Max::Max)
if(WIN32)
    target_link_libraries(Max::Jitter INTERFACE "${_c74}/jit-includes/x64/jitlib.lib")
elseif(APPLE)
    find_library(
        JitterAPI_LIB JitterAPI
        PATHS "${_c74}/jit-includes"
        NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH REQUIRED)
    target_link_libraries(Max::Jitter INTERFACE "${JitterAPI_LIB}")
endif()

unset(_c74)
