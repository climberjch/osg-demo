# cmake/DeployRuntime.cmake
include_guard(GLOBAL)

include(Qt515)
include(OSG365)

# 把 list 转成 a\;b\;c，避免 VS/Ninja 把 ; 拆参
function(_join_dirs_for_cmd out_var)
  string(JOIN "\\;" _joined ${ARGN})
  set(${out_var} "${_joined}" PARENT_SCOPE)
endfunction()

function(target_deploy_runtime target)
  if(NOT WIN32)
    return()
  endif()

  # ---- Qt: windeployqt ----
  qt515_get_windeployqt(_windeployqt)

  add_custom_command(TARGET ${target} POST_BUILD
    # 如果此时你的 exe 还不是 Qt 程序，windeployqt 会报 "not Qt executable"
    # 为了不阻塞构建：失败就忽略（等你真正用了 QApplication 再改成严格）
    COMMAND cmd /c "\"${_windeployqt}\" $<$<CONFIG:Debug>:--debug>$<$<CONFIG:Release>:--release> --no-translations --no-system-d3d-compiler \"$<TARGET_FILE:${target}>\" || exit /b 0"
    VERBATIM
  )

  # ---- OSG: 依赖扫描 + 插件复制 ----
  osg365_get_runtime_dirs(_dirs _plugin_dir _plugin_subdir)
  _join_dirs_for_cmd(_search_arg ${_dirs})

  add_custom_command(TARGET ${target} POST_BUILD
    COMMAND "${CMAKE_COMMAND}"
      -DEXE_PATH=$<TARGET_FILE:${target}>
      -DDST_DIR=$<TARGET_FILE_DIR:${target}>
      -DSEARCH_DIRS=${_search_arg}
      -DPLUGIN_DIR=${_plugin_dir}
      -DPLUGIN_DST_SUBDIR=${_plugin_subdir}
      -DCOPY_PDB=1
      # 避免把 Qt 的 dll 再复制一份（Qt 已 note: windeployqt 做了）
      -DEXCLUDE_REGEXES=.*[\\/]thirdparty[\\/]Qt-5\\.15\\.12[\\/].*
      -P "${CMAKE_SOURCE_DIR}/cmake/copy_runtime_deps.cmake"
    VERBATIM
  )
endfunction()
