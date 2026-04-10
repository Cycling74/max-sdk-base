include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/GitRevision.cmake")

#[[ Parse package manifest file for information ]]
function (c74::package::info)
  cmake_parse_arguments(PARSE_ARGV 0 ARG "" "MANIFEST;DIRECTORY" "")
  cmake_language(CALL c74::requires MANIFEST)
  message(TRACE "Parsing ${package-info}")
  file(READ "${package-info}" metadata)

  string(JSON author ERROR_VARIABLE author.error GET "${metadata}" "author")
  string(JSON version ERROR_VARIABLE version.error GET "${metadata}" "version")
  string(JSON extra ERROR_VARIABLE extra.error GET "${metadata}" "package_extra")
  string(JSON domain ERROR_VARIABLE domain.error GET "${metadata}" "reverse_domain")
  string(JSON copyright ERROR_VARIABLE copyright.error GET "${metadata}" "copyright")
  string(JSON verinfo ERROR_VARIABLE verinfo.error GET "${metadata}" "add_verinfo")
  string(JSON exclude ERROR_VARIABLE exclude.error GET "${metadata}" "exclude_from_collectives")

  if (author.error)
    message(FATAL_ERROR "'${package-info}' is missing an \"author\" field")
  endif()

  if (version.error)
    cmake_language(CALL c74::git::describe GIT_DESCRIBE)
    cmake_language(CALL c74::git::version::parse "${GIT_DESCRIBE}" GIT_VERSION)
    set(version "${GIT_VERSION_MAJ}.${GIT_VERSION_MIN}.${GIT_VERSION_SUB}")
  endif()

  if (domain.error)
    message(TRACE "Error when reading field 'domain': ${domain.error}")
    set(domain "com.example.${PROJECT_NAME}")
  endif()

  if (copyright.error)
    message(TRACE "Error when reading field 'copyright': ${copyright.error}")
    set(copyright "Copyright (c) 1974 Acme Inc.")
  endif()

  if (verinfo.error OR NOT verinfo STREQUAL "true")
    set(verinfo NO)
  endif()

  if (exclude.error)
    set(exclude NO)
  endif()

  if (NOT ARG_DIRECTORY)
    set(ARG_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
  endif()

  set_property(DIRECTORY "${ARG_DIRECTORY}" PROPERTY max::package::author "${author}")
  set_property(DIRECTORY "${ARG_DIRECTORY}" PROPERTY max::package::version ${version})
  set_property(DIRECTORY "${ARG_DIRECTORY}" PROPERTY max::package::extra ${extra})
  set_property(DIRECTORY "${ARG_DIRECTORY}" PROPERTY max::package::domain ${domain})
  set_property(DIRECTORY "${ARG_DIRECTORY}" PROPERTY max::package::copyright ${copyright})
  set_property(DIRECTORY "${ARG_DIRECTORY}" PROPERTY max::package::add_verinfo ${verinfo})
  set_property(DIRECTORY "${ARG_DIRECTORY}" PROPERTY max::package::exclude_from_collectives ${exclude})
endfunction()
