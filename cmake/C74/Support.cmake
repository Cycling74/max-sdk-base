include_guard(GLOBAL)

#[[
Provide any expression to the function and it will error if it cannot be
evaluated.
]]
macro (c74::requires name)
  if (NOT ARG_${name})
    message(FATAL_ERROR "function '${CMAKE_CURRENT_FUNCTION}' requires a '${name}' argument")
  endif()
endmacro()
