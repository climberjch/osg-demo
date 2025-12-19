cmake_minimum_required(VERSION 3.20)
project(MyOsgDemo LANGUAGES CXX)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# =======================
# 输出目录：按配置隔离（推荐）
# =======================
if(CMAKE_CONFIGURATION_TYPES) # VS / Multi-config
  foreach(cfg IN LISTS CMAKE_CONFIGURATION_TYPES)
    string(TOUPPER "${cfg}" CFG_UP)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${CFG_UP} "${CMAKE_SOURCE_DIR}/bin/${cfg}")
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${CFG_UP} "${CMAKE_SOURCE_DIR}/bin/${cfg}")
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${CFG_UP} "${CMAKE_SOURCE_DIR}/lib/${cfg}")
  endforeach()
else() # Ninja / Makefiles
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/bin")
  set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/bin")
  set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/lib")
endif()

# =======================
# Qt 5.15.12
# =======================
set(QT_ROOT "${PROJECT_SOURCE_DIR}/thirdparty/Qt-5.15.12" CACHE PATH "Qt 5.15.12 MSVC root")
message(STATUS "Using QT_ROOT = ${QT_ROOT}")

list(APPEND CMAKE_PREFIX_PATH "${QT_ROOT}")
find_package(Qt5 REQUIRED COMPONENTS Widgets OpenGL)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

# =======================
# OSG thirdparty（vcpkg export 出来的目录）
# =======================
set(OSG_THIRDPARTY_ROOT "${PROJECT_SOURCE_DIR}/thirdparty/osg-3.6.5" CACHE PATH "OSG thirdparty root")
message(STATUS "Using OSG_THIRDPARTY_ROOT = ${OSG_THIRDPARTY_ROOT}")

set(OSG_LIB_RELEASE_DIR "${OSG_THIRDPARTY_ROOT}/lib")
set(OSG_LIB_DEBUG_DIR   "${OSG_THIRDPARTY_ROOT}/debug/lib")
set(OSG_BIN_RELEASE_DIR "${OSG_THIRDPARTY_ROOT}/bin")
set(OSG_BIN_DEBUG_DIR   "${OSG_THIRDPARTY_ROOT}/debug/bin")

# OSG 插件目录名（通常是 osgPlugins-3.6.5）
set(OSG_PLUGIN_SUBDIR "osgPlugins-3.6.5" CACHE STRING "OSG plugin folder name")
set(OSG_PLUGIN_RELEASE_DIR "${OSG_THIRDPARTY_ROOT}/plugins/${OSG_PLUGIN_SUBDIR}")
set(OSG_PLUGIN_DEBUG_DIR   "${OSG_THIRDPARTY_ROOT}/debug/plugins/${OSG_PLUGIN_SUBDIR}")

# =======================
# 可执行文件
# =======================
add_executable(my_osg_export_demo
  src/main.cpp
)

# OSG include 用 target 级别，别用 include_directories 污染全局
target_include_directories(my_osg_export_demo PRIVATE
  "${OSG_THIRDPARTY_ROOT}/include"
)

# Qt link（Qt 的 include 路径会自动带上，一般不需要手动 target_include_directories Qt）
target_link_libraries(my_osg_export_demo PRIVATE
  Qt5::Widgets
  Qt5::OpenGL
)

# =======================
# 链接 OSG libs（Debug/Release 分离）
# =======================
target_link_libraries(my_osg_export_demo PRIVATE
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

# =======================
# 部署：Qt 用 windeployqt
# =======================
#if(WIN32)
  #set(WINDEPLOYQT "${QT_ROOT}/bin/windeployqt.exe")

  #add_custom_command(TARGET my_osg_export_demo POST_BUILD
   # COMMAND "${WINDEPLOYQT}"
    #  $<$<CONFIG:Debug>:--debug>$<$<CONFIG:Release>:--release>
      #--no-translations
     # --no-system-d3d-compiler
     # "$<TARGET_FILE:my_osg_export_demo>"
   # VERBATIM
#  )
#endif()

# =======================
# 部署：OSG 运行时 dll + 插件 + 插件依赖（用你的脚本）
# =======================
if(WIN32)
  add_custom_command(TARGET my_osg_export_demo POST_BUILD
    COMMAND "${CMAKE_COMMAND}"
      -DEXE_PATH="$<TARGET_FILE:my_osg_export_demo>"
      -DDST_DIR="$<TARGET_FILE_DIR:my_osg_export_demo>"
      -DSEARCH_DIRS="${OSG_BIN_RELEASE_DIR};${OSG_BIN_DEBUG_DIR};${OSG_PLUGIN_RELEASE_DIR};${OSG_PLUGIN_DEBUG_DIR}"
      -DPLUGIN_DIR="$<IF:$<CONFIG:Debug>,${OSG_PLUGIN_DEBUG_DIR},${OSG_PLUGIN_RELEASE_DIR}>"
      -DPLUGIN_DST_SUBDIR="${OSG_PLUGIN_SUBDIR}"
      -DCOPY_PDB=1
      # 如果你不想让脚本把 Qt 的 dll 也复制一份，可以打开下面这条（按你路径调整）
       -DEXCLUDE_REGEXES=".*[\\\\/]thirdparty[\\\\/]Qt-5\\.15\\.12[\\\\/].*"
      -P "${CMAKE_SOURCE_DIR}/cmake/copy_runtime_deps.cmake"
    VERBATIM
  )
endif()
