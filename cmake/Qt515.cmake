# cmake/Qt515.cmake
include_guard(GLOBAL)

set(QT_ROOT "${CMAKE_SOURCE_DIR}/thirdparty/Qt-5.15.12" CACHE PATH "Qt 5.15.12 MSVC root")
list(APPEND CMAKE_PREFIX_PATH "${QT_ROOT}")

find_package(Qt5 REQUIRED COMPONENTS Widgets OpenGL)

# 让 Qt 的 moc/uic/rcc 生效（放模块里，顶层就不用管）
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

function(target_use_qt515 target)
  target_link_libraries(${target} PRIVATE Qt5::Widgets Qt5::OpenGL)
  # Qt include 不需要你手动加，Qt5::Widgets 会带
endfunction()

function(qt515_get_windeployqt out_var)
  set(${out_var} "${QT_ROOT}/bin/windeployqt.exe" PARENT_SCOPE)
endfunction()
