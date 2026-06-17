include_guard(GLOBAL)

if(NOT DEFINED C74_CXX_STANDARD)
    set(C74_CXX_STANDARD 0)
endif()

option(MAX_SDK_CODESIGN_EXTERNS "Sign macOS externs during build" ON)
# Use MAX_SDK_CODESIGN_IDENTITY to override the default ad-hoc identity "-"
# e.g. -DMAX_SDK_CODESIGN_IDENTITY="Developer ID Application: ..."

option(MAX_SDK_PACKAGE_OUT_OF_TREE
    "Output externals/extensions into a package layout inside the build tree instead of the source tree"
    OFF)

set(CMAKE_MSVC_DEBUG_INFORMATION_FORMAT "$<$<CONFIG:Debug,RelWithDebInfo>:ProgramDatabase>")
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

# CMake 4.0 Adds CMAKE_MSVC_RUNTIME_CHECKS, like:
# set(CMAKE_MSVC_RUNTIME_CHECKS "$<$<CONFIG:Debug,RelWithDebInfo>:StackFrameErrorCheck;UninitializedVariable>")
add_compile_options($<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:MSVC>>:/RTC1>)

set_property(DIRECTORY PROPERTY BUNDLE_EXTENSION "mxo")

if(DEFINED C74_LIBRARY_OUTPUT_DIRECTORY)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${C74_LIBRARY_OUTPUT_DIRECTORY}")
elseif(MAX_SDK_PACKAGE_OUT_OF_TREE)
    if(NOT DEFINED C74_BUILD_MAX_EXTENSION)
        set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/package/externals")
    else()
        set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/package/extensions")
    endif()
elseif(NOT DEFINED C74_BUILD_MAX_EXTENSION)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/externals")
else()
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/extensions")
endif()
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}")

if(MAX_SDK_PACKAGE_OUT_OF_TREE)
    set(C74_PACKAGE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/package")
else()
    set(C74_PACKAGE_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}")
endif()

if(MAX_SDK_PACKAGE_OUT_OF_TREE)
    # Stage authored content into the build-tree package at configure time.
    set(_c74_stage_dirs
        clippings           # patchers accessible via "Paste From..." contextual menu
        code                # Gen patchers
        collections         # File Browser collections linked to the package
        default-definitions # definition metadata for Object Defaults in UI externals
        default-settings    # saved color scheme configurations
        devices             # Max for Live device files (AMXDs)
        docs                # reference pages and instructional vignettes
        examples            # sample patchers with supporting materials
        extras              # patchers appearing in the Extras menu
        fonts               # custom typeface files
        help                # help patchers and associated resources
        init                # text files processed by Max during launch
        interfaces          # integration files for toolbar display and Max connectivity
        java-classes        # compiled Java components (lib subfolder for .jar files)
        java-doc            # Java documentation
        javascript          # JS script files
        jsextensions        # JS enhancements via externals or scripts
        jsui                # JSUI scripts with contextual menu integration
        media               # multimedia assets
        misc                # general-purpose content
        object-icons        # SVG icon files for specific objects
        object-prototypes   # UI object prototype options
        patchers            # reusable abstractions and patchers
        projects            # Max project folders
        snippets            # code snippet associations
        support             # DLL/dylib dependencies
        templates           # template patchers for "File > New From Template"
    )
    set(_c74_stage_files
        package-info.json   # package manifest
        icon.png            # Package Manager display graphic (500x500)
        license.txt         # usage and redistribution terms
        license.md          # usage and redistribution terms
        readme.txt          # package information
        readme.md           # package information
    )

    foreach(_d IN LISTS _c74_stage_dirs)
        if(IS_DIRECTORY "${CMAKE_SOURCE_DIR}/${_d}")
            file(COPY "${CMAKE_SOURCE_DIR}/${_d}" DESTINATION "${CMAKE_BINARY_DIR}/package")
        endif()
    endforeach()
    foreach(_f IN LISTS _c74_stage_files)
        if(EXISTS "${CMAKE_SOURCE_DIR}/${_f}")
            file(COPY "${CMAKE_SOURCE_DIR}/${_f}" DESTINATION "${CMAKE_BINARY_DIR}/package")
        endif()
    endforeach()
endif()

set(CMAKE_PDB_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/pdb/$<CONFIG>")

find_package(MaxSDK REQUIRED)
