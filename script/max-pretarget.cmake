# Copyright 2018 The Max-API Authors. All rights reserved.
# Use of this source code is governed by the MIT License found in the License.md file.

include("${CMAKE_CURRENT_LIST_DIR}/macros.cmake")

string(REGEX REPLACE "(.*)/" "" THIS_FOLDER_NAME "${CMAKE_CURRENT_SOURCE_DIR}")
string(REPLACE "~" "_tilde" THIS_FOLDER_NAME "${THIS_FOLDER_NAME}")

c74_max_pre_project_calls()

project(${THIS_FOLDER_NAME})

c74_max_post_project_calls()


set(C74_CXX_STANDARD 0)


if (DEFINED C74_LIBRARY_OUTPUT_DIRECTORY)
	set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${C74_LIBRARY_OUTPUT_DIRECTORY}")
else ()
	if (NOT DEFINED C74_BUILD_MAX_EXTENSION)
		set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../../../externals")
	else ()
		set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../../../extensions")
	endif ()
endif()
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}")
