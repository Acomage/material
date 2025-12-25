#!/usr/bin/env python3
"""
Visualization script for Material You color scheme results.
Parses example_result.txt and generates visualizations of the color schemes.
"""

import re
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib import gridspec
import numpy as np
from pathlib import Path
from matplotlib.path import Path as MplPath
import os

np.random.seed(42)


def parse_color_file(filepath):
    """
    Parse the example_result.txt file.

    Returns:
        extracted_colors: list of hex colors extracted from image
        schemes: dict of scheme_name -> dict with 'light' and 'dark' subdicts
                each subdict contains token -> hex color mapping
    """
    with open(filepath, "r") as f:
        lines = [line.rstrip("\n") for line in f]

    # Parse extracted colors (first 5 lines)
    extracted_colors = []
    for i in range(2, 6):  # lines 2-5 contain colors
        if i < len(lines):
            line = lines[i].strip()
            if line.startswith("#"):
                extracted_colors.append(line)

    # Parse schemes
    schemes = {}
    current_scheme = None
    current_variant = None

    for line in lines:
        line = line.strip()

        # Check for scheme header
        scheme_match = re.match(r"^Scheme (\w+) (Light|Dark):$", line)
        if scheme_match:
            scheme_name = scheme_match.group(1)
            variant = scheme_match.group(2).lower()

            if scheme_name not in schemes:
                schemes[scheme_name] = {"light": {}, "dark": {}}

            current_scheme = scheme_name
            current_variant = variant
            continue

        # Parse color tokens: "tokenName: Color #rrggbb"
        if current_scheme and current_variant and ": Color #" in line:
            # Split on ': Color #'
            parts = line.split(": Color #")
            if len(parts) == 2:
                token = parts[0].strip()
                hex_color = "#" + parts[1].strip()
                schemes[current_scheme][current_variant][token] = hex_color

    return extracted_colors, schemes


def hex_to_rgb(hex_color):
    """Convert hex color to RGB tuple (0-1 range)."""
    hex_color = hex_color.lstrip("#")
    if len(hex_color) == 6:
        r = int(hex_color[0:2], 16) / 255.0
        g = int(hex_color[2:4], 16) / 255.0
        b = int(hex_color[4:6], 16) / 255.0
        return (r, g, b)
    elif len(hex_color) == 3:
        r = int(hex_color[0] * 2, 16) / 255.0
        g = int(hex_color[1] * 2, 16) / 255.0
        b = int(hex_color[2] * 2, 16) / 255.0
        return (r, g, b)
    else:
        return (0, 0, 0)  # default black


def plot_extracted_colors(extracted_colors, output_dir):
    """
    将提取的颜色可视化为极具设计感的“调色板卡片”。
    采用圆角胶囊设计、阴影效果和优雅的字体排版。
    """
    n_colors = len(extracted_colors)
    # 动态调整画布宽度
    fig_w = max(10, n_colors * 1.8)
    fig, ax = plt.subplots(figsize=(fig_w, 4))

    # 设定背景颜色为非常浅的灰色，突出色块
    fig.patch.set_facecolor("#f8f9fa")
    ax.set_facecolor("#f8f9fa")

    ax.set_xlim(-0.5, n_colors - 0.2)
    ax.set_ylim(-0.8, 1.5)
    ax.axis("off")

    # 标题设计
    ax.text(
        -0.3,
        1.3,
        "Extracted Color Palette",
        fontsize=18,
        fontweight="bold",
        color="#202124",
    )
    ax.text(-0.3, 1.15, "Source: Input Image Analysis", fontsize=10, color="#5f6368")

    def get_text_color(hex_color):
        hex_color = hex_color.lstrip("#")
        r, g, b = tuple(int(hex_color[i : i + 2], 16) / 255 for i in (0, 2, 4))
        luma = 0.299 * r + 0.587 * g + 0.114 * b
        return "white" if luma < 0.6 else "#1c1b1f"

    for i, hex_color in enumerate(extracted_colors):
        # 1. 绘制阴影 (稍微向右下方偏移)
        shadow_offset = 0.04
        shadow_rect = patches.FancyBboxPatch(
            (i - 0.35 + shadow_offset, -0.1 - shadow_offset),
            0.7,
            0.9,
            boxstyle="round,pad=0.1,rounding_size=0.2",
            facecolor="#000000",
            alpha=0.1,
            zorder=1,
            mutation_scale=1,
        )
        ax.add_patch(shadow_rect)

        # 2. 绘制主体色块 (大圆角胶囊)
        main_rect = patches.FancyBboxPatch(
            (i - 0.35, -0.1),
            0.7,
            0.9,
            boxstyle="round,pad=0.1,rounding_size=0.2",
            facecolor=hex_color,
            edgecolor="none",
            zorder=2,
            mutation_scale=1,
        )
        ax.add_patch(main_rect)

        # 3. 颜色信息标注
        txt_c = get_text_color(hex_color)

        # 色块内的编号
        ax.text(
            i,
            0.65,
            f"{i + 1:02d}",
            fontsize=9,
            fontweight="bold",
            color=txt_c,
            alpha=0.6,
            ha="center",
            zorder=3,
        )

        # 色块内的 HEX 代码 (旋转 90 度增加设计感，或水平放置)
        ax.text(
            i,
            0.3,
            hex_color.upper(),
            fontsize=11,
            fontweight="bold",
            color=txt_c,
            ha="center",
            family="monospace",
            zorder=3,
        )

        # 4. 底部详细信息 (类似潘通色卡)
        # RGB 数值预览
        r_val = int(hex_color[1:3], 16)
        g_val = int(hex_color[3:5], 16)
        b_val = int(hex_color[5:7], 16)
        rgb_text = f"R:{r_val} G:{g_val} B:{b_val}"
        ax.text(
            i,
            -0.35,
            rgb_text,
            fontsize=8,
            color="#5f6368",
            ha="center",
            family="sans-serif",
        )

    plt.tight_layout()
    output_path = output_dir / "extracted_colors.png"
    plt.savefig(
        output_path, dpi=200, bbox_inches="tight", facecolor=fig.get_facecolor()
    )
    plt.close()

    print(f"Generated aesthetic palette: {output_path}")
    return output_path


