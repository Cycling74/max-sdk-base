# max-sdk-base

This folder contains the core headers, libs, and script files you will need to compile a C or C++ external object for Max.  It is used by both the [Max Software Development Kit](https://github.com/Cycling74/max-sdk) and [Min-DevKit Package](https://github.com/Cycling74/min-devkit) example packages. Please refer to those repositories for additional documentation and best practices.


## Overview of Contents

* `c74support` : header and lib files
* `cmake` & `script`: resources to be included and used by CMake


## Using max-sdk-base in your project

There are two supported ways to bring max-sdk-base into your external's build.

### FetchContent

Include the following in your base CMakeLists.txt file. CMake will download max-sdk-base automatically at configure time:

```cmake
cmake_minimum_required(VERSION 3.19)

include(FetchContent)
FetchContent_Declare(
    max-sdk-base
    GIT_REPOSITORY https://github.com/Cycling74/max-sdk-base.git
    GIT_TAG        main  # pin to a tag or commit hash for reproducible builds
)
FetchContent_MakeAvailable(max-sdk-base)

# Set up the build hooks before any add_subdirectory that calls project()
list(APPEND CMAKE_MODULE_PATH "${max-sdk-base_SOURCE_DIR}/cmake")
set(CMAKE_PROJECT_INCLUDE_BEFORE "${max-sdk-base_SOURCE_DIR}/cmake/Max/Project/Before.cmake")
set(CMAKE_PROJECT_INCLUDE        "${max-sdk-base_SOURCE_DIR}/cmake/Max/Project/After.cmake")

project(my-package)
add_subdirectory(source/my-external)
```

### Git submodule

Add max-sdk-base as a submodule at a path of your choice, then point CMake at it before your first `project()` call:

```cmake
cmake_minimum_required(VERSION 3.19)

set(MAXSDK_BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/max-sdk-base")
list(APPEND CMAKE_MODULE_PATH "${MAXSDK_BASE_DIR}/cmake")
set(CMAKE_PROJECT_INCLUDE_BEFORE "${MAXSDK_BASE_DIR}/cmake/Max/Project/Before.cmake")
set(CMAKE_PROJECT_INCLUDE        "${MAXSDK_BASE_DIR}/cmake/Max/Project/After.cmake")

include(Max/Targets)

project(my-package)
add_subdirectory(source/my-external)
```

In both cases, the `Max::Max`, `Max::MSP`, and `Max::Jitter` interface targets are available for use with `target_link_libraries`.

See the [max-sdk repository](https://github.com/Cycling74/max-sdk) for a complete example of how to structure the `CMakeLists.txt` for an external object.


## License

See the accompanying `License.md` file.

## Support
 
For support, please use the developer forums at:
http://cycling74.com/forums/