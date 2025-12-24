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
    """Create visualization of extracted colors from image."""
    fig, ax = plt.subplots(figsize=(10, 2))
    ax.set_title("Colors Extracted from Example Image", fontsize=16, fontweight="bold")

    n_colors = len(extracted_colors)
    for i, hex_color in enumerate(extracted_colors):
        rect = patches.Rectangle(
            (i, 0),
            0.8,
            1,
            facecolor=hex_to_rgb(hex_color),
            edgecolor="black",
            linewidth=2,
        )
        ax.add_patch(rect)

        # Add hex code text
        ax.text(
            i + 0.4,
            0.5,
            hex_color,
            ha="center",
            va="center",
            fontsize=12,
            fontweight="bold",
            color="white" if np.mean(hex_to_rgb(hex_color)) < 0.5 else "black",
        )

    ax.set_xlim(0, n_colors)
    ax.set_ylim(0, 1)
    ax.set_aspect("equal")
    ax.axis("off")

    plt.tight_layout()
    output_path = output_dir / "extracted_colors.png"
    plt.savefig(output_path, dpi=300, bbox_inches="tight")
    plt.close()
    print(f"Saved extracted colors visualization to {output_path}")

    return output_path


def draw_fake_desktop(scheme_name, scheme_data, output_dir):
    """
    Draws a conceptual 'Fake Desktop' to visualize the color scheme in context.
    Simulates a macOS/ChromeOS-like environment with abstract windows, docks, and controls.
    """

    # UI Constants for layout
    W, H = 16, 10  # Aspect ratio 16:10
    CORNER = 0.3  # Standard corner radius

    fig, axes = plt.subplots(1, 2, figsize=(20, 7))  # Two screens side-by-side

    # Helper: Convert hex to RGB
    def get_c(colors, key, default="#000000"):
        hex_c = colors.get(key, default)
        return hex_to_rgb(hex_c)

    # Helper: Draw rounded rect
    def rounded_rect(ax, x, y, w, h, color, r=CORNER, alpha=1.0, z=1):
        rect = patches.FancyBboxPatch(
            (x, y),
            w,
            h,
            boxstyle=f"round,pad=0,rounding_size={r}",
            facecolor=color,
            edgecolor="none",
            alpha=alpha,
            zorder=z,
        )
        ax.add_patch(rect)
        return rect

    # Helper: Draw circle
    def circle(ax, x, y, r, color, z=1):
        c = patches.Circle((x, y), r, facecolor=color, edgecolor="none", zorder=z)
        ax.add_patch(c)

    # Helper: Draw UI Text placeholder (rounded lines)
    def text_line(ax, x, y, w, h, color, z=5):
        rounded_rect(ax, x, y, w, h, color, r=h / 2, z=z)

    # --- The Drawing Logic for One Screen ---
    def render_screen(ax, colors, title_suffix):
        # 1. Wallpaper / Desktop Background
        # Use 'background' or 'surface' as base, maybe 'primaryContainer' for a tint
        bg_color = get_c(colors, "background")
        ax.set_facecolor(bg_color)
        ax.set_xlim(0, W)
        ax.set_ylim(0, H)
        ax.axis("off")

        # Abstract Wallpaper shapes (soft blobs)
        c_tert_con = get_c(colors, "tertiaryContainer")
        c_sec_con = get_c(colors, "secondaryContainer")

        # Big blob bottom left
        circle(ax, 2, 2, 4, c_tert_con, z=0)
        # Big blob top right
        circle(ax, W - 2, H - 2, 5, c_sec_con, z=0)

        # 2. Menu Bar (Top)
        # Use surfaceContainerLow or similar
        bar_color = get_c(colors, "surfaceContainerLow")
        rounded_rect(ax, 0.2, H - 0.8, W - 0.4, 0.6, bar_color, r=0.3, z=1)

        # Menu items (pill shapes)
        on_surf = get_c(colors, "onSurface")
        text_line(
            ax, 0.5, H - 0.65, 0.3, 0.3, get_c(colors, "primary"), z=2
        )  # Apple/Google Logo
        text_line(ax, 1.0, H - 0.65, 1.0, 0.2, on_surf, z=2)  # App Name
        text_line(ax, 2.2, H - 0.65, 0.8, 0.2, on_surf, z=2)  # File
        text_line(ax, 3.2, H - 0.65, 0.8, 0.2, on_surf, z=2)  # Edit

        # Clock/Status right side
        text_line(ax, W - 1.5, H - 0.65, 1.0, 0.2, on_surf, z=2)
        circle(
            ax, W - 1.8, H - 0.5, 0.15, get_c(colors, "primary"), z=2
        )  # Notification dot

        # 3. Background Window (Inactive)
        # Position: Left, slightly behind
        win_bg = get_c(colors, "surfaceContainer")
        win_outline = get_c(colors, "outlineVariant")

        bx, by, bw, bh = 1.5, 2.5, 6, 5
        rounded_rect(ax, bx, by, bw, bh, win_bg, r=0.4, z=2)
        # Window Border
        # (Matplotlib patches don't do inner borders well, so we simulate with a slightly larger rect behind if needed,
        # but here we rely on color contrast or just skip for minimalism)

        # Inactive Sidebar
        rounded_rect(
            ax, bx, by, 1.5, bh, get_c(colors, "surfaceContainerHigh"), r=0.4, z=2.1
        )
        # Inactive Content blocks
        text_line(ax, bx + 2, by + 3.5, 3, 0.4, get_c(colors, "surfaceVariant"), z=2.2)
        text_line(ax, bx + 2, by + 2.5, 3, 0.4, get_c(colors, "surfaceVariant"), z=2.2)

        # 4. Active Window (The "Hero" App)
        # Position: Centered/Right, overlapping
        ax_x, ax_y, ax_w, ax_h = 5, 1.5, 8, 6.5
        win_surf = get_c(colors, "surface")

        # Drop shadow (simulated with semi-transparent black rect offset)
        shadow_c = get_c(colors, "shadow")
        rounded_rect(
            ax, ax_x + 0.2, ax_y - 0.2, ax_w, ax_h, shadow_c, r=0.4, alpha=0.1, z=3
        )

        # Main Window Body
        main_win = rounded_rect(ax, ax_x, ax_y, ax_w, ax_h, win_surf, r=0.4, z=4)

        # Window Controls (Traffic lights)
        cx = ax_x + 0.4
        cy = ax_y + ax_h - 0.5
        circle(ax, cx, cy, 0.12, get_c(colors, "error"), z=5)  # Close
        circle(ax, cx + 0.4, cy, 0.12, get_c(colors, "tertiary"), z=5)  # Minimize
        circle(ax, cx + 0.8, cy, 0.12, get_c(colors, "primary"), z=5)  # Maximize

        # Active Window Layout: Two columns
        # Left Column: Navigation
        nav_bg = get_c(colors, "surfaceContainerLow")
        # We need to clip this to the window shape conceptually, but simplified:
        # Just draw a rect inside
        rounded_rect(ax, ax_x, ax_y, 2.0, ax_h, nav_bg, r=0.4, z=4.1)
        # Fix corners being too round for split view by overdrawing or just accept the style

        # Nav Items
        for i in range(5):
            iy = ax_y + ax_h - 1.5 - (i * 0.6)
            # Selected item
            if i == 1:
                rounded_rect(
                    ax,
                    ax_x + 0.2,
                    iy - 0.1,
                    1.6,
                    0.5,
                    get_c(colors, "secondaryContainer"),
                    r=0.25,
                    z=4.2,
                )
                text_line(
                    ax,
                    ax_x + 0.4,
                    iy,
                    0.8,
                    0.15,
                    get_c(colors, "onSecondaryContainer"),
                    z=4.3,
                )
            else:
                text_line(
                    ax,
                    ax_x + 0.4,
                    iy,
                    0.8,
                    0.15,
                    get_c(colors, "onSurfaceVariant"),
                    z=4.3,
                )

        # Right Column: Content
        content_x = ax_x + 2.2

        # Title
        text_line(
            ax, content_x, ax_y + ax_h - 1.0, 2.5, 0.4, get_c(colors, "onSurface"), z=5
        )

        # Card 1 (Primary Action)
        card_y = ax_y + ax_h - 3.0
        rounded_rect(
            ax,
            content_x,
            card_y,
            5,
            1.5,
            get_c(colors, "surfaceContainerHighest"),
            r=0.3,
            z=5,
        )
        # Icon box
        rounded_rect(
            ax,
            content_x + 0.2,
            card_y + 0.3,
            0.9,
            0.9,
            get_c(colors, "primaryContainer"),
            r=0.2,
            z=6,
        )
        # Icon symbol (simple plus)
        text_line(
            ax,
            content_x + 0.5,
            card_y + 0.6,
            0.3,
            0.3,
            get_c(colors, "onPrimaryContainer"),
            z=7,
        )
        # Text lines
        text_line(
            ax, content_x + 1.3, card_y + 0.8, 2.0, 0.2, get_c(colors, "onSurface"), z=6
        )
        text_line(
            ax,
            content_x + 1.3,
            card_y + 0.4,
            3.0,
            0.15,
            get_c(colors, "onSurfaceVariant"),
            z=6,
        )

        # Interactive Elements Row
        # Toggle Switch
        sw_y = ax_y + 1.5
        rounded_rect(
            ax, content_x, sw_y, 1.0, 0.5, get_c(colors, "primary"), r=0.25, z=5
        )  # Track
        circle(
            ax, content_x + 0.75, sw_y + 0.25, 0.18, get_c(colors, "onPrimary"), z=6
        )  # Knob

        # Slider
        slider_bg = get_c(colors, "outlineVariant")
        text_line(ax, content_x + 1.5, sw_y + 0.2, 3.0, 0.1, slider_bg, z=5)  # Track
        text_line(
            ax, content_x + 1.5, sw_y + 0.2, 1.5, 0.1, get_c(colors, "primary"), z=6
        )  # Active Track
        circle(
            ax, content_x + 1.5 + 1.5, sw_y + 0.25, 0.15, get_c(colors, "primary"), z=7
        )  # Thumb

        # Floating Action Button (FAB)
        fab_x = ax_x + ax_w - 1.0
        fab_y = ax_y + 0.8
        rounded_rect(
            ax, fab_x, fab_y, 1.2, 1.2, get_c(colors, "tertiaryContainer"), r=0.4, z=8
        )
        text_line(
            ax,
            fab_x + 0.4,
            fab_y + 0.4,
            0.4,
            0.4,
            get_c(colors, "onTertiaryContainer"),
            z=9,
        )

        # 5. Dock (Bottom)
        dock_w = 6
        dock_h = 0.8
        dock_x = (W - dock_w) / 2
        dock_y = 0.2

        # Glassmorphism effect for Dock: surfaceContainer with alpha?
        # Let's just use inverseSurface for contrast like Mac usually does dark docks,
        # or surfaceContainerHighest for light feel.
        # Let's use `surfaceContainerHighest` for a "modern" floating dock look.
        dock_c = get_c(colors, "surfaceContainerHighest")
        rounded_rect(ax, dock_x, dock_y, dock_w, dock_h, dock_c, r=0.4, z=10)

        # Dock Icons (squares with rounded corners)
        icons = [
            "primary",
            "secondary",
            "tertiary",
            "error",
            "primaryContainer",
            "secondaryContainer",
        ]

        icon_size = 0.5
        gap = (dock_w - (len(icons) * icon_size)) / (len(icons) + 1)

        for i, token in enumerate(icons):
            ix = dock_x + gap + i * (icon_size + gap)
            iy = dock_y + (dock_h - icon_size) / 2
            c_icon = get_c(colors, token)
            rounded_rect(ax, ix, iy, icon_size, icon_size, c_icon, r=0.15, z=11)

            # Indicator dot for active app
            if i == 0 or i == 2:
                dot_c = get_c(colors, "onSurface")
                circle(ax, ix + icon_size / 2, dock_y - 0.1, 0.05, dot_c, z=10)

        # 6. Mouse Cursor
        # Draw a simple arrow polygon
        cursor_x, cursor_y = ax_x + ax_w - 2, ax_y + 2
        cursor_c = get_c(colors, "primary")
        cursor_outline = get_c(colors, "onPrimary")

        # Arrow vertices (relative)
        verts = [
            (0, 0),
            (0, -1.2),
            (0.3, -0.9),
            (0.5, -1.4),
            (0.7, -1.3),
            (0.5, -0.8),
            (0.9, -0.8),
        ]
        # Scale and translate
        verts = [(vx * 0.6 + cursor_x, vy * 0.6 + cursor_y) for vx, vy in verts]

        poly = patches.Polygon(
            verts,
            closed=True,
            facecolor=cursor_c,
            edgecolor=cursor_outline,
            linewidth=1,
            zorder=20,
        )
        ax.add_patch(poly)

    # Render Light Mode
    render_screen(axes[0], scheme_data["light"], "Light Theme")

    # Render Dark Mode
    render_screen(axes[1], scheme_data["dark"], "Dark Theme")

    plt.tight_layout()
    # Remove spacing between subplots
    plt.subplots_adjust(wspace=0.05, hspace=0)

    output_path = output_dir / f"desktop_concept_{scheme_name.lower()}.png"
    plt.savefig(output_path, dpi=300, bbox_inches="tight", pad_inches=0.1)
    plt.close()
    print(f"Saved desktop concept visualization to {output_path}")

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


