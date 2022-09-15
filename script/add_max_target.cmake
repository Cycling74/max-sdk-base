# Copyright 2018 The Max-API Authors. All rights reserved.
# Use of this source code is governed by the MIT License found in the License.md file.


# This command creates a project as well as a libary target with the specified name. 
# The list of sources which is passed will be added to the target. 
#
# Call example: 
# add_max_target(mytarget SOURCES main.cpp asd.cpp)
# 
function(add_max_target target)
	set(sources_arg SOURCES)
	cmake_parse_arguments(PARSE_ARGV 0 PARAMS "${options}" "${oneValueArgs}" "${sources_arg}")

	if (WIN32)
		# These must be prior to the "project" command
		# https://stackoverflow.com/questions/14172856/compile-with-mt-instead-of-md-using-cmake

		if (CMAKE_GENERATOR MATCHES "Visual Studio")
			set(CMAKE_C_FLAGS_DEBUG            "/D_DEBUG /MTd /Zi /Ob0 /Od /RTC1")
			set(CMAKE_C_FLAGS_MINSIZEREL       "/MT /O1 /Ob1 /D NDEBUG")
			set(CMAKE_C_FLAGS_RELEASE          "/MT /O2 /Ob2 /D NDEBUG")
			set(CMAKE_C_FLAGS_RELWITHDEBINFO   "/MT /Zi /O2 /Ob1 /D NDEBUG")

			set(CMAKE_CXX_FLAGS_DEBUG          "/D_DEBUG /MTd /Zi /Ob0 /Od /RTC1")
			set(CMAKE_CXX_FLAGS_MINSIZEREL     "/MT /O1 /Ob1 /D NDEBUG")
			set(CMAKE_CXX_FLAGS_RELEASE        "/MT /O2 /Ob2 /D NDEBUG")
			set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "/MT /Zi /O2 /Ob1 /D NDEBUG")

			add_compile_options(
				$<$<CONFIG:>:/MT>
				$<$<CONFIG:Debug>:/MTd>
				$<$<CONFIG:Release>:/MT>
				$<$<CONFIG:MinSizeRel>:/MT>
				$<$<CONFIG:RelWithDebInfo>:/MT>
			)		
		else()
			set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static")
		endif ()
	endif ()
	
	
	project(${target})


	# Load max-sdk-base path
	get_property(MAX_SDK_BASE_DIR GLOBAL PROPERTY C74_MAX_SDK_BASE_DIR)


	# Set external output name
	if ("${target}" MATCHES ".*_tilde")
		string(REGEX REPLACE "_tilde" "~" EXTERN_OUTPUT_NAME_DEFAULT "${target}")
	else ()
		set(EXTERN_OUTPUT_NAME_DEFAULT "${target}")
	endif ()
	set("${target}_EXTERN_OUTPUT_NAME" "${EXTERN_OUTPUT_NAME_DEFAULT}" CACHE STRING "The name to give to the external output file/directory")
	mark_as_advanced("${target}_EXTERN_OUTPUT_NAME")


	# Set paths
	set(C74_SUPPORT_DIR "${MAX_SDK_BASE_DIR}/c74support")
	set(MAX_SDK_INCLUDES "${C74_SUPPORT_DIR}/max-includes")
	set(MAX_SDK_MSP_INCLUDES "${C74_SUPPORT_DIR}/msp-includes")
	set(MAX_SDK_JIT_INCLUDES "${C74_SUPPORT_DIR}/jit-includes")
	
	
	# Some configuration
	if (APPLE)
		if (CMAKE_OSX_ARCHITECTURES STREQUAL "")
			set(CMAKE_OSX_ARCHITECTURES x86_64)
		endif()
		set(CMAKE_OSX_DEPLOYMENT_TARGET "10.11" CACHE STRING "Minimum OS X deployment version" FORCE)
	endif ()
	if (WIN32)
		set(CMAKE_PDB_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/pdb/$<CONFIG>")

		set(MaxAPI_LIB "${MAX_SDK_INCLUDES}/x64/MaxAPI.lib")
		set(MaxAudio_LIB "${MAX_SDK_MSP_INCLUDES}/x64/MaxAudio.lib")
		set(Jitter_LIB "${MAX_SDK_JIT_INCLUDES}/x64/jitlib.lib")	

		mark_as_advanced(MaxAPI_LIB)
		mark_as_advanced(MaxAudio_LIB)
		mark_as_advanced(Jitter_LIB)

		add_definitions(
			-DMAXAPI_USE_MSCRT
			-DWIN_VERSION
			-D_USE_MATH_DEFINES
		)
	else ()
		file (STRINGS "${MAX_SDK_BASE_DIR}/script/max-linker-flags.txt" C74_SYM_MAX_LINKER_FLAGS)

		set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${C74_SYM_MAX_LINKER_FLAGS}")
		set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${C74_SYM_MAX_LINKER_FLAGS}")
		set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${C74_SYM_MAX_LINKER_FLAGS}")
	endif ()

	
	# Create target 
	add_library(${target} MODULE "${PARAMS_SOURCES}")
	target_link_libraries(${target} PRIVATE max-sdk-base API)
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


	# Output
	if (APPLE)
		find_library(
			MSP_LIBRARY "MaxAudioAPI"
			REQUIRED
			PATHS "${MAX_SDK_MSP_INCLUDES}"
			NO_DEFAULT_PATH
			#only use the specific path above, don't look in system root
			#this enables cross compilation to provide an alternative root
			#but also find this specific path
			NO_CMAKE_FIND_ROOT_PATH
		)
		target_link_libraries(${target} PUBLIC ${MSP_LIBRARY})
		find_library(
			JITTER_LIBRARY "JitterAPI"
			REQUIRED
			PATHS "${MAX_SDK_JIT_INCLUDES}"
			NO_DEFAULT_PATH
			NO_CMAKE_FIND_ROOT_PATH
		)
		target_link_libraries(${target} PUBLIC ${JITTER_LIBRARY})
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

			target_link_libraries(${target} PUBLIC ${MaxAPI_LIB})
			target_link_libraries(${target} PUBLIC ${MaxAudio_LIB})
			target_link_libraries(${target} PUBLIC ${Jitter_LIB})
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