def draw_material_you_impression(scheme_name, scheme_data, output_dir):
    """
    绘制 Material You 主题印象图 (Impression Diagram)。
    特征：悬浮顶栏、下拉式控制中心、多窗口堆叠、现代Dock。
    """

    # 画布设定 (16:10 比例)
    W, H = 19.2, 12.0

    # 圆角常量
    R_L = 0.6  # 大圆角 (窗口、面板)
    R_M = 0.4  # 中圆角 (按钮、卡片)
    R_S = 0.2  # 小圆角 (小按钮)

    fig, axes = plt.subplots(1, 2, figsize=(24, 8.5))  # 左右双屏

    # --- 辅助函数 ---
    def hex_to_rgb(hex_color, alpha=1.0):
        if not hex_color or hex_color == "None":
            return (0, 0, 0, 0)
        hex_color = hex_color.lstrip("#")
        return tuple(int(hex_color[i : i + 2], 16) / 255 for i in (0, 2, 4)) + (alpha,)

    def get_c(colors, key, alpha=1.0):
        return hex_to_rgb(colors.get(key, "#000000"), alpha)

    def draw_rrect(ax, x, y, w, h, color, r=0.3, z=1, alpha=1.0, edge_c="none", lw=0):
        # 限制圆角半径不超过短边一半
        r = min(r, w / 2, h / 2)
        rect = patches.FancyBboxPatch(
            (x + r, y + r),
            w - 2 * r,
            h - 2 * r,
            boxstyle=f"round,pad={r},rounding_size={r}",
            facecolor=color,
            edgecolor=edge_c,
            linewidth=lw,
            alpha=alpha,
            zorder=z,
            mutation_scale=1,
        )
        ax.add_patch(rect)
        return rect

    def draw_shadow(ax, x, y, w, h, color, r=0.3, z=0, offset=0.15, alpha=0.25):
        """绘制柔和阴影"""
        draw_rrect(ax, x + offset, y - offset, w, h, color, r=r, z=z, alpha=alpha)

    def draw_circle(ax, x, y, r, color, z=1, alpha=1.0):
        ax.add_patch(
            patches.Circle(
                (x, y), r, facecolor=color, edgecolor="none", zorder=z, alpha=alpha
            )
        )

    def draw_text_blob(ax, x, y, w, h, color, z=10):
        draw_rrect(ax, x, y, w, h, color, r=h / 2, z=z)

    # --- 渲染逻辑 ---
    def render_screen(ax, colors, title):
        ax.set_xlim(0, W)
        ax.set_ylim(0, H)
        ax.axis("off")

        # 1. 壁纸 (Abstract Wallpaper)
        # 使用 Surface 色调作为底色，叠加 Fixed/Container 气泡
        ax.set_facecolor(get_c(colors, "surface"))

        # 抽象气泡布局
        draw_circle(ax, 0, 0, 8, get_c(colors, "primaryContainer"), z=0, alpha=0.5)
        draw_circle(ax, W, H, 7, get_c(colors, "tertiaryContainer"), z=0, alpha=0.5)
        draw_circle(
            ax, W * 0.3, H * 0.7, 5, get_c(colors, "secondaryFixedDim"), z=0, alpha=0.3
        )
        draw_circle(
            ax, W * 0.7, H * 0.3, 4, get_c(colors, "primaryFixed"), z=0, alpha=0.4
        )

        # 统一色调遮罩
        ax.add_patch(
            patches.Rectangle(
                (0, 0),
                W,
                H,
                facecolor=get_c(colors, "surfaceTint"),
                alpha=0.08,
                zorder=0.1,
            )
        )

        # 2. 悬浮顶栏 (Floating Status Bar)
        # 此时 Top Bar 是一个圆角长条，悬浮在顶部，不贴边
        bar_w = W * 0.96
        bar_h = 0.7
        bar_x = (W - bar_w) / 2
        bar_y = H - bar_h - 0.2  # 距离顶部有间隙

        shadow_c = get_c(colors, "shadow")

        # 顶栏阴影
        draw_shadow(ax, bar_x, bar_y, bar_w, bar_h, shadow_c, r=bar_h / 2, z=4)
        # 顶栏主体 (surfaceContainer)
        draw_rrect(
            ax,
            bar_x,
            bar_y,
            bar_w,
            bar_h,
            get_c(colors, "surfaceContainer"),
            r=bar_h / 2,
            z=5,
        )

        # 顶栏左侧内容 (Date/Time)
        draw_text_blob(
            ax, bar_x + 0.5, bar_y + 0.2, 1.5, 0.3, get_c(colors, "onSurface"), z=6
        )

        # 顶栏右侧内容 (Status Icons)
        # 模拟 Wifi, Battery, Control Center Trigger
        bx_end = bar_x + bar_w
        draw_circle(
            ax, bx_end - 0.5, bar_y + 0.35, 0.15, get_c(colors, "primary"), z=6
        )  # Battery
        draw_circle(
            ax, bx_end - 1.0, bar_y + 0.35, 0.12, get_c(colors, "onSurface"), z=6
        )  # Wifi

        # 3. 控制中心 (Popup Control Center) - 重点修改部分
        # 位于顶栏右侧下方，呈现展开状态
        cc_w, cc_h = 4.0, 5.2
        cc_x = bx_end - cc_w  # 右对齐顶栏
        cc_y = bar_y - cc_h - 0.2  # 位于顶栏下方，留一点空隙

        # 面板阴影
        draw_shadow(ax, cc_x, cc_y, cc_w, cc_h, shadow_c, r=R_L, z=50)
        # 面板背景 (surfaceContainerHigh - 略高于背景)
        draw_rrect(
            ax,
            cc_x,
            cc_y,
            cc_w,
            cc_h,
            get_c(colors, "surfaceContainerHigh"),
            r=R_L,
            z=51,
        )

        # --- 控制中心内部控件 ---
        cx_start = cc_x + 0.25
        cy_top = cc_y + cc_h - 0.25
        cw = cc_w - 0.5

        # Row 1: 大胶囊开关 (Wi-Fi & Bluetooth)
        # Wi-Fi (Active - Primary)
        btn_h = 1.0
        btn_w_half = (cw - 0.2) / 2
        draw_rrect(
            ax,
            cx_start,
            cy_top - btn_h,
            btn_w_half,
            btn_h,
            get_c(colors, "primary"),
            r=R_M,
            z=52,
        )
        draw_circle(
            ax, cx_start + 0.5, cy_top - 0.5, 0.2, get_c(colors, "onPrimary"), z=53
        )  # Icon
        draw_text_blob(
            ax,
            cx_start + 0.9,
            cy_top - 0.4,
            0.6,
            0.12,
            get_c(colors, "onPrimary"),
            z=53,
        )  # Label
        draw_text_blob(
            ax,
            cx_start + 0.9,
            cy_top - 0.7,
            0.5,
            0.12,
            get_c(colors, "onPrimary", 0.7),
            z=53,
        )  # Subtext

        # Bluetooth (Inactive - SurfaceContainerHighest)
        bt_x = cx_start + btn_w_half + 0.2
        draw_rrect(
            ax,
            bt_x,
            cy_top - btn_h,
            btn_w_half,
            btn_h,
            get_c(colors, "surfaceContainerHighest"),
            r=R_M,
            z=52,
        )
        draw_circle(
            ax, bt_x + 0.5, cy_top - 0.5, 0.2, get_c(colors, "onSurfaceVariant"), z=53
        )
        draw_text_blob(
            ax, bt_x + 1.0, cy_top - 0.5, 0.6, 0.15, get_c(colors, "onSurface"), z=53
        )

        # Row 2: 小圆形功能键 (4个)
        r2_y = cy_top - btn_h - 0.2 - 0.8
        colors_row = [
            "secondaryContainer",
            "tertiaryContainer",
            "errorContainer",
            "surfaceContainerHighest",
        ]
        on_colors_row = [
            "onSecondaryContainer",
            "onTertiaryContainer",
            "onErrorContainer",
            "onSurfaceVariant",
        ]
        small_size = (cw - 0.2 * 3) / 4
        for i, (bg, fg) in enumerate(zip(colors_row, on_colors_row)):
            sx = cx_start + i * (small_size + 0.2)
            draw_rrect(
                ax,
                sx,
                r2_y,
                small_size,
                small_size,
                get_c(colors, bg),
                r=small_size / 2,
                z=52,
            )
            draw_circle(
                ax,
                sx + small_size / 2,
                r2_y + small_size / 2,
                small_size / 4,
                get_c(colors, fg),
                z=53,
            )

        # Row 3: 亮度滑块 (带图标)
        r3_y = r2_y - 0.2 - 0.8
        draw_rrect(
            ax,
            cx_start,
            r3_y,
            cw,
            0.8,
            get_c(colors, "surfaceContainerHighest"),
            r=0.4,
            z=52,
        )  # Track
        draw_rrect(
            ax,
            cx_start,
            r3_y,
            cw * 0.7,
            0.8,
            get_c(colors, "surfaceVariant"),
            r=0.4,
            z=53,
        )  # Fill (Low emphasis)
        draw_circle(
            ax,
            cx_start + 0.4,
            r3_y + 0.4,
            0.15,
            get_c(colors, "onSurfaceVariant"),
            z=54,
        )  # Icon

        # Row 4: 音量滑块
        r4_y = r3_y - 0.2 - 0.8
        draw_rrect(
            ax,
            cx_start,
            r4_y,
            cw,
            0.8,
            get_c(colors, "surfaceContainerHighest"),
            r=0.4,
            z=52,
        )
        draw_rrect(
            ax, cx_start, r4_y, cw * 0.4, 0.8, get_c(colors, "primary"), r=0.4, z=53
        )  # Fill (High emphasis)
        draw_circle(
            ax, cx_start + 0.4, r4_y + 0.4, 0.15, get_c(colors, "onPrimary"), z=54
        )  # Icon

        # Row 5: 底部媒体播放器 (Tertiary tint)
        r5_y = cc_y + 0.2
        r5_h = r4_y - 0.2 - r5_y
        draw_rrect(
            ax,
            cx_start,
            r5_y,
            cw,
            r5_h,
            get_c(colors, "tertiaryContainer"),
            r=R_M,
            z=52,
        )
        # Cover Art
        draw_rrect(
            ax,
            cx_start + 0.2,
            r5_y + 0.2,
            r5_h - 0.4,
            r5_h - 0.4,
            get_c(colors, "onTertiaryContainer", 0.2),
            r=0.1,
            z=53,
        )
        draw_circle(
            ax,
            cx_start + 0.2 + (r5_h - 0.4) / 2,
            r5_y + 0.2 + (r5_h - 0.4) / 2,
            0.15,
            get_c(colors, "onTertiaryContainer"),
            z=54,
        )  # Note icon
        # Text
        draw_text_blob(
            ax,
            cx_start + r5_h,
            r5_y + r5_h / 2 + 0.1,
            1.5,
            0.15,
            get_c(colors, "onTertiaryContainer"),
            z=53,
        )
        draw_text_blob(
            ax,
            cx_start + r5_h,
            r5_y + r5_h / 2 - 0.2,
            1.0,
            0.15,
            get_c(colors, "onTertiaryContainer", 0.7),
            z=53,
        )

        # 4. 普通窗口 (Background App - Terminal)
        # 位于左侧，层级较低，被控制中心压住一部分也无所谓
        term_x, term_y = 1.0, 2.5
        term_w, term_h = 7.0, 5.5

        draw_shadow(ax, term_x, term_y, term_w, term_h, shadow_c, r=R_M, z=9)
        draw_rrect(
            ax,
            term_x,
            term_y,
            term_w,
            term_h,
            get_c(colors, "inverseSurface"),
            r=R_M,
            z=10,
        )
        # Terminal Header
        draw_rrect(
            ax,
            term_x,
            term_y + term_h - 0.8,
            term_w,
            0.8,
            get_c(colors, "inverseSurface"),
            r=R_M,
            z=11,
        )
        draw_rrect(
            ax,
            term_x,
            term_y + term_h - 0.8,
            term_w,
            0.4,
            get_c(colors, "inverseSurface"),
            r=0,
            z=11,
        )
        # Buttons
        for i, c_role in enumerate(["error", "tertiary", "secondary"]):
            draw_circle(
                ax,
                term_x + 0.4 + i * 0.35,
                term_y + term_h - 0.4,
                0.1,
                get_c(colors, c_role),
                z=12,
            )
        # Code
        for i in range(5):
            draw_text_blob(
                ax,
                term_x + 0.5,
                term_y + term_h - 1.5 - i * 0.6,
                np.random.uniform(1, 4),
                0.2,
                get_c(colors, "inverseOnSurface"),
                z=11,
            )

        # 5. 主窗口 (Settings/Files)
        # 居中偏左
        # 4. 主焦点窗口：模拟 "Settings/Explorer"
        # 展示 Surface, Outline, Tonal Palette 的层次
        mw_x, mw_y, mw_w, mw_h = 5.0, 2.0, 9.5, 7.5

        # 阴影
        draw_shadow(ax, mw_x, mw_y, mw_w, mw_h, shadow_c, r=R_L, z=19)

        # 窗口主体 (Surface)
        draw_rrect(ax, mw_x, mw_y, mw_w, mw_h, get_c(colors, "surface"), r=R_L, z=20)
        # 边框 (Outline Variant) - 模拟细边框
        draw_rrect(
            ax,
            mw_x,
            mw_y,
            mw_w,
            mw_h,
            "none",
            edge_c=get_c(colors, "outlineVariant"),
            lw=1,
            r=R_L,
            z=21,
        )

        # 侧边栏 (Navigation Rail) - SurfaceContainerLow
        sb_w = 2.5
        draw_rrect(
            ax,
            mw_x,
            mw_y,
            sb_w,
            mw_h,
            get_c(colors, "surfaceContainerLow"),
            r=R_L,
            z=21,
        )
        # 修正右侧圆角，使其变直，这里直接覆盖一个矩形在中间连接处
        draw_rrect(
            ax,
            mw_x + sb_w - 0.5,
            mw_y,
            0.5,
            mw_h,
            get_c(colors, "surfaceContainerLow"),
            r=0,
            z=21,
        )

        # 侧边栏内容
        # 选中的项目 (SecondaryContainer)
        sel_y = mw_y + mw_h - 2.0
        draw_rrect(
            ax,
            mw_x + 0.2,
            sel_y,
            sb_w - 0.4,
            0.8,
            get_c(colors, "secondaryContainer"),
            r=R_S,
            z=22,
        )
        draw_text_blob(
            ax,
            mw_x + 0.8,
            sel_y + 0.3,
            1.2,
            0.2,
            get_c(colors, "onSecondaryContainer"),
            z=23,
        )
        draw_circle(
            ax,
            mw_x + 0.5,
            sel_y + 0.4,
            0.15,
            get_c(colors, "onSecondaryContainer"),
            z=23,
        )  # Icon

        # 未选中的项目
        for i in range(1, 4):
            item_y = sel_y - (i * 1.0)
            draw_text_blob(
                ax,
                mw_x + 0.8,
                item_y + 0.3,
                1.0,
                0.2,
                get_c(colors, "onSurfaceVariant"),
                z=22,
            )
            draw_circle(
                ax,
                mw_x + 0.5,
                item_y + 0.4,
                0.15,
                get_c(colors, "onSurfaceVariant"),
                z=22,
            )

        # 主内容区域
        cw_x = mw_x + sb_w
        cw_w = mw_w - sb_w

        # Header Title
        draw_text_blob(
            ax,
            cw_x + 0.5,
            mw_y + mw_h - 1.0,
            2.0,
            0.3,
            get_c(colors, "onSurface"),
            z=22,
        )

        # UI 元素组 1: 卡片 (Surface Container Highest)
        c1_x, c1_y = cw_x + 0.5, mw_y + mw_h - 3.0
        draw_rrect(
            ax,
            c1_x,
            c1_y,
            4.0,
            1.5,
            get_c(colors, "surfaceContainerHighest"),
            r=R_M,
            z=22,
        )
        # Icon inside card (Primary)
        draw_rrect(
            ax,
            c1_x + 0.2,
            c1_y + 0.3,
            0.9,
            0.9,
            get_c(colors, "primary"),
            r=R_S,
            z=23,
        )
        draw_text_blob(
            ax, c1_x + 1.3, c1_y + 0.9, 1.5, 0.2, get_c(colors, "onSurface"), z=23
        )
        draw_text_blob(
            ax,
            c1_x + 1.3,
            c1_y + 0.5,
            2.0,
            0.15,
            get_c(colors, "onSurfaceVariant"),
            z=23,
        )

        # UI 元素组 2: 开关和滑块
        # Switch (Active)
        sw_y = mw_y + mw_h - 4.0
        draw_text_blob(
            ax, c1_x, sw_y + 0.1, 1.5, 0.2, get_c(colors, "onSurface"), z=22
        )  # Label
        # Track
        draw_rrect(
            ax, c1_x + 4.0, sw_y, 1.0, 0.5, get_c(colors, "primary"), r=0.25, z=22
        )
        # Handle
        draw_circle(
            ax, c1_x + 4.0 + 0.75, sw_y + 0.25, 0.18, get_c(colors, "onPrimary"), z=23
        )

        # Switch (Inactive)
        sw2_y = sw_y - 0.8
        draw_text_blob(
            ax, c1_x, sw2_y + 0.1, 1.0, 0.2, get_c(colors, "onSurface"), z=22
        )
        draw_rrect(
            ax,
            c1_x + 4.0,
            sw2_y,
            1.0,
            0.5,
            get_c(colors, "surfaceContainerHighest"),
            edge_c=get_c(colors, "outline"),
            lw=1,
            r=0.25,
            z=22,
        )
        draw_circle(
            ax, c1_x + 4.0 + 0.25, sw2_y + 0.25, 0.15, get_c(colors, "outline"), z=23
        )

        # Slider
        sl_y = sw2_y - 0.8
        draw_rrect(
            ax,
            c1_x,
            sl_y + 0.2,
            5.0,
            0.1,
            get_c(colors, "surfaceContainerHighest"),
            r=0.05,
            z=22,
        )  # Track bg
        draw_rrect(
            ax, c1_x, sl_y + 0.2, 2.5, 0.1, get_c(colors, "primary"), r=0.05, z=23
        )  # Active track
        draw_circle(
            ax, c1_x + 2.5, sl_y + 0.25, 0.15, get_c(colors, "primary"), z=24
        )  # Thumb

        # Floating Action Button (FAB) inside window bottom right
        fab_size = 1.0
        draw_rrect(
            ax,
            cw_x + cw_w - fab_size - 0.5,
            mw_y + 0.5,
            fab_size,
            fab_size,
            get_c(colors, "tertiaryContainer"),
            r=0.35,
            z=25,
        )
        # Simple Plus Icon
        fcx, fcy = cw_x + cw_w - fab_size - 0.5 + 0.5, mw_y + 0.5 + 0.5
        draw_rrect(
            ax,
            fcx - 0.2,
            fcy - 0.05,
            0.4,
            0.1,
            get_c(colors, "onTertiaryContainer"),
            r=0.02,
            z=26,
        )
        draw_rrect(
            ax,
            fcx - 0.05,
            fcy - 0.2,
            0.1,
            0.4,
            get_c(colors, "onTertiaryContainer"),
            r=0.02,
            z=26,
        )

        # 5. 右下角悬浮面板 (Quick Settings / Notifications)
        # 展示 Surface Container High 和 Add-on 颜色
        qs_w, qs_h = 3.5, 4.0
        qs_x, qs_y = W - qs_w - 0.5, 1.5

        draw_shadow(ax, qs_x, qs_y, qs_w, qs_h, shadow_c, r=R_L, z=29)
        draw_rrect(
            ax,
            qs_x,
            qs_y,
            qs_w,
            qs_h,
            get_c(colors, "surfaceContainerHigh"),
            r=R_L,
            z=30,
        )

        # Toggles grid
        colors_grid = ["primary", "secondary", "tertiary", "error"]
        for i, role in enumerate(colors_grid):
            row = i // 2
            col = i % 2
            btn_w = (qs_w - 0.6) / 2
            bx = qs_x + 0.2 + col * (btn_w + 0.2)
            by = qs_y + qs_h - 0.2 - (row + 1) * 0.9

            # Button Shape
            draw_rrect(ax, bx, by, btn_w, 0.7, get_c(colors, role), r=0.35, z=31)
            # Icon placeholder
            draw_circle(
                ax,
                bx + 0.35,
                by + 0.35,
                0.15,
                get_c(colors, f"on{role.capitalize()}"),
                z=32,
            )

        # Brightness Slider in Panel
        bs_y = qs_y + 0.5
        draw_rrect(
            ax,
            qs_x + 0.2,
            bs_y,
            qs_w - 0.4,
            0.6,
            get_c(colors, "surfaceContainerHighest"),
            r=0.3,
            z=31,
        )
        draw_rrect(
            ax,
            qs_x + 0.2,
            bs_y,
            (qs_w - 0.4) * 0.7,
            0.6,
            get_c(colors, "inversePrimary"),
            r=0.3,
            z=32,
        )  # Level
        # 6. 底部悬浮 Dock
        dock_w, dock_h = 7.0, 1.1
        dock_x = (W - dock_w) / 2
        dock_y = 0.3

        # 磨砂玻璃感 Dock (Transparent surfaceContainerHighest)
        draw_shadow(ax, dock_x, dock_y, dock_w, dock_h, shadow_c, r=0.5, z=40)
        draw_rrect(
            ax,
            dock_x,
            dock_y,
            dock_w,
            dock_h,
            get_c(colors, "surfaceContainerHighest", 0.85),
            r=0.55,
            z=41,
        )

        # Icons
        icons = [
            "primary",
            "secondary",
            "tertiary",
            "error",
            "primaryContainer",
            "inverseSurface",
        ]
        i_size = 0.7
        gap = (dock_w - len(icons) * i_size) / (len(icons) + 1)
        for i, role in enumerate(icons):
            ix = dock_x + gap + i * (i_size + gap)
            iy = dock_y + (dock_h - i_size) / 2
            draw_rrect(ax, ix, iy, i_size, i_size, get_c(colors, role), r=0.2, z=42)
            if i == 0:  # Active indicator
                draw_circle(
                    ax,
                    ix + i_size / 2,
                    dock_y - 0.15,
                    0.05,
                    get_c(colors, "onSurface"),
                    z=42,
                )

        # 7. 鼠标
        # 指向控制中心的 Wi-Fi 按钮
        cur_x, cur_y = cx_start + 1.5, cy_top - 0.8
        cursor_poly = [
            (cur_x, cur_y),
            (cur_x, cur_y - 0.9),
            (cur_x + 0.25, cur_y - 0.7),
            (cur_x + 0.45, cur_y - 1.0),
            (cur_x + 0.6, cur_y - 0.9),
            (cur_x + 0.4, cur_y - 0.6),
            (cur_x + 0.7, cur_y - 0.6),
        ]

        poly = patches.Polygon(
            cursor_poly,
            closed=True,
            facecolor=get_c(colors, "primary"),
            edgecolor=get_c(colors, "onPrimary"),
            linewidth=1,
            zorder=100,
        )
        ax.add_patch(poly)

        # Title Label
        ax.text(
            W / 2,
            -0.8,
            title,
            ha="center",
            va="top",
            fontsize=14,
            color=get_c(colors, "onSurface"),
            fontweight="bold",
        )

    # 生成 Light/Dark 对比图
    render_screen(axes[0], scheme_data["light"], "")
    render_screen(axes[1], scheme_data["dark"], "")

    plt.subplots_adjust(left=0.02, right=0.98, top=0.95, bottom=0.1, wspace=0.05)

    filename = f"desktop_concept_{scheme_name.lower()}.png"
    output_path = output_dir / filename
    plt.savefig(output_path, dpi=120, facecolor="#f0f0f0")
    plt.close()
    print(f"Generated updated impression diagram: {output_path}")
    return output_path


