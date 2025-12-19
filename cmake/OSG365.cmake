# cmake/OSG365.cmake
include_guard(GLOBAL)

set(OSG_THIRDPARTY_ROOT "${CMAKE_SOURCE_DIR}/thirdparty/osg-3.6.5" CACHE PATH "OSG thirdparty root")

set(OSG_LIB_RELEASE_DIR "${OSG_THIRDPARTY_ROOT}/lib")
set(OSG_LIB_DEBUG_DIR   "${OSG_THIRDPARTY_ROOT}/debug/lib")
set(OSG_BIN_RELEASE_DIR "${OSG_THIRDPARTY_ROOT}/bin")
set(OSG_BIN_DEBUG_DIR   "${OSG_THIRDPARTY_ROOT}/debug/bin")

# 你机器上的真实插件路径（截图）
set(OSG_PLUGIN_SUBDIR "osgPlugins-3.6.5" CACHE STRING "OSG plugin folder name")
set(OSG_PLUGIN_RELEASE_DIR "${OSG_THIRDPARTY_ROOT}/plugins/${OSG_PLUGIN_SUBDIR}")
set(OSG_PLUGIN_DEBUG_DIR   "${OSG_THIRDPARTY_ROOT}/debug/plugins/${OSG_PLUGIN_SUBDIR}")

function(target_use_osg365 target)
  target_include_directories(${target} PRIVATE
    "${OSG_THIRDPARTY_ROOT}/include"
  )

  target_link_libraries(${target} PRIVATE
    "$<$<CONFIG:Debug>:${OSG_LIB_DEBUG_DIR}/osgd.lib>"
    "$<$<CONFIG:Release>:${OSG_LIB_RELEASE_DIR}/osg.lib>"

    "$<$<CONFIG:Debug>:${OSG_LIB_DEBUG_DIR}/osgGAd.lib>"
    "$<$<CONFIG:Release>:${OSG_LIB_RELEASE_DIR}/osgGA.lib>"

    "$<$<CONFIG:Debug>:${OSG_LIB_DEBUG_DIR}/osgDBd.lib>"
    "$<$<CONFIG:Release>:${OSG_LIB_RELEASE_DIR}/osgDB.lib>"

    "$<$<CONFIG:Debug>:${OSG_LIB_DEBUG_DIR}/osgViewerd.lib>"
    "$<$<CONFIG:Release>:${OSG_LIB_RELEASE_DIR}/osgViewer.lib>"

    "$<$<CONFIG:Debug>:${OSG_LIB_DEBUG_DIR}/OpenThreadsd.lib>"
    "$<$<CONFIG:Release>:${OSG_LIB_RELEASE_DIR}/OpenThreads.lib>"

    "$<$<CONFIG:Debug>:${OSG_LIB_DEBUG_DIR}/osgAnimationd.lib>"
    "$<$<CONFIG:Release>:${OSG_LIB_RELEASE_DIR}/osgAnimation.lib>"

    "$<$<CONFIG:Debug>:${OSG_LIB_DEBUG_DIR}/osgUtild.lib>"
    "$<$<CONFIG:Release>:${OSG_LIB_RELEASE_DIR}/osgUtil.lib>"
  )
endfunction()

function(osg365_get_runtime_dirs out_search_dirs out_plugin_dir out_plugin_subdir)
  # 搜索路径：dll 在 bin/debug/bin，插件在 plugins/debug/plugins
  set(${out_search_dirs}
    "${OSG_BIN_RELEASE_DIR}"
    "${OSG_BIN_DEBUG_DIR}"
    "${OSG_PLUGIN_RELEASE_DIR}"
    "${OSG_PLUGIN_DEBUG_DIR}"
    PARENT_SCOPE
  )
  # 当前配置使用的插件目录（Debug/Release）
  set(${out_plugin_dir}
    "$<IF:$<CONFIG:Debug>,${OSG_PLUGIN_DEBUG_DIR},${OSG_PLUGIN_RELEASE_DIR}>"
    PARENT_SCOPE
  )
  set(${out_plugin_subdir} "${OSG_PLUGIN_SUBDIR}" PARENT_SCOPE)
endfunction()
