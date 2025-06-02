# Copyright 2018 The Max-API Authors. All rights reserved.
# Use of this source code is governed by the MIT License found in the License.md file.

if (${C74_CXX_STANDARD} EQUAL 98)
	if (APPLE)
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=gnu++98 -stdlib=libstdc++")
		set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -stdlib=libstdc++")
		set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -stdlib=libstdc++")
	endif ()
else ()
	set_property(TARGET ${PROJECT_NAME} PROPERTY CXX_STANDARD 17)
	set_property(TARGET ${PROJECT_NAME} PROPERTY CXX_STANDARD_REQUIRED ON)
endif ()

set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME "${${PROJECT_NAME}_EXTERN_OUTPUT_NAME}")
#remove the 'lib' prefix for some generators
set_target_properties(${PROJECT_NAME} PROPERTIES PREFIX "")



### Output ###
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
	target_link_libraries(${PROJECT_NAME} PUBLIC ${MSP_LIBRARY})
	find_library(
		JITTER_LIBRARY "JitterAPI"
		REQUIRED
		PATHS "${MAX_SDK_JIT_INCLUDES}"
		NO_DEFAULT_PATH
		NO_CMAKE_FIND_ROOT_PATH
	)
	target_link_libraries(${PROJECT_NAME} PUBLIC ${JITTER_LIBRARY})
	if ("${PROJECT_NAME}" MATCHES "jit.gl.*")
		target_link_libraries(${PROJECT_NAME} PUBLIC "-framework OpenGL")
	endif()	
	set_property(TARGET ${PROJECT_NAME}
				 PROPERTY BUNDLE True)
	set_property(TARGET ${PROJECT_NAME}
				 PROPERTY BUNDLE_EXTENSION "mxo")	
	set_target_properties(${PROJECT_NAME} PROPERTIES XCODE_ATTRIBUTE_WRAPPER_EXTENSION "mxo")
	set_target_properties(${PROJECT_NAME} PROPERTIES MACOSX_BUNDLE_BUNDLE_VERSION "${GIT_VERSION_TAG}")
    set_target_properties(${PROJECT_NAME} PROPERTIES MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_LIST_DIR}/Info.plist.in)
	set_target_properties(${PROJECT_NAME} PROPERTIES XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${AUTHOR_DOMAIN}.${BUNDLE_IDENTIFIER}")
elseif (WIN32)
    if ("${PROJECT_NAME}" MATCHES "_test")
    else ()
		if ("${PROJECT_NAME}" MATCHES "jit.gl.*")
			find_package(OpenGL REQUIRED)
			include_directories(${OPENGL_INCLUDE_DIR})
			target_link_libraries(${PROJECT_NAME} PUBLIC ${OPENGL_LIBRARIES})
		endif()

		target_link_libraries(${PROJECT_NAME} PUBLIC ${MaxAPI_LIB})
		target_link_libraries(${PROJECT_NAME} PUBLIC ${MaxAudio_LIB})
		target_link_libraries(${PROJECT_NAME} PUBLIC ${Jitter_LIB})
	endif ()
	
	set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".mxe64")

	if (CMAKE_GENERATOR MATCHES "Visual Studio")
		# warning about constexpr not being const in c++14
		set_target_properties(${PROJECT_NAME} PROPERTIES COMPILE_FLAGS "/wd4814")

		# do not generate ILK files
		set_target_properties(${PROJECT_NAME} PROPERTIES LINK_FLAGS "/INCREMENTAL:NO")

		# allow parallel builds
		set_target_properties(${PROJECT_NAME} PROPERTIES COMPILE_FLAGS "/MP")
	endif ()

	if (EXCLUDE_FROM_COLLECTIVES STREQUAL "yes")
		target_compile_definitions(${PROJECT_NAME} PRIVATE "-DEXCLUDE_FROM_COLLECTIVES")
	endif()

	if (ADD_VERINFO)
		target_sources(${PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_LIST_DIR}/verinfo.rc)
	endif()
else() 
	set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".mxl_${CMAKE_SYSTEM_PROCESSOR}")
endif ()


### Post Build ###

if (APPLE AND NOT "${PROJECT_NAME}" MATCHES "_test")
	add_custom_command( 
		TARGET ${PROJECT_NAME} 
		POST_BUILD 
		COMMAND cp "${CMAKE_CURRENT_LIST_DIR}/PkgInfo" "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${${PROJECT_NAME}_EXTERN_OUTPUT_NAME}.mxo/Contents/PkgInfo" 
		VERBATIM
		COMMENT "Copy PkgInfo" 
	)

	if(MAX_SDK_CODESIGN_EXTERNS)
		if(NOT DEFINED MAX_SDK_CODESIGN_IDENTITY)
			set(MAX_SDK_CODESIGN_IDENTITY "-")
			message(STATUS "Code signing with ad-hoc identity")
		else()
            execute_process(
                COMMAND security find-identity -p codesigning -v
                OUTPUT_VARIABLE security_output
            )
            if (MAX_SDK_CODESIGN_IDENTITY AND security_output MATCHES "${MAX_SDK_CODESIGN_IDENTITY}")
                message(STATUS "Code signing identity found, will sign")		
			else()
				set(MAX_SDK_CODESIGN_IDENTITY "-")
				message(STATUS "Code signing with ad-hoc identity")
			endif()
		endif()
		add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
			COMMAND codesign -s ${MAX_SDK_CODESIGN_IDENTITY} -f --deep $<TARGET_BUNDLE_DIR:${PROJECT_NAME}> 2>/dev/null
		)
	endif()
endif ()
