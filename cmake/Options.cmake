# cmake/Options.cmake
include_guard(GLOBAL)

function(target_apply_common_settings target)
  target_compile_features(${target} PRIVATE cxx_std_17)

  # VS 多配置：把 exe/dll 都统一落到项目 bin/<Config> 下，避免 Debug/Release 混
  if(CMAKE_CONFIGURATION_TYPES)
    set_target_properties(${target} PROPERTIES
      RUNTIME_OUTPUT_DIRECTORY         "${CMAKE_SOURCE_DIR}/bin"
      RUNTIME_OUTPUT_DIRECTORY_DEBUG   "${CMAKE_SOURCE_DIR}/bin/Debug"
      RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_SOURCE_DIR}/bin/Release"
      RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CMAKE_SOURCE_DIR}/bin/RelWithDebInfo"
      RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL "${CMAKE_SOURCE_DIR}/bin/MinSizeRel"
    )
  else()
    # 单配置：都放 bin
    set_target_properties(${target} PROPERTIES
      RUNTIME_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/bin"
    )
  endif()
endfunction()