def plot_all_schemes_overview(schemes, output_dir):
    """Create an overview visualization showing primary colors of all schemes."""
    scheme_names = list(schemes.keys())
    n_schemes = len(scheme_names)

    fig, axes = plt.subplots(2, n_schemes, figsize=(4 * n_schemes, 8))
    fig.suptitle(
        "Material You Color Schemes Overview\nPrimary Colors for Light and Dark Variants",
        fontsize=20,
        fontweight="bold",
    )

    for col, scheme_name in enumerate(scheme_names):
        scheme_data = schemes[scheme_name]

        # Light variant primary color
        light_primary = scheme_data["light"].get("primary", "#000000")
        ax_light = axes[0, col]
        ax_light.add_patch(
            patches.Rectangle(
                (0, 0),
                1,
                1,
                facecolor=hex_to_rgb(light_primary),
                edgecolor="black",
                linewidth=2,
            )
        )
        ax_light.text(
            0.5,
            0.5,
            "Light",
            ha="center",
            va="center",
            fontsize=12,
            fontweight="bold",
            color="white" if np.mean(hex_to_rgb(light_primary)) < 0.5 else "black",
        )
        ax_light.set_title(f"{scheme_name}\n{light_primary}", fontsize=11)
        ax_light.set_xlim(0, 1)
        ax_light.set_ylim(0, 1)
        ax_light.set_aspect("equal")
        ax_light.axis("off")

        # Dark variant primary color
        dark_primary = scheme_data["dark"].get("primary", "#000000")
        ax_dark = axes[1, col]
        ax_dark.add_patch(
            patches.Rectangle(
                (0, 0),
                1,
                1,
                facecolor=hex_to_rgb(dark_primary),
                edgecolor="black",
                linewidth=2,
            )
        )
        ax_dark.text(
            0.5,
            0.5,
            "Dark",
            ha="center",
            va="center",
            fontsize=12,
            fontweight="bold",
            color="white" if np.mean(hex_to_rgb(dark_primary)) < 0.5 else "black",
        )
        ax_dark.set_xlim(0, 1)
        ax_dark.set_ylim(0, 1)
        ax_dark.set_aspect("equal")
        ax_dark.axis("off")

    plt.tight_layout()
    output_path = output_dir / "all_schemes_overview.png"
    plt.savefig(output_path, dpi=300, bbox_inches="tight")
    plt.close()
    print(f"Saved all schemes overview to {output_path}")

    return output_path


