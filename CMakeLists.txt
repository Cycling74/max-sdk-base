cmake_minimum_required(VERSION 3.25)

list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

find_package(Git QUIET)

include(C74/PackageInfo)
include(C74/Support)

# Set as a CACHE variable so it remains visible after add_subdirectory returns;
# After.cmake and Before.cmake read it when they fire during the consumer's project() call.
set(MAXSDK_BASE_DIR
    "${CMAKE_CURRENT_SOURCE_DIR}"
    CACHE PATH "Root of max-sdk-base" FORCE)

include(Max/Targets)

# Removes the need for GetGitRevisionDescription.cmake
set_property(DIRECTORY "${CMAKE_SOURCE_DIR}" APPEND
  PROPERTY
    CMAKE_CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/.git/HEAD")
