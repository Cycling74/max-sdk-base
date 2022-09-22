# Copyright 2018 The Max-API Authors. All rights reserved.
# Use of this source code is governed by the MIT License found in the License.md file.

cmake_minimum_required(VERSION 3.19)

project(max-sdk-base)

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
set_target_properties(${target} PROPERTIES LINKER_LANGUAGE CXX)



target_include_directories(${target} 
	INTERFACE 
		"$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/c74support>"
		"$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/c74support/jit-includes>"
		"$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/c74support/max-includes>"
		"$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/c74support/msp-includes>"
		"$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/include/c74support>"
		"$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/include/c74support/jit-includes>"
		"$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/include/c74support/max-includes>"
		"$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/include/c74support/msp-includes>"
)
set_target_properties(${target} PROPERTIES FOLDER "C74_Libraries")



# Link to precompiled libraries
set(C74_SUPPORT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/c74support")
set(MAX_SDK_INCLUDES "${C74_SUPPORT_DIR}/max-includes")
set(MAX_SDK_MSP_INCLUDES "${C74_SUPPORT_DIR}/msp-includes")
set(MAX_SDK_JIT_INCLUDES "${C74_SUPPORT_DIR}/jit-includes")

if (APPLE)
	find_library(MSP_LIBRARY "MaxAudioAPI" REQUIRED
		PATHS "${MAX_SDK_MSP_INCLUDES}"
		NO_DEFAULT_PATH	NO_CMAKE_FIND_ROOT_PATH
		# only use the specific path, don't look in system root this enables cross 
		# compilation to provide an alternative root but also find this specific pat
	)
	find_library(JITTER_LIBRARY "JitterAPI" REQUIRED
		PATHS "${MAX_SDK_JIT_INCLUDES}"
		NO_DEFAULT_PATH	NO_CMAKE_FIND_ROOT_PATH
	)
	target_link_libraries(${target} INTERFACE ${MSP_LIBRARY})
	target_link_libraries(${target} INTERFACE ${JITTER_LIBRARY})
elseif (WIN32)
	target_link_libraries(${target} INTERFACE "${MAX_SDK_INCLUDES}/x64/MaxAPI.lib")
	target_link_libraries(${target} INTERFACE "${MAX_SDK_MSP_INCLUDES}/x64/MaxAudio.lib")
	target_link_libraries(${target} INTERFACE "${MAX_SDK_JIT_INCLUDES}/x64/jitlib.lib")
endif ()
