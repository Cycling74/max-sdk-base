

macro(c74_max_pre_project_calls)
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
	
	if (APPLE)
		if (CMAKE_OSX_ARCHITECTURES STREQUAL "")
			set(CMAKE_OSX_ARCHITECTURES x86_64)
		endif()
		set(CMAKE_OSX_DEPLOYMENT_TARGET "10.11" CACHE STRING "Minimum OS X deployment version" FORCE)
	endif ()
endmacro()


macro(c74_set_extern_output_name)
	if ("${PROJECT_NAME}" MATCHES ".*_tilde")
		string(REGEX REPLACE "_tilde" "~" EXTERN_OUTPUT_NAME_DEFAULT "${PROJECT_NAME}")
	else ()
		set(EXTERN_OUTPUT_NAME_DEFAULT "${PROJECT_NAME}")
	endif ()
	set("${PROJECT_NAME}_EXTERN_OUTPUT_NAME" "${EXTERN_OUTPUT_NAME_DEFAULT}" CACHE STRING "The name to give to the external output file/directory")
	mark_as_advanced("${PROJECT_NAME}_EXTERN_OUTPUT_NAME")
endmacro()


macro(c74_set_include_paths)
	get_property(MAX_SDK_BASE_DIR GLOBAL PROPERTY C74_MAX_SDK_BASE_DIR)
	set(C74_SUPPORT_DIR "${MAX_SDK_BASE_DIR}/c74support")
	set(MAX_SDK_INCLUDES "${C74_SUPPORT_DIR}/max-includes")
	set(MAX_SDK_MSP_INCLUDES "${C74_SUPPORT_DIR}/msp-includes")
	set(MAX_SDK_JIT_INCLUDES "${C74_SUPPORT_DIR}/jit-includes")

	set(C74_INCLUDES "${C74_SUPPORT_DIR}" "${MAX_SDK_INCLUDES}" "${MAX_SDK_MSP_INCLUDES}" "${MAX_SDK_JIT_INCLUDES}")
	set(C74_SCRIPTS "${MAX_SDK_BASE_DIR}/script")
endmacro()


macro(c74_max_post_project_calls)
	c74_set_include_paths()
	c74_set_extern_output_name()
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
	elseif (APPLE)
		file (STRINGS "${MAX_SDK_BASE_DIR}/script/max-linker-flags.txt" C74_SYM_MAX_LINKER_FLAGS)

		set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${C74_SYM_MAX_LINKER_FLAGS}")
		set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${C74_SYM_MAX_LINKER_FLAGS}")
		set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${C74_SYM_MAX_LINKER_FLAGS}")
	endif ()
endmacro()