# def plot_scheme_comparison(schemes, output_dir):
#     """Create a comparison visualization showing multiple colors per scheme."""
#     scheme_names = list(schemes.keys())
#     n_schemes = len(scheme_names)
#
#     # Colors to compare for each scheme
#     compare_tokens = ["primary", "secondary", "tertiary", "background", "surface"]
#
#     fig, axes = plt.subplots(
#         len(compare_tokens),
#         n_schemes,
#         figsize=(2.5 * n_schemes, 2 * len(compare_tokens)),
#     )
#     fig.suptitle(
#         "Color Scheme Comparison\nLight Variant Key Colors",
#         fontsize=18,
#         fontweight="bold",
#         y=1.02,
#     )
#
#     for col, scheme_name in enumerate(scheme_names):
#         scheme_data = schemes[scheme_name]
#         light_colors = scheme_data["light"]
#
#         for row, token in enumerate(compare_tokens):
#             ax = axes[row, col] if len(compare_tokens) > 1 else axes[col]
#             hex_color = light_colors.get(token, "#000000")
#
#             ax.add_patch(
#                 patches.Rectangle(
#                     (0, 0),
#                     1,
#                     1,
#                     facecolor=hex_to_rgb(hex_color),
#                     edgecolor="black",
#                     linewidth=1,
#                 )
#             )
#
#             # Add token name and color
#             text_color = "white" if np.mean(hex_to_rgb(hex_color)) < 0.5 else "black"
#             if row == 0:  # Top row shows scheme name
#                 ax.set_title(scheme_name, fontsize=10, pad=3)
#
#             ax.text(
#                 0.5,
#                 0.7,
#                 token,
#                 ha="center",
#                 va="center",
#                 fontsize=9,
#                 fontweight="bold",
#                 color=text_color,
#             )
#             ax.text(
#                 0.5,
#                 0.3,
#                 hex_color,
#                 ha="center",
#                 va="center",
#                 fontsize=8,
#                 color=text_color,
#             )
#
#             ax.set_xlim(0, 1)
#             ax.set_ylim(0, 1)
#             ax.set_aspect("equal")
#             ax.axis("off")
#
#     plt.tight_layout()
#     output_path = output_dir / "scheme_comparison.png"
#     plt.savefig(output_path, dpi=300, bbox_inches="tight")
#     plt.close()
#     print(f"Saved scheme comparison to {output_path}")
#
#     return output_path


