cmake_minimum_required(VERSION 3.19)
project(max-sdk-base)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Set as a CACHE variable so it remains visible after add_subdirectory returns;
# After.cmake and Before.cmake read it when they fire during the consumer's project() call.
set(MAXSDK_BASE_DIR
    "${CMAKE_CURRENT_SOURCE_DIR}"
    CACHE PATH "Root of max-sdk-base" FORCE)

include(Max/Targets)
