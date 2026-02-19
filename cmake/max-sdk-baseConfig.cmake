# max-sdk-baseConfig.cmake
# Supports find_package(max-sdk-base) after the package is on CMAKE_PREFIX_PATH,
# e.g. when FetchContent_MakeAvailable sets up the paths automatically in CMake 3.24+.

get_filename_component(_maxsdk_base "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)

list(APPEND CMAKE_MODULE_PATH "${_maxsdk_base}/cmake")

if(NOT DEFINED MAXSDK_BASE_DIR)
    set(MAXSDK_BASE_DIR "${_maxsdk_base}" CACHE PATH "Root of max-sdk-base")
endif()

include("${_maxsdk_base}/cmake/Max/Targets.cmake")

unset(_maxsdk_base)