def plot_scheme_comparison(schemes, output_dir):
    """
    创建一个美观的、具有现代设计感的配色方案对比图。
    摒弃了无聊的网格，采用“色卡柱”设计，并选择了更能体现主题倾向的颜色角色。
    """
    scheme_names = list(schemes.keys())
    n_schemes = len(scheme_names)

    # 1. 选择更有代表性的颜色角色
    # - Primary: 核心品牌色
    # - Tertiary: 独特的强调色（Material You的灵魂）
    # - Primary Container: 界面中大面积使用的色彩，体现氛围
    # - Secondary Container: 辅助元素的底色
    # - Surface Container Highest: 带有主题色调倾向的中性色（比纯Surface更有味道）
    display_tokens = [
        ("primary", 1.5),  # (Role Name, Height Weight) - 主色最高
        ("tertiary", 1.0),  # 强调色
        ("primaryContainer", 1.25),  # 容器色次高
        ("secondaryContainer", 1.0),
        ("surfaceContainerHighest", 1.125),  # 中性色底座
    ]

    total_weight = sum(w for _, w in display_tokens)

    # 画布设置：根据方案数量动态调整宽度
    fig_w = max(4, n_schemes * 2.5)
    fig_h = 8
    fig, ax = plt.subplots(figsize=(fig_w, fig_h))

    # 去除坐标轴
    ax.set_xlim(0, n_schemes)
    ax.set_ylim(0, total_weight + 1.5)  # 留出顶部标题空间
    ax.axis("off")

    # 辅助函数：计算亮度以决定文字颜色 (黑/白)
    def hex_to_rgb(hex_color):
        hex_color = hex_color.lstrip("#")
        return tuple(int(hex_color[i : i + 2], 16) / 255 for i in (0, 2, 4))

    def get_text_color(bg_hex):
        r, g, b = hex_to_rgb(bg_hex)
        # 计算感知亮度 (Luma)
        luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return "white" if luminance < 0.55 else "#1c1b1f"  # 使用深灰而不是纯黑，更柔和

    # 绘制逻辑
    pad_x = 0.2  # 柱子之间的间隙
    col_width = 1.0 - pad_x * 2

    for col_idx, scheme_name in enumerate(scheme_names):
        scheme_data = schemes[scheme_name]["light"]  # 默认展示 Light 模式，色彩更明显

        current_y = 0
        center_x = col_idx + 0.5

        # 2. 绘制该方案的色卡柱 (从下往上堆叠)
        # 我们倒序遍历，这样"Surface"在最下面，"Primary"在最上面，符合视觉直觉
        for token_name, weight in reversed(display_tokens):
            hex_color = scheme_data.get(token_name, "#000000")

            # 绘制圆角矩形
            # 使用 FancyBboxPatch 实现圆角
            # 注意：Matplotlib的圆角处理比较tricky，这里用相对简单的圆角逻辑

            # 如果是底部第一个，只有下面两个角是圆的；如果是顶部，只有上面圆？
            # 为了美观，我们让每个色块都是独立的圆角矩形，中间有微小缝隙

            block_h = weight - 0.05  # 留微小缝隙

            rect = patches.FancyBboxPatch(
                (center_x - col_width / 2, current_y),
                col_width,
                block_h,
                boxstyle="round,pad=0,rounding_size=0.05",
                facecolor=hex_color,
                edgecolor="none",
                mutation_scale=1,
            )
            ax.add_patch(rect)

            # 添加文字信息
            txt_color = get_text_color(hex_color)

            # Token Name (小字)
            ax.text(
                center_x,
                current_y + block_h / 2 + 0.15,
                token_name,
                ha="center",
                va="center",
                fontsize=8,
                color=txt_color,
                alpha=0.8,
                fontfamily="sans-serif",
            )
            # Hex Code (大字，粗体)
            ax.text(
                center_x,
                current_y + block_h / 2 - 0.15,
                hex_color.upper(),
                ha="center",
                va="center",
                fontsize=10,
                fontweight="bold",
                color=txt_color,
                fontfamily="monospace",
            )

            current_y += weight

        # 3. 底部添加方案名称
        ax.text(
            center_x,
            -0.5,
            scheme_name,
            ha="center",
            va="top",
            fontsize=12,
            fontweight="bold",
            color="#333333",
        )

    # 顶部大标题
    ax.text(
        n_schemes / 2,
        total_weight + 0.8,
        "Color Scheme Palette Comparison",
        ha="center",
        va="center",
        fontsize=20,
        fontweight="bold",
        color="#1f1f1f",
    )
    ax.text(
        n_schemes / 2,
        total_weight + 0.4,
        "Key roles extraction: Primary, Tertiary, Containers & Tinted Surface",
        ha="center",
        va="center",
        fontsize=12,
        color="#666666",
    )

    plt.tight_layout()
    output_path = output_dir / "scheme_comparison.png"
    plt.savefig(output_path, dpi=200, bbox_inches="tight")
    plt.close()
    print(f"Saved aesthetic comparison to {output_path}")

    return output_path


