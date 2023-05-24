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

set_target_properties(${PROJECT_NAME} PROPERTIES 
	OUTPUT_NAME "${${PROJECT_NAME}_EXTERN_OUTPUT_NAME}"
	#remove the 'lib' prefix for some generators
	PREFIX ""
)

#link libraries except for windows tests
if (NOT (WIN32 AND "${PROJECT_NAME}" MATCHES "_test"))
	target_link_libraries(${PROJECT_NAME} 
		PUBLIC ${MAX_LIBRARY} ${MSP_LIBRARY} ${JITTER_LIBRARY}
		)

	if ("${PROJECT_NAME}" MATCHES "jit.gl.*")
		if (APPLE)
			set(OPENGL_LIBRARIES "-framework OpenGL")
		else ()
			find_package(OpenGL REQUIRED)
			include_directories(${OPENGL_INCLUDE_DIR})
		endif()
		target_link_libraries(${PROJECT_NAME} PUBLIC ${OPENGL_LIBRARIES})
	endif()	
endif()	

### Output ###
if (APPLE)
	set_target_properties(${PROJECT_NAME} PROPERTIES 
		BUNDLE True
		BUNDLE_EXTENSION "mxo"
		XCODE_ATTRIBUTE_WRAPPER_EXTENSION "mxo"
		MACOSX_BUNDLE_BUNDLE_VERSION "${GIT_VERSION_TAG}"
		MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_LIST_DIR}/Info.plist.in
		XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${AUTHOR_DOMAIN}.${BUNDLE_IDENTIFIER}"
	)
elseif (WIN32)
	set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".mxe64")

	if (CMAKE_GENERATOR MATCHES "Visual Studio")
		set_target_properties(${PROJECT_NAME} PROPERTIES 
			# warning about constexpr not being const in c++14
			COMPILE_FLAGS "/wd4814"
			# do not generate ILK files
			LINK_FLAGS "/INCREMENTAL:NO"
			# allow parallel builds
			COMPILE_FLAGS "/MP"
		)
	endif ()

	if (EXCLUDE_FROM_COLLECTIVES STREQUAL "yes")
		target_compile_definitions(${PROJECT_NAME} PRIVATE "-DEXCLUDE_FROM_COLLECTIVES")
	endif()

	if (ADD_VERINFO)
		target_sources(${PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_LIST_DIR}/verinfo.rc)
	endif()
else() 
	set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".mxl_${CMAKE_SYSTEM_PROCESSOR}")
endif()


### Post Build ###

if (APPLE AND NOT "${PROJECT_NAME}" MATCHES "_test")
	add_custom_command( 
		TARGET ${PROJECT_NAME} 
		POST_BUILD 
		COMMAND cp "${CMAKE_CURRENT_LIST_DIR}/PkgInfo" "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${${PROJECT_NAME}_EXTERN_OUTPUT_NAME}.mxo/Contents/PkgInfo" 
		COMMENT "Copy PkgInfo" 
	)
endif ()
