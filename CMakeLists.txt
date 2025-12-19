cmake_minimum_required(VERSION 3.20)

project(MyOsgDemo LANGUAGES CXX)

# 让 VS 有 compile_commands.json，IntelliSense 补全更准
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)


# ====== 导入 QT 5.15.12
set(QT_ROOT "${PROJECT_SOURCE_DIR}/thirdparty/Qt-5.15.12" CACHE PATH "Qt 5.15.12 MSVC root")
message(STATUS "Using QT_ROOT = ${QT_ROOT}")
set(Qt5_DIR "${QT_ROOT}/lib/cmake/Qt5" CACHE PATH "Qt5 CMake package dir")
list(APPEND CMAKE_PREFIX_PATH "${QT_ROOT}")

# Qt Widgets + OpenGL（QOpenGLWindow / QOpenGLWidget 用得到）
find_package(Qt5 REQUIRED COMPONENTS Widgets OpenGL)

# 打开 CMake 中需要 QT 打开的开关
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

# ====== 1. OSG 第三方根目录（vcpkg export 出来的 osg 包） ======
set(OSG_THIRDPARTY_ROOT "${PROJECT_SOURCE_DIR}/thirdparty/osg-3.6.5")
message(STATUS "Using OSG_THIRDPARTY_ROOT = ${OSG_THIRDPARTY_ROOT}")

# 统一把可执行文件都放到项目根的 bin 目录，Debug/Release 一致
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY            "${CMAKE_SOURCE_DIR}/bin")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG      "${CMAKE_SOURCE_DIR}/bin")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE    "${CMAKE_SOURCE_DIR}/bin")

# ====== 2. 头文件路径 ======
include_directories("${OSG_THIRDPARTY_ROOT}/include")

# 假设 vcpkg export 目录结构大致如下（很典型）：
#   osg-3.6.5/
#     include/
#     lib/        <- Release .lib
#     debug/lib/  <- Debug   .lib
#     bin/        <- Release .dll
#     debug/bin/  <- Debug   .dll
set(OSG_LIB_RELEASE_DIR "${OSG_THIRDPARTY_ROOT}/lib")
set(OSG_LIB_DEBUG_DIR   "${OSG_THIRDPARTY_ROOT}/debug/lib")


# 源文件
add_executable(my_osg_export_demo
    src/main.cpp
)

# include QT 的头文件
 target_include_directories(my_osg_export_demo 
 PRIVATE "${QT_ROOT}/include"
)

# 链接 QT 
target_link_libraries(my_osg_export_demo PRIVATE QT5::Qt5::Widgets QT5::Qt5::OpenGL)

# ====== 3. Debug/Release 分别链接各自的 .lib ======
# 说明：
# - 如果你发现 debug 版库名是 osgd.lib / osgDBd.lib 这种，把下面的 osg.lib 换成 osgd.lib 即可。
# - 这里用的是“带路径的库文件”，所以不再需要 link_directories。
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