def plot_scheme_comparison(schemes, output_dir):
    """Create a comparison visualization showing multiple colors per scheme."""
    scheme_names = list(schemes.keys())
    n_schemes = len(scheme_names)

    # Colors to compare for each scheme
    compare_tokens = ["primary", "secondary", "tertiary", "background", "surface"]

    fig, axes = plt.subplots(
        len(compare_tokens),
        n_schemes,
        figsize=(2.5 * n_schemes, 2 * len(compare_tokens)),
    )
    fig.suptitle(
        "Color Scheme Comparison\nLight Variant Key Colors",
        fontsize=18,
        fontweight="bold",
        y=1.02,
    )

    for col, scheme_name in enumerate(scheme_names):
        scheme_data = schemes[scheme_name]
        light_colors = scheme_data["light"]

        for row, token in enumerate(compare_tokens):
            ax = axes[row, col] if len(compare_tokens) > 1 else axes[col]
            hex_color = light_colors.get(token, "#000000")

            ax.add_patch(
                patches.Rectangle(
                    (0, 0),
                    1,
                    1,
                    facecolor=hex_to_rgb(hex_color),
                    edgecolor="black",
                    linewidth=1,
                )
            )

            # Add token name and color
            text_color = "white" if np.mean(hex_to_rgb(hex_color)) < 0.5 else "black"
            if row == 0:  # Top row shows scheme name
                ax.set_title(scheme_name, fontsize=10, pad=3)

            ax.text(
                0.5,
                0.7,
                token,
                ha="center",
                va="center",
                fontsize=9,
                fontweight="bold",
                color=text_color,
            )
            ax.text(
                0.5,
                0.3,
                hex_color,
                ha="center",
                va="center",
                fontsize=8,
                color=text_color,
            )

            ax.set_xlim(0, 1)
            ax.set_ylim(0, 1)
            ax.set_aspect("equal")
            ax.axis("off")

    plt.tight_layout()
    output_path = output_dir / "scheme_comparison.png"
    plt.savefig(output_path, dpi=300, bbox_inches="tight")
    plt.close()
    print(f"Saved scheme comparison to {output_path}")

    return output_path