def main():
    """Main function to generate all visualizations."""
    # Setup paths
    script_dir = Path(__file__).parent
    data_file = script_dir / "example_result.txt"
    output_dir = script_dir / "visualization"
    project_root = script_dir.parent

    # Create output directory if it doesn't exist
    output_dir.mkdir(exist_ok=True)

    print(f"Parsing color data from {data_file}...")
    extracted_colors, schemes = parse_color_file(data_file)

    print(f"Found {len(extracted_colors)} extracted colors:")
    for color in extracted_colors:
        print(f"  {color}")

    print(f"Found {len(schemes)} color schemes:")
    for scheme_name in schemes:
        light_tokens = len(schemes[scheme_name]["light"])
        dark_tokens = len(schemes[scheme_name]["dark"])
        print(
            f"  {scheme_name}: {light_tokens} light tokens, {dark_tokens} dark tokens"
        )

    # Generate visualizations
    print("\nGenerating visualizations...")

    # 1. Extracted colors
    extracted_path = plot_extracted_colors(extracted_colors, output_dir)

    # 2. Individual scheme palettes
    scheme_paths = {}
    for scheme_name in schemes:
        # scheme_path = plot_scheme_palette(scheme_name, schemes[scheme_name], output_dir)
        # scheme_path = draw_fake_desktop(scheme_name, schemes[scheme_name], output_dir)
        scheme_path = draw_material_you_impression(
            scheme_name, schemes[scheme_name], output_dir
        )
        scheme_paths[scheme_name] = scheme_path

    # 3. Overview of all schemes
    overview_path = plot_all_schemes_overview(schemes, output_dir)

    # 4. Scheme comparison
    comparison_path = plot_scheme_comparison(schemes, output_dir)

    print("\n" + "=" * 60)
    print("VISUALIZATION GENERATION COMPLETE")
    print("=" * 60)
    print(f"Output directory: {output_dir}")
    print(f"1. Extracted colors: {extracted_path}")
    print(f"2. Scheme overview: {overview_path}")
    print(f"3. Scheme comparison: {comparison_path}")
    print(f"4. Individual scheme palettes:")
    for scheme_name, path in scheme_paths.items():
        print(f"   - {scheme_name}: {path}")

    # Generate a simple HTML preview page
    generate_html_preview(
        project_root, extracted_path, overview_path, comparison_path, scheme_paths
    )

    return True


