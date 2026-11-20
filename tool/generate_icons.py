"""Script to generate Android adaptive icons, legacy mipmap icons, iOS AppIcon assets,
and store assets from attendly_calendar_symbol_transparent.svg.
"""

import io
import math
import os
import resvg_py
from PIL import Image, ImageDraw

WARM_WHITE_RGBA = (0xFF, 0xFA, 0xF9, 0xFF)
WARM_WHITE_RGB = (0xFF, 0xFA, 0xF9)
SYMBOL_SVG = 'attendly_calendar_symbol_transparent.svg'
FONT_PATH = 'assets/fonts/PlusJakartaSans-VariableFont_wght.ttf'

def generate_all() -> None:
    if not os.path.exists(SYMBOL_SVG):
        raise FileNotFoundError(f"Source symbol SVG not found at '{SYMBOL_SVG}'")

    print(f"Using '{SYMBOL_SVG}' as master application icon source.")

    # -------------------------------------------------------------------------
    # 1. Android Adaptive Icons (ic_launcher_foreground.png)
    # Canvas: 108dp. Safe zone: 72dp diameter centered.
    # The transparent calendar symbol is rendered at ~68dp inside the 72dp safe zone.
    # Densities: mdpi=108, hdpi=162, xhdpi=216, xxhdpi=324, xxxhdpi=432
    # -------------------------------------------------------------------------
    adaptive_densities = {
        'mipmap-mdpi': (108, 68),
        'mipmap-hdpi': (162, 102),
        'mipmap-xhdpi': (216, 136),
        'mipmap-xxhdpi': (324, 204),
        'mipmap-xxxhdpi': (432, 272),
    }

    for folder, (canvas_size, sym_size) in adaptive_densities.items():
        folder_path = os.path.join('android', 'app', 'src', 'main', 'res', folder)
        os.makedirs(folder_path, exist_ok=True)

        sym_png = resvg_py.svg_to_bytes(
            svg_path=SYMBOL_SVG,
            width=sym_size,
            height=sym_size,
            shape_rendering='geometric_precision',
            image_rendering='optimize_quality',
        )
        sym_img = Image.open(io.BytesIO(sym_png)).convert('RGBA')

        fg_canvas = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
        offset = ((canvas_size - sym_size) // 2, (canvas_size - sym_size) // 2)
        fg_canvas.paste(sym_img, offset, sym_img)

        fg_path = os.path.join(folder_path, 'ic_launcher_foreground.png')
        fg_canvas.save(fg_path, 'PNG')
        print(f"Generated Android adaptive foreground: {fg_path} ({canvas_size}x{canvas_size})")

    # -------------------------------------------------------------------------
    # 2. Android Legacy Launcher Icons (ic_launcher.png & ic_launcher_round.png)
    # -------------------------------------------------------------------------
    legacy_sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }

    for folder, size in legacy_sizes.items():
        folder_path = os.path.join('android', 'app', 'src', 'main', 'res', folder)

        # Rounded rectangle icon (ic_launcher.png)
        rx = max(4, int(size * 0.22))
        sym_size = int(size * 0.72)
        sym_png = resvg_py.svg_to_bytes(
            svg_path=SYMBOL_SVG,
            width=sym_size,
            height=sym_size,
            shape_rendering='geometric_precision',
            image_rendering='optimize_quality',
        )
        sym_img = Image.open(io.BytesIO(sym_png)).convert('RGBA')

        icon_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(icon_img)
        draw.rounded_rectangle([(0, 0), (size - 1, size - 1)], radius=rx, fill=WARM_WHITE_RGBA)
        offset = ((size - sym_size) // 2, (size - sym_size) // 2)
        icon_img.paste(sym_img, offset, sym_img)
        icon_path = os.path.join(folder_path, 'ic_launcher.png')
        icon_img.save(icon_path, 'PNG')

        # Round icon (ic_launcher_round.png)
        round_sym_size = int(size * 0.65)
        round_sym_png = resvg_py.svg_to_bytes(
            svg_path=SYMBOL_SVG,
            width=round_sym_size,
            height=round_sym_size,
            shape_rendering='geometric_precision',
            image_rendering='optimize_quality',
        )
        round_sym_img = Image.open(io.BytesIO(round_sym_png)).convert('RGBA')

        round_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        round_draw = ImageDraw.Draw(round_img)
        round_draw.ellipse([(0, 0), (size - 1, size - 1)], fill=WARM_WHITE_RGBA)
        round_offset = ((size - round_sym_size) // 2, (size - round_sym_size) // 2)
        round_img.paste(round_sym_img, round_offset, round_sym_img)
        round_path = os.path.join(folder_path, 'ic_launcher_round.png')
        round_img.save(round_path, 'PNG')

        print(f"Generated Android legacy icons in {folder} ({size}x{size})")

    # -------------------------------------------------------------------------
    # 3. iOS AppIcon Assets (ios/Runner/Assets.xcassets/AppIcon.appiconset/)
    # iOS icons require full-bleed solid background without transparency.
    # -------------------------------------------------------------------------
    ios_icon_dir = os.path.join('ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    os.makedirs(ios_icon_dir, exist_ok=True)

    ios_icons = [
        ('Icon-App-20x20@1x.png', 20),
        ('Icon-App-20x20@2x.png', 40),
        ('Icon-App-20x20@3x.png', 60),
        ('Icon-App-29x29@1x.png', 29),
        ('Icon-App-29x29@2x.png', 58),
        ('Icon-App-29x29@3x.png', 87),
        ('Icon-App-40x40@1x.png', 40),
        ('Icon-App-40x40@2x.png', 80),
        ('Icon-App-40x40@3x.png', 120),
        ('Icon-App-60x60@2x.png', 120),
        ('Icon-App-60x60@3x.png', 180),
        ('Icon-App-76x76@1x.png', 76),
        ('Icon-App-76x76@2x.png', 152),
        ('Icon-App-83.5x83.5@2x.png', 167),
        ('Icon-App-1024x1024@1x.png', 1024),
    ]

    for filename, px_size in ios_icons:
        sym_size = max(1, int(px_size * 0.72))
        sym_png = resvg_py.svg_to_bytes(
            svg_path=SYMBOL_SVG,
            width=sym_size,
            height=sym_size,
            shape_rendering='geometric_precision',
            image_rendering='optimize_quality',
        )
        sym_img = Image.open(io.BytesIO(sym_png)).convert('RGBA')

        # Solid RGB canvas (Apple HIG requires zero alpha channel for app icons)
        ios_canvas = Image.new('RGB', (px_size, px_size), WARM_WHITE_RGB)
        offset = ((px_size - sym_size) // 2, (px_size - sym_size) // 2)
        ios_canvas.paste(sym_img, offset, sym_img)

        out_path = os.path.join(ios_icon_dir, filename)
        ios_canvas.save(out_path, 'PNG')
        print(f"Generated iOS icon: {out_path} ({px_size}x{px_size})")

    # -------------------------------------------------------------------------
    # 4. Store Assets (assets/icons/app_icon.png and app_icon_1024.png)
    # -------------------------------------------------------------------------
    os.makedirs('assets/icons', exist_ok=True)
    # 512x512 Store / In-App Icon (with rounded tile)
    store_512_sym = int(512 * 0.72)
    s512_png = resvg_py.svg_to_bytes(svg_path=SYMBOL_SVG, width=store_512_sym, height=store_512_sym)
    s512_img = Image.open(io.BytesIO(s512_png)).convert('RGBA')
    icon_512 = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    d512 = ImageDraw.Draw(icon_512)
    d512.rounded_rectangle([(0, 0), (511, 511)], radius=112, fill=WARM_WHITE_RGBA)
    icon_512.paste(s512_img, ((512 - store_512_sym) // 2, (512 - store_512_sym) // 2), s512_img)
    icon_512.save('assets/icons/app_icon.png', 'PNG')
    print("Generated store icon: assets/icons/app_icon.png (512x512)")

    # 1024x1024 Full-bleed Store Icon
    store_1024_sym = int(1024 * 0.72)
    s1024_png = resvg_py.svg_to_bytes(svg_path=SYMBOL_SVG, width=store_1024_sym, height=store_1024_sym)
    s1024_img = Image.open(io.BytesIO(s1024_png)).convert('RGBA')
    icon_1024 = Image.new('RGB', (1024, 1024), WARM_WHITE_RGB)
    icon_1024.paste(s1024_img, ((1024 - store_1024_sym) // 2, (1024 - store_1024_sym) // 2), s1024_img)
    icon_1024.save('assets/icons/app_icon_1024.png', 'PNG')
    print("Generated store icon: assets/icons/app_icon_1024.png (1024x1024 RGB)")

    print("\n[SUCCESS] All application launcher and home screen icons successfully generated from attendly_calendar_symbol_transparent.svg!")

if __name__ == '__main__':
    generate_all()
