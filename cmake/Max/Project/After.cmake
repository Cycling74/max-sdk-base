block()

get_property(
    _is_ext
    DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    PROPERTY max::external)
if(NOT _is_ext)
    return()
endif()

set(_tgt "${PROJECT_NAME}")
# Reverse _tilde convention so the output file/bundle carries the real ~ name
string(REPLACE "_tilde" "~" _output_name "${_tgt}")

# max::glob defaults to OFF. Enable with set_property(DIRECTORY PROPERTY max::glob ON) before project().
get_property(_glob_enabled DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" PROPERTY max::glob)

add_library(${_tgt} MODULE)

if(_glob_enabled)
    set(_globs "")
    foreach(_ext IN LISTS CMAKE_C_SOURCE_FILE_EXTENSIONS CMAKE_CXX_SOURCE_FILE_EXTENSIONS)
        list(APPEND _globs "${CMAKE_CURRENT_SOURCE_DIR}/*.${_ext}")
    endforeach()
    file(GLOB_RECURSE _sources CONFIGURE_DEPENDS ${_globs})
    target_sources(${_tgt} PRIVATE ${_sources})
endif()

# Auto-set MAX_PACKAGE_JIT_GL and link OpenGL for jit.gl.* externals
if(_tgt MATCHES "^jit\\.gl\\.")
    set_property(TARGET ${_tgt} PROPERTY MAX_PACKAGE_JIT_GL YES)
    if(APPLE)
        target_link_libraries(${_tgt} PRIVATE "-framework OpenGL")
    elseif(WIN32)
        find_package(OpenGL REQUIRED)
        target_link_libraries(${_tgt} PRIVATE ${OPENGL_LIBRARIES})
    endif()
endif()

target_link_libraries(${_tgt} PRIVATE Max::Max Max::MSP Max::Jitter)

# EXCLUDE_FROM_COLLECTIVES — evaluated at generation time from target property
target_compile_definitions(
    ${_tgt} PRIVATE $<$<BOOL:$<TARGET_PROPERTY:MAX_PACKAGE_EXCLUDE_FROM_COLLECTIVES>>:EXCLUDE_FROM_COLLECTIVES>)

# macOS: apply weak-undefined linker flags per-target (avoids mutating global linker flags)
if(APPLE)
    get_property(
        _flags_file
        TARGET Max::Max
        PROPERTY _MAX_LINKER_FLAGS_FILE)
    file(STRINGS "${_flags_file}" _raw_flags)
    separate_arguments(_flags_list UNIX_COMMAND "${_raw_flags}")
    target_link_options(${_tgt} PRIVATE ${_flags_list})
endif()

if(C74_CXX_STANDARD EQUAL 98)
    if(APPLE)
        target_compile_options(${_tgt} PRIVATE -std=gnu++98 -stdlib=libstdc++)
        target_link_options(${_tgt} PRIVATE -stdlib=libstdc++)
    endif()
else()
    set_target_properties(${_tgt} PROPERTIES CXX_STANDARD 17 CXX_STANDARD_REQUIRED ON)
endif()

if(WIN32)
    set_target_properties(${_tgt} PROPERTIES OUTPUT_NAME "${_output_name}" PREFIX "" SUFFIX ".mxe64")
elseif(UNIX AND NOT APPLE)
    set_target_properties(${_tgt} PROPERTIES OUTPUT_NAME "${_output_name}" PREFIX "" SUFFIX ".mxl_${CMAKE_SYSTEM_PROCESSOR}")
else()
    set_target_properties(${_tgt} PROPERTIES OUTPUT_NAME "${_output_name}" PREFIX "")
endif()

if(APPLE)
    if(NOT DEFINED GIT_VERSION_TAG)
        include(C74/GitRevision)
        cmake_language(CALL c74::git::describe _raw_tag)
        cmake_language(CALL c74::git::version::parse "${_raw_tag}" _v)
        set(GIT_VERSION_TAG "${_v_MAJ}.${_v_MIN}.${_v_SUB}")
    endif()
    if(NOT DEFINED AUTHOR_DOMAIN)
        set(AUTHOR_DOMAIN "com.acme")
    endif()

    set(_scripts "${MAXSDK_SOURCE_DIR}/script")

    set(MACOSX_BUNDLE_EXECUTABLE_NAME "${_output_name}")
    set(PACKAGE_VERSION "${GIT_VERSION_TAG}")
    if(NOT DEFINED EXCLUDE_FROM_COLLECTIVES)
        set(EXCLUDE_FROM_COLLECTIVES "")
    endif()
    if(NOT DEFINED COPYRIGHT_STRING)
        set(COPYRIGHT_STRING "")
    endif()

    if(CMAKE_GENERATOR STREQUAL "Xcode")
        # Xcode expands ${PRODUCT_NAME:rfc1034identifier} at build time.
        # configure_file @ONLY expands @VAR@ placeholders and leaves ${...} alone for Xcode.
        # XCODE_ATTRIBUTE_INFOPLIST_FILE bypasses CMake's own configure_file processing of the plist.
        if(NOT DEFINED BUNDLE_IDENTIFIER)
            set(BUNDLE_IDENTIFIER [[${PRODUCT_NAME:rfc1034identifier}]])
        endif()
        configure_file(
            "${MAXSDK_SOURCE_DIR}/cmake/Info.plist.in"
            "${CMAKE_CURRENT_BINARY_DIR}/${_tgt}_Info.plist"
            @ONLY)
        set_target_properties(
            ${_tgt}
            PROPERTIES BUNDLE TRUE
                       BUNDLE_EXTENSION "mxo"
                       XCODE_ATTRIBUTE_WRAPPER_EXTENSION "mxo"
                       MACOSX_BUNDLE_BUNDLE_VERSION "${GIT_VERSION_TAG}"
                       XCODE_ATTRIBUTE_INFOPLIST_FILE "${CMAKE_CURRENT_BINARY_DIR}/${_tgt}_Info.plist"
                       XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${AUTHOR_DOMAIN}.${BUNDLE_IDENTIFIER}")
    else()
        # Non-Xcode generators: resolve everything at configure time; post-build copy handles the plist.
        if(NOT DEFINED BUNDLE_IDENTIFIER)
            set(BUNDLE_IDENTIFIER "${_output_name}")
        endif()
        configure_file(
            "${MAXSDK_SOURCE_DIR}/cmake/Info.plist.in"
            "${CMAKE_CURRENT_BINARY_DIR}/${_tgt}_Info.plist"
            @ONLY)
        set_target_properties(
            ${_tgt}
            PROPERTIES BUNDLE TRUE
                       BUNDLE_EXTENSION "mxo"
                       MACOSX_BUNDLE_BUNDLE_VERSION "${GIT_VERSION_TAG}")
        add_custom_command(
            TARGET ${_tgt}
            POST_BUILD
            COMMAND "${CMAKE_COMMAND}" -E copy_if_different
                    "${CMAKE_CURRENT_BINARY_DIR}/${_tgt}_Info.plist"
                    "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${_output_name}.mxo/Contents/Info.plist")
    endif()

    add_custom_command(
        TARGET ${_tgt}
        POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${_scripts}/PkgInfo"
                "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${_output_name}.mxo/Contents/PkgInfo")
    if(MAX_SDK_CODESIGN_EXTERNS)
        if(NOT DEFINED MAX_SDK_CODESIGN_IDENTITY)
            set(MAX_SDK_CODESIGN_IDENTITY "-")
            message(STATUS "Code signing with ad-hoc identity")
        else()
            execute_process(COMMAND security find-identity -p codesigning -v
                            OUTPUT_VARIABLE _security_output)
            if(_security_output MATCHES "${MAX_SDK_CODESIGN_IDENTITY}")
                message(STATUS "Code signing identity found, will sign")
            else()
                set(MAX_SDK_CODESIGN_IDENTITY "-")
                message(STATUS "Code signing with ad-hoc identity")
            endif()
        endif()
        add_custom_command(
            TARGET ${_tgt}
            POST_BUILD
            COMMAND codesign -s "${MAX_SDK_CODESIGN_IDENTITY}" -f --deep
                    "$<TARGET_BUNDLE_DIR:${_tgt}>" 2>/dev/null)
    endif()
elseif(WIN32)
    if(CMAKE_GENERATOR MATCHES "Visual Studio")
        # Fix: posttarget.cmake sets COMPILE_FLAGS /wd4814 then clobbers it with /MP
        target_compile_options(${_tgt} PRIVATE /wd4814 /MP)
        set_target_properties(${_tgt} PROPERTIES LINK_FLAGS "/INCREMENTAL:NO")
    endif()
    target_sources(${_tgt} PRIVATE
        $<$<BOOL:$<TARGET_PROPERTY:MAX_PACKAGE_VERSION_INFO>>:${MAXSDK_SOURCE_DIR}/script/verinfo.rc>)
endif()

endblock()
