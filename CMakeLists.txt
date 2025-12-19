cmake_minimum_required(VERSION 3.20)
project(QtOsgDemo LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Qt 的 moc（你的 main.cpp 末尾有 #include "main.moc"）
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

# =========================
# 1) Qt 路径（你本地 thirdparty）
# =========================
set(QT_ROOT "${CMAKE_SOURCE_DIR}/thirdparty/Qt-5.15.12" CACHE PATH "Qt root")
list(APPEND CMAKE_PREFIX_PATH "${QT_ROOT}")

find_package(Qt5 REQUIRED COMPONENTS Widgets OpenGL)

# =========================
# 2) OSG 路径（你本地 thirdparty）
# =========================
set(OSG_ROOT "${CMAKE_SOURCE_DIR}/thirdparty/osg-3.6.5" CACHE PATH "OSG root")

# 典型 vcpkg export 结构：
#   include/
#   lib/        (Release .lib)
#   debug/lib/  (Debug .lib)
set(OSG_INC_DIR         "${OSG_ROOT}/include")
set(OSG_LIB_RELEASE_DIR "${OSG_ROOT}/lib")
set(OSG_LIB_DEBUG_DIR   "${OSG_ROOT}/debug/lib")

# =========================
# 3) 目标
# =========================
add_executable(qt_osg_demo
  src/main.cpp
)

target_include_directories(qt_osg_demo PRIVATE
  "${OSG_INC_DIR}"
)

# 如果你希望 exe 固定输出到 bin（可选）
set_target_properties(qt_osg_demo PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/bin"
)

# =========================
# 4) 链接：Qt + OSG（按 Debug/Release 区分）
# =========================
target_link_libraries(qt_osg_demo PRIVATE
  Qt5::Widgets
  Qt5::OpenGL

  "$<$<CONFIG:Debug>:${OSG_LIB_DEBUG_DIR}/osgd.lib>"
  "$<$<CONFIG:Release>:${OSG_LIB_RELEASE_DIR}/osg.lib>"

  "$<$<CONFIG:Debug>:${OSG_LIB_DEBUG_DIR}/osgDBd.lib>"
  "$<$<CONFIG:Release>:${OSG_LIB_RELEASE_DIR}/osgDB.lib>"

  "$<$<CONFIG:Debug>:${OSG_LIB_DEBUG_DIR}/osgUtild.lib>"
  "$<$<CONFIG:Release>:${OSG_LIB_RELEASE_DIR}/osgUtil.lib>"

  "$<$<CONFIG:Debug>:${OSG_LIB_DEBUG_DIR}/osgViewerd.lib>"
  "$<$<CONFIG:Release>:${OSG_LIB_RELEASE_DIR}/osgViewer.lib>"

  "$<$<CONFIG:Debug>:${OSG_LIB_DEBUG_DIR}/osgGAd.lib>"
  "$<$<CONFIG:Release>:${OSG_LIB_RELEASE_DIR}/osgGA.lib>"

  "$<$<CONFIG:Debug>:${OSG_LIB_DEBUG_DIR}/OpenThreadsd.lib>"
  "$<$<CONFIG:Release>:${OSG_LIB_RELEASE_DIR}/OpenThreads.lib>"
)


if(WIN32)
  set(WINDEPLOYQT "${QT_ROOT}/bin/windeployqt.exe")

  add_custom_command(TARGET qt_osg_demo POST_BUILD
    COMMAND "${CMAKE_COMMAND}" -E chdir "$<TARGET_FILE_DIR:qt_osg_demo>"
            "${WINDEPLOYQT}"
            "$<$<CONFIG:Debug>:--debug>$<$<NOT:$<CONFIG:Debug>>:--release>"
            --no-translations
            --no-system-d3d-compiler
            "$<TARGET_FILE:qt_osg_demo>"
    VERBATIM
  )
endif()
