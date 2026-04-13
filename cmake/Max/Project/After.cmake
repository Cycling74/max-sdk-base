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

# If the directory sets max::sources, use that list; otherwise glob everything.
get_property(_explicit_sources DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" PROPERTY max::sources)
if(_explicit_sources)
    set(${_tgt}_SOURCES ${_explicit_sources})
else()
    file(GLOB ${_tgt}_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/*.h"
         "${CMAKE_CURRENT_SOURCE_DIR}/*.c" "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp")
endif()
unset(_explicit_sources)

add_library(${_tgt} MODULE)

target_sources(
    ${_tgt}
    PRIVATE
        ${${_tgt}_SOURCES}
        $<$<AND:$<BOOL:$<TARGET_PROPERTY:MAX_PACKAGE_VERSION_INFO>>,$<PLATFORM_ID:Windows>>:${MAXSDK_BASE_DIR}/script/verinfo.rc>
)

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

set_target_properties(${_tgt} PROPERTIES OUTPUT_NAME "${_output_name}" PREFIX "")

if(APPLE)
    if(NOT DEFINED GIT_VERSION_TAG)
        include(C74/GitRevision)
        cmake_language(CALL c74::git::describe _raw_tag)
        cmake_language(CALL c74::git::version::parse "${_raw_tag}" _v)
        set(GIT_VERSION_TAG "${_v_MAJ}.${_v_MIN}.${_v_SUB}")
        unset(_raw_tag _v_MAJ _v_MIN _v_SUB _v_MOD)
    endif()
    if(NOT DEFINED BUNDLE_IDENTIFIER)
        set(BUNDLE_IDENTIFIER [[${PRODUCT_NAME:rfc1034identifier}]])
    endif()
    if(NOT DEFINED AUTHOR_DOMAIN)
        set(AUTHOR_DOMAIN "com.acme")
    endif()

    set(_scripts "${MAXSDK_BASE_DIR}/script")
    set_target_properties(
        ${_tgt}
        PROPERTIES BUNDLE TRUE
                   BUNDLE_EXTENSION "mxo"
                   XCODE_ATTRIBUTE_WRAPPER_EXTENSION "mxo"
                   MACOSX_BUNDLE_BUNDLE_VERSION "${GIT_VERSION_TAG}"
                   MACOSX_BUNDLE_INFO_PLIST "${_scripts}/Info.plist.in"
                   XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${AUTHOR_DOMAIN}.${BUNDLE_IDENTIFIER}")
    add_custom_command(
        TARGET ${_tgt}
        POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${_scripts}/PkgInfo"
                "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${_output_name}.mxo/Contents/PkgInfo")
    unset(_scripts)
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
            unset(_security_output)
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
    # ADD_VERINFO global set by max-package.cmake (legacy compat)
    if(ADD_VERINFO)
        target_sources(${_tgt} PRIVATE "${MAXSDK_BASE_DIR}/script/verinfo.rc")
    endif()
endif()

unset(_output_name)
unset(_tgt)
