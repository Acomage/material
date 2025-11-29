import Lake
open Lake DSL System

package "Material" where
  -- 可以在这里添加其他的 package 配置

--------------------------------------------------------------------------------
-- FFI (Foreign Function Interface) 编译配置
--------------------------------------------------------------------------------

-- 定义 C 文件的编译目标
-- 这会编译 Image/c/bindings.c 并生成 bindings.o
target bindings.o pkg : FilePath := do
  -- 定义源文件和头文件目录
  let cDir := pkg.dir / "Image" / "c"
  let srcFile := cDir / "bindings.c"
  let oFile := pkg.buildDir / "Image" / "c" / "bindings.o"
  
  -- 创建构建任务，监控 .c 文件的变化
  let srcJob ← inputFile srcFile true
  
  -- 关键步骤：配置编译参数
  -- 1. "-I" (← getLeanIncludeDir).toString : 包含 Lean 自身的头文件 (<lean/lean.h>)
  -- 2. "-I" cDir.toString               : 包含当前目录，以便能找到 "stb_image.h"
  let weakArgs := #["-I", (← getLeanIncludeDir).toString, "-I", cDir.toString]
  
  -- 使用 "leanc" 作为编译器！
  -- leanc 是 clang 的一个包装器，确保了与 Lean 运行时相同的编译选项
  -- buildO "bindings.c" oFile srcJob weakArgs "leanc"
  let cc := (← IO.getEnv "CC").getD "clang"
  buildO oFile srcJob weakArgs #["-O2"] cc

-- 定义外部库 (External Library)
-- 这会将上面的 .o 文件打包成静态库，供 Lean 链接
extern_lib lbindings pkg := do
  let name := nameToStaticLib "bindings"
  -- 获取上面定义的 bindings.o 目标
  let ffiO ← fetch <| pkg.target ``bindings.o
  buildStaticLib (pkg.staticLibDir / name) #[ffiO]

--------------------------------------------------------------------------------
-- Lean 库配置
--------------------------------------------------------------------------------

-- 配置 Image 库
-- 将 srcDir 指向 "Image/ffi"，这样 "Image/ffi/Image.lean" 就可以通过 `import Image` 导入
lean_lib Image where
  srcDir := "Image/ffi"
  roots := #[`Image]

-- 配置 Material 库
-- 使用默认源码目录（根目录），它会自动找到 Material 文件夹下的代码
lean_lib Material where
  roots := #[`Material]

--------------------------------------------------------------------------------
-- 可执行文件配置
--------------------------------------------------------------------------------

@[default_target]
lean_exe material where
  root := `Main
  -- 1. 强制依赖 lbindings
  -- TODO: here we need to use `needs` instead of `extraDepTargets`
  extraDepTargets := #[``lbindings]
  
  -- 2. 修正：将本地库路径添加到搜索路径，然后链接库
  moreLinkArgs := #[
    -- **添加搜索路径**: -L {workspace}/.lake/build/lib/
    s!"-L{__dir__}/.lake/build/lib/",
    -- 链接库: -lbindings
    "-lbindings"
  ]