def generate_html_preview(
    output_dir, extracted_path, overview_path, comparison_path, scheme_paths
):
    """Generate a high-design HTML preview at the project root."""

    # 因为 index.html 在根目录，而图片在子目录，我们需要这个前缀
    # 假设 output_dir 的名字就是 "visualization"
    sub_dir = "example/visualization"

    scheme_names = sorted(scheme_paths.keys())

    html_content = f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Material You Design System | Lean4</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Google+Sans:wght@400;500;700&family=Roboto+Mono&display=swap" rel="stylesheet">
    <style>
        :root {{
            --primary: #3c71df;
            --bg: #f8f9fa;
            --card-bg: #ffffff;
            --text-main: #191b22;
            --text-sub: #424653;
        }}

        * {{ box-sizing: border-box; }}
        
        body {{
            font-family: 'Google Sans', sans-serif;
            background-color: var(--bg);
            color: var(--text-main);
            margin: 0;
            padding: 0;
            line-height: 1.5;
        }}

        header {{
            background: linear-gradient(135deg, #191b22 0%, #2e3037 100%);
            color: white;
            padding: 5rem 2rem;
            text-align: center;
            margin-bottom: 3rem;
            box-shadow: 0 4px 20px rgba(0,0,0,0.1);
        }}

        h1 {{ font-size: 3.2rem; margin: 0; font-weight: 700; letter-spacing: -1.5px; }}
        .tagline {{ font-size: 1.1rem; opacity: 0.7; margin-top: 1.2rem; font-family: 'Roboto Mono', monospace; text-transform: uppercase; letter-spacing: 2px; }}

        .container {{
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 2rem;
        }}

        .section-title {{
            font-size: 1.5rem;
            margin: 5rem 0 2.5rem;
            display: flex;
            align-items: center;
            gap: 1.5rem;
            font-weight: 700;
        }}
        
        .section-title::after {{
            content: "";
            height: 1px;
            flex-grow: 1;
            background: rgba(0,0,0,0.1);
        }}

        .overview-grid {{
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 2.5rem;
            margin-bottom: 3rem;
        }}

        .glass-card {{
            background: var(--card-bg);
            border-radius: 28px;
            padding: 2.5rem;
            box-shadow: 0 8px 30px rgba(0,0,0,0.04);
            border: 1px solid rgba(0,0,0,0.05);
            transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
        }}
        
        .glass-card:hover {{ transform: translateY(-8px); box-shadow: 0 20px 40px rgba(0,0,0,0.08); }}
        .glass-card p {{ margin-top: 0; font-weight: 700; color: var(--text-sub); margin-bottom: 1.5rem; }}
        .glass-card img {{ width: 100%; border-radius: 12px; }}

        .scheme-showcase {{
            display: flex;
            flex-direction: column;
            gap: 5rem;
            margin-bottom: 8rem;
        }}

        .scheme-block {{
            background: var(--card-bg);
            border-radius: 32px;
            padding: 3.5rem;
            box-shadow: 0 15px 45px rgba(0,0,0,0.05);
            border: 1px solid rgba(0,0,0,0.03);
        }}

        .scheme-header {{
            margin-bottom: 2.5rem;
        }}

        .scheme-info h3 {{
            font-size: 2.4rem;
            margin: 0;
            letter-spacing: -0.5px;
            color: #3c71df; /* 使用你的 Primary Color */
        }}

        .desktop-preview {{
            position: relative;
            overflow: hidden;
            border-radius: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }}

        .desktop-preview img {{
            width: 100%;
            height: auto;
            display: block;
            transition: transform 0.6s ease;
        }}

        .desktop-preview:hover img {{
            transform: scale(1.03);
        }}

        footer {{
            padding: 6rem 2rem;
            text-align: center;
            background: #fff;
            margin-top: 4rem;
            border-top: 1px solid rgba(0,0,0,0.05);
        }}

        @media (max-width: 900px) {{
            .overview-grid {{ grid-template-columns: 1fr; }}
            .scheme-block {{ padding: 2rem; }}
            h1 {{ font-size: 2.4rem; }}
        }}
    </style>
</head>
<body>
    <header>
        <h1>Material You</h1>
        <div class="tagline">Lean4 Generated Color Schemes</div>
    </header>

    <div class="container">
        <div class="section-title">Analysis & Comparison</div>
        <div class="overview-grid">
            <div class="glass-card">
                <p>Extracted from Wallpaper</p>
                <img src="{sub_dir}/extracted_colors.png" alt="Extracted colors">
            </div>
            <div class="glass-card">
                <p>Cross-Scheme Comparison</p>
                <img src="{sub_dir}/scheme_comparison.png" alt="Comparison">
            </div>
        </div>

        <div class="section-title">Desktop Experience Simulation</div>
        <div class="scheme-showcase">
"""

    for scheme_name in scheme_names:
        filename = f"desktop_concept_{scheme_name.lower()}.png"
        html_content += f"""
            <div class="scheme-block">
                <div class="scheme-header">
                    <div class="scheme-info">
                        <h3>{scheme_name}</h3>
                        <p style="color: var(--text-sub); margin-top: 0.5rem;">Adaptive Desktop Palette Simulation (Light vs Dark)</p>
                    </div>
                </div>
                <div class="desktop-preview">
                    <img src="{sub_dir}/{filename}" alt="{scheme_name} concept">
                </div>
            </div>
"""

    html_content += """
        </div>
    </div>

    <footer>
        <p style="font-weight: 700; color: #191b22;">Material You Lean4 Core</p>
        <p style="opacity: 0.5; font-size: 0.8rem;">Algorithms for Dynamic Color Generation</p>
    </footer>
</body>
</html>
"""

    # 修改这里：将 index.html 写到根目录
    html_path = output_dir / "index.html"
    with open(html_path, "w", encoding="utf-8") as f:
        f.write(html_content)
    print(f"Generated High-Design HTML preview at {html_path.absolute()}")


if __name__ == "__main__":
    main()
