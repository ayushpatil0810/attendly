"""Script to generate Android adaptive icons, legacy mipmap icons, store assets,
and splash/logo assets from attendly_calendar_symbol_transparent.svg and attendly_primary_splash_logo.svg.
"""

import io
import os
import resvg_py
from PIL import Image, ImageDraw

WARM_WHITE = (0xFF, 0xFA, 0xF9, 0xFF)
FONT_PATH = 'assets/fonts/PlusJakartaSans-VariableFont_wght.ttf'
SYMBOL_SVG = 'attendly_calendar_symbol_transparent.svg'
SPLASH_SVG = 'attendly_primary_splash_logo.svg'

def generate_all() -> None:
    # 1. Splash & Brand Logo Assets
    os.makedirs('assets/images', exist_ok=True)
    font_files = [FONT_PATH] if os.path.exists(FONT_PATH) else None

    # Read original splash logo SVG and generate tightly-cropped version
    # The original SVG has viewBox="0 0 1200 600" with content located from x=185 to 960 and y=165 to 450.
    # By removing the 1200x600 empty margins, the logo displays at its true intended size without being shrunken.
    with open(SPLASH_SVG, 'r', encoding='utf-8') as f:
        svg_content = f.read()

    svg_transparent = svg_content.replace('<rect width="1200" height="600" fill="#FFFAF9"/>', '')
    svg_tight = svg_transparent.replace(
        'width="1200" height="600" viewBox="0 0 1200 600"',
        'width="775" height="285" viewBox="185 165 775 285"',
    )

    logo_bytes = resvg_py.svg_to_bytes(
        svg_string=svg_tight,
        font_files=font_files,
        shape_rendering='geometric_precision',
        text_rendering='geometric_precision',
        image_rendering='optimize_quality',
    )
    with open('assets/images/app_logo.png', 'wb') as f:
        f.write(logo_bytes)
    with open('assets/images/splash_logo.png', 'wb') as f:
        f.write(logo_bytes)
    print('Generated assets/images/app_logo.png and splash_logo.png (tight transparent, 775x285)')

    # 2. Android Adaptive Icons (108dp canvas with central 72dp safe zone)
    # The transparent calendar symbol is rendered at ~68dp inside the 72dp safe zone
    # Canvas dimensions: mdpi=108, hdpi=162, xhdpi=216, xxhdpi=324, xxxhdpi=432
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
        print(f'Generated adaptive foreground: {fg_path} ({canvas_size}x{canvas_size})')

    # 3. Legacy Fallback Icons (ic_launcher.png and ic_launcher_round.png)
    legacy_sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }

    for folder, size in legacy_sizes.items():
        folder_path = os.path.join('android', 'app', 'src', 'main', 'res', folder)

        # Rounded rectangle icon
        rx = max(4, int(size * 0.22))
        sym_size = int(size * 0.72)
        sym_png = resvg_py.svg_to_bytes(svg_path=SYMBOL_SVG, width=sym_size, height=sym_size)
        sym_img = Image.open(io.BytesIO(sym_png)).convert('RGBA')

        icon_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(icon_img)
        draw.rounded_rectangle([(0, 0), (size - 1, size - 1)], radius=rx, fill=WARM_WHITE)
        offset = ((size - sym_size) // 2, (size - sym_size) // 2)
        icon_img.paste(sym_img, offset, sym_img)
        icon_path = os.path.join(folder_path, 'ic_launcher.png')
        icon_img.save(icon_path, 'PNG')

        # Round icon (ic_launcher_round.png)
        round_sym_size = int(size * 0.65)
        round_sym_png = resvg_py.svg_to_bytes(svg_path=SYMBOL_SVG, width=round_sym_size, height=round_sym_size)
        round_sym_img = Image.open(io.BytesIO(round_sym_png)).convert('RGBA')

        round_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        round_draw = ImageDraw.Draw(round_img)
        round_draw.ellipse([(0, 0), (size - 1, size - 1)], fill=WARM_WHITE)
        round_offset = ((size - round_sym_size) // 2, (size - round_sym_size) // 2)
        round_img.paste(round_sym_img, round_offset, round_sym_img)
        round_path = os.path.join(folder_path, 'ic_launcher_round.png')
        round_img.save(round_path, 'PNG')

        print(f'Generated legacy icons in {folder} ({size}x{size})')

    # 4. Store Assets (assets/icons/app_icon.png and app_icon_1024.png)
    os.makedirs('assets/icons', exist_ok=True)
    for store_size, name in [(512, 'app_icon.png'), (1024, 'app_icon_1024.png')]:
        rx = int(store_size * 0.22)
        sym_size = int(store_size * 0.72)
        sym_png = resvg_py.svg_to_bytes(svg_path=SYMBOL_SVG, width=sym_size, height=sym_size)
        sym_img = Image.open(io.BytesIO(sym_png)).convert('RGBA')

        icon_img = Image.new('RGBA', (store_size, store_size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(icon_img)
        draw.rounded_rectangle([(0, 0), (store_size - 1, store_size - 1)], radius=rx, fill=WARM_WHITE)
        offset = ((store_size - sym_size) // 2, (store_size - sym_size) // 2)
        icon_img.paste(sym_img, offset, sym_img)
        icon_path = os.path.join('assets', 'icons', name)
        icon_img.save(icon_path, 'PNG')
        print(f'Generated store icon: {icon_path} ({store_size}x{store_size})')

if __name__ == '__main__':
    generate_all()
