# 关于本仓库

本仓库是对 google material color utilities 的重写。

其中图片的颜色量化以及颜色评分算法是用 Futhark 实现的。
剩余的算法是用 Lean4 和 zig 分别实现的。

其中 Lean4 代码主要用于重构 google 的代码，而 zig 代码
是对 Lean4 重构后代码的重写。

# 示例可视化

本项目可以从图像中提取颜色并生成完整的 Material You 颜色方案。以下是从示例壁纸生成的可视化结果：

## 示例壁纸
![示例壁纸](example/example.jpg)

## 提取的颜色
系统从示例图像中提取了 4 种主要颜色：
![提取的颜色](example/visualization/extracted_colors.png)

## 所有方案的桌面体验模拟
适应性桌面调色板模拟（浅色与深色）

| 方案 | 可视化 |
|------|--------|
| Content | ![Content 方案](example/visualization/desktop_concept_content.png) |
| Expressive | ![Expressive 方案](example/visualization/desktop_concept_expressive.png) |
| Fidelity | ![Fidelity 方案](example/visualization/desktop_concept_fidelity.png) |
| MonoChrome | ![MonoChrome 方案](example/visualization/desktop_concept_monochrome.png) |
| Neutral | ![Neutral 方案](example/visualization/desktop_concept_neutral.png) |
| Rainbow | ![Rainbow 方案](example/visualization/desktop_concept_rainbow.png) |
| TonalSpot | ![TonalSpot 方案](example/visualization/desktop_concept_tonalspot.png) |
| Vibrant | ![Vibrant 方案](example/visualization/desktop_concept_vibrant.png) |

## 交互式预览
包含所有可视化结果的 HTML 预览页面可在 [`https://acomage.github.io/material/`](https://acomage.github.io/material/) 找到。

## 生成可视化
为你自己的图像生成类似的可视化结果：
1. 运行颜色提取流程生成结果文件
2. 使用可视化脚本：
   ```bash
   cd example
   python generate_visualization.py
   ```

# 从源码构建
要从源码构建 lean4 版本的二进制文件，你需要：
- lake
- Futhark
- ISPC（我使用 ISPC 作为 Futhark 的后端，但你也可以使用其他后端）
- libjpeg-turbo和blend2d（用于图片解码）
- make
- cmake
- ninja
- clang（我使用 clang 来编译 Futhark 生成的 C 代码和 LEAN_CC，但你也可以使用其他 C 编译器）

然后，你可以通过运行以下命令来构建项目：
```bash
make
```

然而，在构建项目之前，有一些小建议你可能想知道。
因为 Lean4 的 C 工具链使用的是较旧的 glibc，如果你系统上的 libpng 和 libjpeg-turbo
链接到了系统的 glibc，你可能会遇到一些错误。所以我建议你使用 clang 或其他 C 编译器作为 LEAN_CC，而不是使用 Lean4 默认的 C 工具链。

要从源码构建 zig 版本的二进制文件，你需要：
- zig 0.16.0
- Futhark
- ISPC（我使用 ISPC 作为 Futhark 的后端， 但你也可以使用其他后端）
- libjpeg-turbo 和 libpng（用于图片解码，但这些都是可以更换的，经测试，blend2d 的 png 解码显著快于 libpng）
- make （用于构建 Futhark 部分，后续可能会迁移到build.zig）
- clang（我使用 clang 来编译 Futhark 生成的 C 代码，但你也可以使用其他 C 编译器，比如之间使用zig）

然后你需要进入 `zig` 目录下，运行：

```bash
make
zig build -Doptimize=ReleaseFast
```

这将在 `zig/zig-out/bin` 目录下生成二进制文件 `main`

# 感谢
- [`material color utilities`](https://github.com/material-foundation/material-color-utilities)
- [`blend2d`](https://github.com/blend2d/blend2d)
