cmake_minimum_required(VERSION 3.20)

if(NOT DEFINED EXE_PATH OR EXE_PATH STREQUAL "")
  message(FATAL_ERROR "EXE_PATH is not set")
endif()
if(NOT DEFINED DST_DIR OR DST_DIR STREQUAL "")
  message(FATAL_ERROR "DST_DIR is not set")
endif()

if(NOT DEFINED SEARCH_DIRS OR SEARCH_DIRS STREQUAL "")
  set(SEARCH_DIRS "")
endif()
if(NOT DEFINED PLUGIN_DIR OR PLUGIN_DIR STREQUAL "")
  set(PLUGIN_DIR "")
endif()
if(NOT DEFINED PLUGIN_DST_SUBDIR OR PLUGIN_DST_SUBDIR STREQUAL "")
  set(PLUGIN_DST_SUBDIR "")
endif()
if(NOT DEFINED COPY_PDB)
  set(COPY_PDB 0)
endif()
if(NOT DEFINED EXCLUDE_REGEXES OR EXCLUDE_REGEXES STREQUAL "")
  set(EXCLUDE_REGEXES "")
endif()

# 防御：去掉误传的引号 & 把 \; 还原成 ;
string(REPLACE "\"" "" EXE_PATH "${EXE_PATH}")
string(REPLACE "\"" "" DST_DIR "${DST_DIR}")
string(REPLACE "\\;" ";" SEARCH_DIRS "${SEARCH_DIRS}")

execute_process(COMMAND "${CMAKE_COMMAND}" -E make_directory "${DST_DIR}")

function(_should_exclude _path _out)
  set(${_out} FALSE PARENT_SCOPE)
  if(EXCLUDE_REGEXES)
    foreach(_re IN LISTS EXCLUDE_REGEXES)
      if(_path MATCHES "${_re}")
        set(${_out} TRUE PARENT_SCOPE)
        return()
      endif()
    endforeach()
  endif()
endfunction()

# 1) 收集插件 dll
set(_plugin_dlls "")
if(PLUGIN_DIR AND IS_DIRECTORY "${PLUGIN_DIR}")
  file(GLOB _plugin_dlls "${PLUGIN_DIR}/*.dll")
endif()

# 2) 用 dumpbin 扫运行时依赖（需要在 VS 开发环境里）
find_program(_dumpbin_exe dumpbin)
if(NOT _dumpbin_exe)
  message(WARNING "dumpbin not found. Skip GET_RUNTIME_DEPENDENCIES; only copy plugins (if any).")
else()
  set(_resolved "")
  set(_unresolved "")

  file(GET_RUNTIME_DEPENDENCIES
    EXECUTABLES "${EXE_PATH}"
    LIBRARIES   ${_plugin_dlls}
    DIRECTORIES ${SEARCH_DIRS}

    PRE_EXCLUDE_REGEXES
      "api-ms-win-.*"
      "ext-ms-.*"
    POST_EXCLUDE_REGEXES
      ".*[\\\\/]System32[\\\\/].*"
      ".*[\\\\/]Windows[\\\\/].*"
      ".*[\\\\/]Microsoft[\\\\/].*"

    RESOLVED_DEPENDENCIES_VAR _resolved
    UNRESOLVED_DEPENDENCIES_VAR _unresolved
  )

  foreach(dll IN LISTS _resolved)
    _should_exclude("${dll}" _skip)
    if(_skip)
      continue()
    endif()

    execute_process(COMMAND "${CMAKE_COMMAND}" -E copy_if_different
      "${dll}" "${DST_DIR}"
    )

    if(COPY_PDB)
      get_filename_component(_dir "${dll}" DIRECTORY)
      get_filename_component(_name "${dll}" NAME_WE)
      set(_pdb "${_dir}/${_name}.pdb")
      if(EXISTS "${_pdb}")
        _should_exclude("${_pdb}" _skip_pdb)
        if(NOT _skip_pdb)
          execute_process(COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "${_pdb}" "${DST_DIR}"
          )
        endif()
      endif()
    endif()
  endforeach()

  if(_unresolved)
    message(WARNING "Unresolved runtime dependencies:\n  ${_unresolved}")
  endif()
endif()

# 3) 拷贝插件到 exe 同级目录下的 osgPlugins-3.6.5/
if(_plugin_dlls AND PLUGIN_DST_SUBDIR)
  set(_plugin_dst "${DST_DIR}/${PLUGIN_DST_SUBDIR}")
  execute_process(COMMAND "${CMAKE_COMMAND}" -E make_directory "${_plugin_dst}")

  foreach(p IN LISTS _plugin_dlls)
    _should_exclude("${p}" _skip_p)
    if(_skip_p)
      continue()
    endif()

    execute_process(COMMAND "${CMAKE_COMMAND}" -E copy_if_different
      "${p}" "${_plugin_dst}"
    )
  endforeach()
endif()
