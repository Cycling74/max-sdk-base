# Copyright 2018 The Max-API Authors. All rights reserved.
# Use of this source code is governed by the MIT License found in the License.md file.

cmake_minimum_required(VERSION 3.19)

# we need to access this directory in some places
set_property(GLOBAL PROPERTY C74_MAX_SDK_BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
include(script/add_max_target.cmake)


# Create interface lib for max-sdk-base
set(target max-sdk-base)
add_library(${target} INTERFACE 
	"c74support/c74_jitter.h"
	"c74support/c74_max.h"
	"c74support/c74_msp.h"
	"c74support/c74_ui.h"
	"c74support/c74_ui_graphics.h"
)

set(MAX_SDK_INCLUDE_DIRS )
target_include_directories(${target} 
	INTERFACE 
		"${CMAKE_CURRENT_SOURCE_DIR}/c74support"
		"${CMAKE_CURRENT_SOURCE_DIR}/c74support/jit-includes"
		"${CMAKE_CURRENT_SOURCE_DIR}/c74support/max-includes"
		"${CMAKE_CURRENT_SOURCE_DIR}/c74support/msp-includes"
)
set_target_properties(${target} PROPERTIES FOLDER "C74_Libraries")
