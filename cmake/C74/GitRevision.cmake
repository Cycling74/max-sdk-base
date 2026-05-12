include_guard(GLOBAL)

find_package(Git QUIET)

function (c74::git::head::hash outvar)
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" rev-parse --verify HEAD
    OUTPUT_VARIABLE output
    ERROR_VARIABLE error
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_STRIP_TRAILING_WHITESPACE
  )
  set(${outvar} "${output}")
  if (error)
    set(${outvar} "hash-NOTFOUND")
  endif()
  return(PROPAGATE ${outvar})
endfunction()

function (c74::git::head::refspec outvar)
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" symbolic-ref HEAD
    OUTPUT_VARIABLE output
    ERROR_VARIABLE error
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_STRIP_TRAILING_WHITESPACE
  )
  set(${outvar} "${output}")
  if (error)
    set(${outvar} "refspec-NOTFOUND")
  endif()
  return(PROPAGATE ${outvar})
endfunction()

function (c74::git::describe outvar)
  if (NOT GIT_FOUND)
    set(${outvar} "Git-NOTFOUND" PARENT_SCOPE)
    return(PROPAGATE ${outvar})
  endif()
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" describe --always --tags
    OUTPUT_VARIABLE output
    ERROR_VARIABLE error
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_STRIP_TRAILING_WHITESPACE
  )
  set(${outvar} "${output}")
  if (error)
    set(${outvar} "describe-NOTFOUND")
  endif()
  return(PROPAGATE ${outvar})
endfunction()

function (c74::git::version::parse tag out_prefix)
  # Strip 'v' prefix and git describe suffix (-N-gHASH), then split into numeric components
  string(REGEX REPLACE "^[vV]" "" version "${tag}")
  string(REGEX REPLACE "-[0-9]+-g[0-9a-f]+$" "" version "${version}")
  string(REGEX MATCHALL "[0-9]+" parts "${version}")

  set(${out_prefix}_MAJ 0)
  set(${out_prefix}_MIN 0)
  set(${out_prefix}_SUB 0)
  set(${out_prefix}_MOD 0)

  list(LENGTH parts len)
  if (len GREATER 0)
    list(GET parts 0 ${out_prefix}_MAJ)
  endif()
  if (len GREATER 1)
    list(GET parts 1 ${out_prefix}_MIN)
  endif()
  if (len GREATER 2)
    list(GET parts 2 ${out_prefix}_SUB)
  endif()
  if (len GREATER 3)
    list(GET parts 3 ${out_prefix}_MOD)
  endif()

  return(PROPAGATE ${out_prefix}_MAJ ${out_prefix}_MIN ${out_prefix}_SUB ${out_prefix}_MOD)
endfunction()
