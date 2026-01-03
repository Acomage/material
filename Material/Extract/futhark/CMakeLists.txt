cmake_minimum_required(VERSION 3.24)

project(color_extract LANGUAGES C CXX)

# ------------------------------------------------------------------------------
# 基本设置
# ------------------------------------------------------------------------------
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(_OPT_FLAGS
    -O3
    -march=native
    -mtune=native
    -ffast-math
    -fstrict-aliasing
    -funroll-loops
    -fomit-frame-pointer
    -DNDEBUG
)

# ------------------------------------------------------------------------------
# 外部工具
# ------------------------------------------------------------------------------
find_program(FUTHARK_EXECUTABLE futhark REQUIRED)
find_program(ISPC_EXECUTABLE ispc REQUIRED)

# ------------------------------------------------------------------------------
# TurboJPEG
# ------------------------------------------------------------------------------
find_path(TURBOJPEG_INCLUDE_DIR turbojpeg.h)
find_library(TURBOJPEG_LIBRARY turbojpeg)

if(NOT TURBOJPEG_INCLUDE_DIR OR NOT TURBOJPEG_LIBRARY)
    message(FATAL_ERROR "libturbojpeg (turbojpeg.h / libturbojpeg) not found")
endif()

# ------------------------------------------------------------------------------
# Lean include
# ------------------------------------------------------------------------------
set(LEAN_INCLUDE_DIR
    "$ENV{HOME}/.elan/toolchains/leanprover--lean4---v4.27.0-rc1/include"
    CACHE PATH "Lean include directory"
)

# ------------------------------------------------------------------------------
# Futhark 生成
# ------------------------------------------------------------------------------
set(GENERATED_PREFIX "${CMAKE_BINARY_DIR}/extract")

set(FUTHARK_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/src/extract.fut"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/celebi.fut"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/wu.fut"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/wsmeans.fut"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/color.fut"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/hct.fut"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/score.fut"
)

add_custom_command(
    OUTPUT
        "${GENERATED_PREFIX}.c"
        "${GENERATED_PREFIX}.h"
        "${GENERATED_PREFIX}.kernels.ispc"
    COMMAND
        "${FUTHARK_EXECUTABLE}"
        ispc
        --library
        "${CMAKE_CURRENT_SOURCE_DIR}/src/extract.fut"
        -o "${GENERATED_PREFIX}"
    DEPENDS ${FUTHARK_SOURCES}
    COMMENT "Generating Futhark C/ISPC sources"
    VERBATIM
)

add_custom_command(
    OUTPUT "${GENERATED_PREFIX}.kernels.o"
    COMMAND
        "${ISPC_EXECUTABLE}"
        -O3
        --addressing=32
        --pic
        --woff
        -o "${GENERATED_PREFIX}.kernels.o"
        "${GENERATED_PREFIX}.kernels.ispc"
    DEPENDS "${GENERATED_PREFIX}.kernels.ispc"
    COMMENT "Compiling ISPC kernels"
    VERBATIM
)

add_custom_target(futhark_codegen
    DEPENDS
        "${GENERATED_PREFIX}.c"
        "${GENERATED_PREFIX}.h"
        "${GENERATED_PREFIX}.kernels.ispc"
)

add_custom_target(ispc_codegen
    DEPENDS "${GENERATED_PREFIX}.kernels.o"
)

# ------------------------------------------------------------------------------
# Futhark runtime object
# ------------------------------------------------------------------------------
add_library(futhark_runtime OBJECT "${GENERATED_PREFIX}.c")
add_dependencies(futhark_runtime futhark_codegen)

target_include_directories(futhark_runtime PUBLIC "${CMAKE_BINARY_DIR}")
target_compile_options(futhark_runtime PRIVATE ${_OPT_FLAGS})
set_property(TARGET futhark_runtime PROPERTY POSITION_INDEPENDENT_CODE ON)

# ------------------------------------------------------------------------------
# ISPC object (imported .o)
# ------------------------------------------------------------------------------
add_library(ispc_objects OBJECT IMPORTED)
set_property(
    TARGET ispc_objects
    PROPERTY IMPORTED_OBJECTS "${GENERATED_PREFIX}.kernels.o"
)
add_dependencies(ispc_objects ispc_codegen)

# ------------------------------------------------------------------------------
# Blend2D (vendored static library)
# ------------------------------------------------------------------------------
set(BLEND2D_STATIC TRUE CACHE BOOL "Build Blend2D as static library" FORCE)
set(BLEND2D_BUILD_SHARED FALSE CACHE BOOL "" FORCE)
set(BLEND2D_BUILD_TESTS FALSE CACHE BOOL "" FORCE)
set(BLEND2D_BUILD_EXAMPLES FALSE CACHE BOOL "" FORCE)

add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/src/blend2d")

# ------------------------------------------------------------------------------
# 最终静态库
# ------------------------------------------------------------------------------
add_library(color_extract STATIC
    src/color_extract_ffi.c
)

add_dependencies(color_extract
    futhark_codegen
    ispc_codegen
)

# 合并 Futhark / ISPC 对象
target_sources(color_extract PRIVATE
    $<TARGET_OBJECTS:futhark_runtime>
    $<TARGET_OBJECTS:ispc_objects>
)

# include paths
target_include_directories(color_extract PRIVATE
    "${CMAKE_BINARY_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
    "${TURBOJPEG_INCLUDE_DIR}"
    "${LEAN_INCLUDE_DIR}"
)

# 链接 Blend2D (传播 include + 使用 libblend2d.a)
target_link_libraries(color_extract PRIVATE blend2d::blend2d)

# 编译选项
target_compile_options(color_extract PRIVATE ${_OPT_FLAGS})
set_property(TARGET color_extract PROPERTY POSITION_INDEPENDENT_CODE ON)

