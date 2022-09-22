# Copyright 2018 The Max-API Authors. All rights reserved.
# Use of this source code is governed by the MIT License found in the License.md file.

include("${CMAKE_CURRENT_LIST_DIR}/macros.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/git-rev.cmake")

# This command creates a project as well as a libary target with the specified name. 
# The list of sources which is passed will be added to the target. 
#
# Call example: 
# add_max_target(mytarget SOURCES main.cpp asd.cpp)
# 
function(add_max_target target)
	set(sources_arg SOURCES)
	cmake_parse_arguments(PARSE_ARGV 0 PARAMS "${options}" "${oneValueArgs}" "${sources_arg}")

	c74_max_pre_project_calls()
	
	project(${target})

	c74_max_post_project_calls()

	
	# Create target 
	add_library(${target} MODULE "${PARAMS_SOURCES}")
	target_link_libraries(${target} PRIVATE max-sdk-base)
	set_target_properties(${target} PROPERTIES OUTPUT_NAME "${${target}_EXTERN_OUTPUT_NAME}")
	set_target_properties(${target} PROPERTIES PREFIX "") # remove the 'lib' prefix for some generators


	# C++ standard and compile flags
	set(C74_CXX_STANDARD 0)
	if (${C74_CXX_STANDARD} EQUAL 98) # From max-posttarget, seems redundant:
		if (APPLE)
			set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=gnu++98 -stdlib=libstdc++")
			set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -stdlib=libstdc++")
			set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -stdlib=libstdc++")
		endif ()
	else ()
		set_target_properties(${target} PROPERTIES CXX_STANDARD 17)
		set_target_properties(${target} PROPERTIES CXX_STANDARD_REQUIRED ON)
	endif ()


	# Configuration and link to precompiled libs (the latter not anymore, instead link against max-sdk-base library which links against these)
	if (APPLE)
		if ("${target}" MATCHES "jit.gl.*")
			target_link_libraries(${target} PUBLIC "-framework OpenGL")
		endif()	
		set_target_properties(${target} PROPERTIES BUNDLE True)
		set_target_properties(${target} PROPERTIES BUNDLE_EXTENSION "mxo")	
		set_target_properties(${target} PROPERTIES XCODE_ATTRIBUTE_WRAPPER_EXTENSION "mxo")
		set_target_properties(${target} PROPERTIES MACOSX_BUNDLE_BUNDLE_VERSION "${GIT_VERSION_TAG}")
		set_target_properties(${target} PROPERTIES MACOSX_BUNDLE_INFO_PLIST "${MAX_SDK_BASE_DIR}/script/Info.plist.in")
		set_target_properties(${target} PROPERTIES XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${AUTHOR_DOMAIN}.${BUNDLE_IDENTIFIER}")
	elseif (WIN32)
		if ("${target}" MATCHES "_test")
		else ()
			if ("${target}" MATCHES "jit.gl.*")
				find_package(OpenGL REQUIRED)
				include_directories(${OPENGL_INCLUDE_DIR})
				target_link_libraries(${target} PUBLIC ${OPENGL_LIBRARIES})
			endif()
		endif ()
	
		set_target_properties(${target} PROPERTIES SUFFIX ".mxe64")

		if (CMAKE_GENERATOR MATCHES "Visual Studio")
			set_target_properties(${target} PROPERTIES COMPILE_FLAGS "/wd4814")      # warning about constexpr not being const in c++14
			set_target_properties(${target} PROPERTIES LINK_FLAGS "/INCREMENTAL:NO") # do not generate ILK files
			set_target_properties(${target} PROPERTIES COMPILE_FLAGS "/MP")          # allow parallel builds
		endif ()

		if (EXCLUDE_FROM_COLLECTIVES STREQUAL "yes")
			target_compile_definitions(${target} PRIVATE "-DEXCLUDE_FROM_COLLECTIVES")
		endif()
		
		if (ADD_VERINFO)
			target_sources(${target} PRIVATE "${MAX_SDK_BASE_DIR}/script/verinfo.rc")
		endif()
	endif ()


	# Post Build
	if (APPLE AND NOT "${target}" MATCHES "_test")
		add_custom_command( 
			TARGET ${target} 
			POST_BUILD 
			COMMAND cp "${MAX_SDK_BASE_DIR}/script/PkgInfo" "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${${target}_EXTERN_OUTPUT_NAME}.mxo/Contents/PkgInfo" 
			COMMENT "Copy PkgInfo" 
		)
	endif ()

endfunction()
