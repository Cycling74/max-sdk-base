# max-sdk-base

This folder contains the core headers, libs, and script files you will need to compile a C or C++ external object for Max.  It is used by both the [Max Software Development Kit](https://github.com/Cycling74/max-sdk) and [Min-DevKit Package](https://github.com/Cycling74/min-devkit) example packages. Please refer to those repositories for additional documentation and best practices.


## Overview of Contents

* `c74support` : header and lib files
* `cmake`: CMake modules — the recommended build system integration (see [max-sdk](https://github.com/Cycling74/max-sdk) for examples)
* `script`: legacy CMake scripts, retained for backward compatibility while projects migrate


## Using max-sdk-base in your project

There are two supported ways to bring max-sdk-base into your external's build.

### FetchContent

Include the following in your base CMakeLists.txt file. CMake will download max-sdk-base automatically at configure time:

```cmake
cmake_minimum_required(VERSION 3.25)

include(FetchContent)
FetchContent_Declare(
    max-sdk-base
    GIT_REPOSITORY https://github.com/Cycling74/max-sdk-base.git
    GIT_TAG        main  # pin to a tag or commit hash for reproducible builds
)
FetchContent_MakeAvailable(max-sdk-base)

project(my-package)
add_subdirectory(source/my-external)
```

### Git submodule

Add max-sdk-base as a submodule at a path of your choice, then include it via `add_subdirectory` before your first `project()` call:

```cmake
cmake_minimum_required(VERSION 3.25)

add_subdirectory(max-sdk-base)

project(my-package)
add_subdirectory(source/my-external)
```

In both cases, the `Max::Max`, `Max::MSP`, and `Max::Jitter` imported targets are available for use with `target_link_libraries`.

See the [max-sdk repository](https://github.com/Cycling74/max-sdk) for a complete example of how to structure the `CMakeLists.txt` for an external object.


## CMake Options

### Out-of-tree package build

When `MAX_SDK_PACKAGE_OUT_OF_TREE` is `ON`, the build directory contains a
fully assembled Max package which you can zip up to share with others without
including source code or build-time files. You can also then symlink
`build/package` directly into Max's Packages folder instead of the root
repository, keeping source and build files separate.

Enable it at configure time:

```bash
cmake -B build -DMAX_SDK_PACKAGE_OUT_OF_TREE=ON
cmake --build build
```

Authored content directories (`help`, `init`, `media`, `support`, etc.) are
copied at configure time. These files and directories are described here:
https://docs.cycling74.com/userguide/packages/#package-folder-structure. To
pick up changes to this content in the build directory, re-run cmake.

## License

See the accompanying `License.md` file.

## Support
 
For support, please use the developer forums at:
http://cycling74.com/forums/
