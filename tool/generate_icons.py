"""Script to generate Android adaptive icons, legacy mipmap icons, iOS AppIcon assets,
store assets, and splash logos from attendly.svg.
"""

import io
import math
import os
import resvg_py
from PIL import Image, ImageDraw, ImageFont

WHITE_RGBA = (255, 255, 255, 255)
WHITE_RGB = (255, 255, 255)
DARK_INK_RGBA = (0, 0, 0, 255)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SVG_FILE = os.path.join(SCRIPT_DIR, 'attendly.svg')
FONT_PATH = os.path.join(SCRIPT_DIR, '..', 'assets', 'fonts', 'PlusJakartaSans-VariableFont_wght.ttf')

def get_symbol_image(target_h: int) -> Image.Image:
    """Render attendly.svg at target height preserving aspect ratio (868/929)."""
    target_w = max(1, int(round(target_h * 868.0 / 929.0)))
    png_bytes = resvg_py.svg_to_bytes(
        svg_path=SVG_FILE,
        width=target_w,
        height=target_h,
        shape_rendering='geometric_precision',
        image_rendering='optimize_quality',
    )
    return Image.open(io.BytesIO(png_bytes)).convert('RGBA')

def generate_all() -> None:
    if not os.path.exists(SVG_FILE):
        raise FileNotFoundError(f"Source SVG not found at '{SVG_FILE}'")

    print(f"Generating application icons from '{SVG_FILE}'...")

    # -------------------------------------------------------------------------
    # 1. Android Adaptive Icons (ic_launcher_foreground.png)
    # Total canvas: 108dp. Safe zone: 66-72dp diameter centered.
    # Scale factor: 0.4907 ensures the entire symbol (including outer tabs & checkmark)
    # stays strictly inside the 66dp circular safe zone across all Android launchers.
    # -------------------------------------------------------------------------
    adaptive_densities = {
        'mipmap-mdpi': (108, 53),
        'mipmap-hdpi': (162, 79),
        'mipmap-xhdpi': (216, 106),
        'mipmap-xxhdpi': (324, 159),
        'mipmap-xxxhdpi': (432, 212),
    }

    for folder, (canvas_size, sym_h) in adaptive_densities.items():
        folder_path = os.path.join('android', 'app', 'src', 'main', 'res', folder)
        os.makedirs(folder_path, exist_ok=True)

        sym_img = get_symbol_image(sym_h)
        fg_canvas = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
        offset = ((canvas_size - sym_img.width) // 2, (canvas_size - sym_img.height) // 2)
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
        sym_h = max(1, int(size * 0.68))
        sym_img = get_symbol_image(sym_h)

        icon_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(icon_img)
        draw.rounded_rectangle([(0, 0), (size - 1, size - 1)], radius=rx, fill=WHITE_RGBA)
        offset = ((size - sym_img.width) // 2, (size - sym_img.height) // 2)
        icon_img.paste(sym_img, offset, sym_img)
        icon_path = os.path.join(folder_path, 'ic_launcher.png')
        icon_img.save(icon_path, 'PNG')

        # Round icon (ic_launcher_round.png)
        round_sym_h = max(1, int(size * 0.58))
        round_sym_img = get_symbol_image(round_sym_h)

        round_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        round_draw = ImageDraw.Draw(round_img)
        round_draw.ellipse([(0, 0), (size - 1, size - 1)], fill=WHITE_RGBA)
        round_offset = ((size - round_sym_img.width) // 2, (size - round_sym_img.height) // 2)
        round_img.paste(round_sym_img, round_offset, round_sym_img)
        round_path = os.path.join(folder_path, 'ic_launcher_round.png')
        round_img.save(round_path, 'PNG')

        print(f"Generated Android legacy icons in {folder} ({size}x{size})")

    # -------------------------------------------------------------------------
    # 3. iOS AppIcon Assets (ios/Runner/Assets.xcassets/AppIcon.appiconset/)
    # Full-bleed solid background without transparency.
    # -------------------------------------------------------------------------
    ios_icon_dir = os.path.join('ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    if os.path.exists(ios_icon_dir):
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
            sym_h = max(1, int(px_size * 0.70))
            sym_img = get_symbol_image(sym_h)

            ios_canvas = Image.new('RGB', (px_size, px_size), WHITE_RGB)
            offset = ((px_size - sym_img.width) // 2, (px_size - sym_img.height) // 2)
            ios_canvas.paste(sym_img, offset, sym_img)

            out_path = os.path.join(ios_icon_dir, filename)
            ios_canvas.save(out_path, 'PNG')
            print(f"Generated iOS icon: {out_path} ({px_size}x{px_size})")

    # -------------------------------------------------------------------------
    # 4. Store Assets (assets/icons/app_icon.png and app_icon_1024.png)
    # -------------------------------------------------------------------------
    os.makedirs('assets/icons', exist_ok=True)

    # 512x512 Store / In-App Icon (with rounded tile)
    s512_h = 350
    s512_img = get_symbol_image(s512_h)
    icon_512 = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    d512 = ImageDraw.Draw(icon_512)
    d512.rounded_rectangle([(0, 0), (511, 511)], radius=112, fill=WHITE_RGBA)
    icon_512.paste(s512_img, ((512 - s512_img.width) // 2, (512 - s512_img.height) // 2), s512_img)
    icon_512.save('assets/icons/app_icon.png', 'PNG')
    print("Generated store icon: assets/icons/app_icon.png (512x512)")

    # 1024x1024 Full-bleed Store Icon (Apple HIG & Play Store require RGB without alpha)
    s1024_h = 680
    s1024_img = get_symbol_image(s1024_h)
    icon_1024 = Image.new('RGB', (1024, 1024), WHITE_RGB)
    icon_1024.paste(s1024_img, ((1024 - s1024_img.width) // 2, (1024 - s1024_img.height) // 2), s1024_img)
    icon_1024.save('assets/icons/app_icon_1024.png', 'PNG')
    print("Generated store icon: assets/icons/app_icon_1024.png (1024x1024 RGB)")

    # -------------------------------------------------------------------------
    # 5. Logo Lockup Assets (assets/images/app_logo.png and splash_logo.png)
    # 775x285 lockup: Symbol on the left + "attendly" wordmark on the right
    # -------------------------------------------------------------------------
    os.makedirs('assets/images', exist_ok=True)
    logo_w, logo_h = 775, 285
    sym_logo_h = 210
    sym_logo = get_symbol_image(sym_logo_h)

    lockup = Image.new('RGBA', (logo_w, logo_h), (0, 0, 0, 0))
    draw_lockup = ImageDraw.Draw(lockup)

    # Symbol placed on left
    sym_x = 48
    sym_y = (logo_h - sym_logo.height) // 2
    lockup.paste(sym_logo, (sym_x, sym_y), sym_logo)

    # Wordmark "attendly"
    if os.path.exists(FONT_PATH):
        try:
            font = ImageFont.truetype(FONT_PATH, size=116)
        except Exception:
            font = ImageFont.load_default()
    else:
        font = ImageFont.load_default()

    text_x = sym_x + sym_logo.width + 36
    # Measure text bounding box to center vertically
    try:
        t_bbox = draw_lockup.textbbox((text_x, 0), "attendly", font=font)
        text_h = t_bbox[3] - t_bbox[1]
        text_y = (logo_h - text_h) // 2 - t_bbox[1]
    except Exception:
        text_y = (logo_h - 116) // 2

    draw_lockup.text((text_x, text_y), "attendly", fill=DARK_INK_RGBA, font=font)

    lockup.save('assets/images/app_logo.png', 'PNG')
    lockup.save('assets/images/splash_logo.png', 'PNG')
    print("Generated brand logo assets: assets/images/app_logo.png & splash_logo.png (775x285)")

    print("\n[SUCCESS] All application launcher, store, and brand assets successfully generated from attendly.svg!")

if __name__ == '__main__':
    generate_all()