def main():
    """Main function to generate all visualizations."""
    # Setup paths
    script_dir = Path(__file__).parent
    data_file = script_dir / "example_result.txt"
    output_dir = script_dir / "visualization"

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
        scheme_path = draw_fake_desktop(scheme_name, schemes[scheme_name], output_dir)
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
        output_dir, extracted_path, overview_path, comparison_path, scheme_paths
    )

    return True


def generate_html_preview(
    output_dir, extracted_path, overview_path, comparison_path, scheme_paths
):
    """Generate a high-design-quality HTML preview page."""

    # 辅助生成色彩条的逻辑
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
            --primary: #667eea;
            --bg: #f0f2f5;
            --card-bg: #ffffff;
            --text-main: #1a1c1e;
            --text-sub: #44474e;
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
            background: linear-gradient(135deg, #1a1c1e 0%, #2f3033 100%);
            color: white;
            padding: 4rem 2rem;
            text-align: center;
            margin-bottom: 3rem;
            box-shadow: 0 4px 20px rgba(0,0,0,0.1);
        }}

        h1 {{ font-size: 3rem; margin: 0; font-weight: 700; letter-spacing: -1px; }}
        .tagline {{ font-size: 1.25rem; opacity: 0.8; margin-top: 1rem; font-family: 'Roboto Mono', monospace; }}

        .container {{
            max-width: 1400px;
            margin: 0 auto;
            padding: 0 2rem;
        }}

        .section-title {{
            font-size: 1.8rem;
            margin: 4rem 0 2rem;
            display: flex;
            align-items: center;
            gap: 1rem;
        }}
        
        .section-title::after {{
            content: "";
            height: 2px;
            flex-grow: 1;
            background: linear-gradient(to right, #ccc, transparent);
        }}

        /* Top Overview Cards */
        .overview-grid {{
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 2rem;
            margin-bottom: 3rem;
        }}

        .glass-card {{
            background: var(--card-bg);
            border-radius: 24px;
            padding: 2rem;
            box-shadow: 0 10px 30px rgba(0,0,0,0.05);
            transition: transform 0.3s ease;
        }}
        
        .glass-card:hover {{ transform: translateY(-5px); }}
        .glass-card img {{ width: 100%; border-radius: 12px; }}

        /* Individual Scheme Section */
        .scheme-showcase {{
            display: flex;
            flex-direction: column;
            gap: 4rem;
            margin-bottom: 5rem;
        }}

        .scheme-block {{
            background: var(--card-bg);
            border-radius: 32px;
            padding: 3rem;
            box-shadow: 0 20px 50px rgba(0,0,0,0.08);
            overflow: hidden;
        }}

        .scheme-header {{
            display: flex;
            justify-content: space-between;
            align-items: flex-end;
            margin-bottom: 2rem;
        }}

        .scheme-info h3 {{
            font-size: 2.2rem;
            margin: 0;
            color: var(--primary);
        }}

        .desktop-preview {{
            position: relative;
            cursor: zoom-in;
            transition: transform 0.4s cubic-bezier(0.165, 0.84, 0.44, 1);
        }}

        .desktop-preview:hover {{
            transform: scale(1.02);
        }}

        .desktop-preview img {{
            width: 100%;
            height: auto;
            border-radius: 16px;
            display: block;
        }}

        .color-strip {{
            display: flex;
            height: 40px;
            border-radius: 8px;
            overflow: hidden;
            margin-top: 2rem;
            box-shadow: inset 0 0 0 1px rgba(0,0,0,0.05);
        }}

        .color-dot {{
            flex: 1;
            height: 100%;
            position: relative;
        }}

        footer {{
            padding: 5rem 2rem;
            text-align: center;
            opacity: 0.6;
            font-size: 0.9rem;
        }}

        @media (max-width: 1000px) {{
            .overview-grid {{ grid-template-columns: 1fr; }}
            .scheme-block {{ padding: 1.5rem; }}
        }}
    </style>
</head>
<body>
    <header>
        <h1>Material You</h1>
        <div class="tagline">Color System Visualization | Lean4 Implementation</div>
    </header>

    <div class="container">
        <div class="section-title">Source Insight</div>
        <div class="overview-grid">
            <div class="glass-card">
                <p><strong>Extracted Palette</strong></p>
                <img src="extracted_colors.png" alt="Extracted colors">
            </div>
            <div class="glass-card">
                <p><strong>Global Comparison</strong></p>
                <img src="scheme_comparison.png" alt="Comparison">
            </div>
        </div>

        <div class="section-title">Scheme Impressions</div>
        <div class="scheme-showcase">
"""

    for scheme_name in scheme_names:
        filename = f"desktop_concept_{scheme_name.lower()}.png"
        html_content += f"""
            <div class="scheme-block">
                <div class="scheme-header">
                    <div class="scheme-info">
                        <h3>{scheme_name}</h3>
                        <p style="color: var(--text-sub)">Desktop environment simulation for Light and Dark modes</p>
                    </div>
                </div>
                <div class="desktop-preview">
                    <img src="{filename}" alt="{scheme_name} concept">
                </div>
            </div>
"""

    html_content += """
        </div>
    </div>

    <footer>
        <p>&copy; 2024 Generated by Material You Lean4 Core</p>
        <p>Dynamic Color Algorithms Visualization</p>
    </footer>
</body>
</html>
"""

    html_path = output_dir / "index.html"
    with open(html_path, "w") as f:
        f.write(html_content)
    print(f"Generated High-Design HTML preview at {html_path}")


if __name__ == "__main__":
    main()
