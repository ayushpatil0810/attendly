"""Script to generate realistic Android home screen widget preview drawables
for Small (2x2) and Medium (4x2) widgets matching Attendly's Apple HIG theme.
"""

import math
import os
from PIL import Image, ImageDraw, ImageFont

FONT_PATH = 'assets/fonts/PlusJakartaSans-VariableFont_wght.ttf'

def get_font(size: int, bold: bool = False):
    try:
        return ImageFont.truetype(FONT_PATH, size=size)
    except Exception:
        return ImageFont.load_default()

def draw_donut_ring(
    draw: ImageDraw.ImageDraw,
    cx: float,
    cy: float,
    radius: float,
    thickness: float,
    percentage: float,
    track_color: tuple,
    progress_color: tuple,
):
    # Background track circle
    bbox = [cx - radius, cy - radius, cx + radius, cy + radius]
    draw.arc(bbox, start=0, end=360, fill=track_color, width=int(thickness))

    # Foreground progress arc (start from -90 deg / 12 o'clock)
    sweep = 360.0 * (percentage / 100.0)
    draw.arc(bbox, start=-90, end=-90 + sweep, fill=progress_color, width=int(thickness))

def generate_small_preview(output_path: str):
    # Canvas size: 360 x 360
    w, h = 360, 360
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    # Card background (white squircle with subtle Apple border)
    margin = 8
    draw.rounded_rectangle(
        [(margin, margin), (w - margin - 1, h - margin - 1)],
        radius=44,
        fill=(255, 255, 255, 255),
        outline=(229, 229, 234, 255), # #E5E5EA
        width=2,
    )

    # Header title
    f_header = get_font(18)
    title = "FALL 2026"
    tb = draw.textbbox((0, 0), title, font=f_header)
    tw = tb[2] - tb[0]
    draw.text(((w - tw) // 2, 38), title, fill=(142, 142, 147, 255), font=f_header)

    # Donut Ring (center)
    ring_cx, ring_cy = w // 2, 168
    ring_r = 74
    ring_th = 15
    draw_donut_ring(
        draw,
        cx=ring_cx,
        cy=ring_cy,
        radius=ring_r,
        thickness=ring_th,
        percentage=86.0,
        track_color=(229, 229, 234, 255),
        progress_color=(52, 199, 89, 255), # Apple Green #34C759
    )

    # Percentage in ring
    f_pct = get_font(42)
    pct_text = "86%"
    pb = draw.textbbox((0, 0), pct_text, font=f_pct)
    pw = pb[2] - pb[0]
    ph = pb[3] - pb[1]
    draw.text((ring_cx - pw // 2, ring_cy - ph // 2 - 3), pct_text, fill=(0, 0, 0, 255), font=f_pct)

    # Bottom status badge capsule
    f_badge = get_font(18)
    badge_text = "On Track"
    bb = draw.textbbox((0, 0), badge_text, font=f_badge)
    bw = bb[2] - bb[0]
    badge_w = bw + 32
    badge_h = 34
    badge_x = (w - badge_w) // 2
    badge_y = 278
    draw.rounded_rectangle(
        [(badge_x, badge_y), (badge_x + badge_w, badge_y + badge_h)],
        radius=17,
        fill=(232, 248, 238, 255), # #E8F8EE
        outline=(52, 199, 89, 255), # #34C759
        width=2,
    )
    draw.text(
        (badge_x + 16, badge_y + (badge_h - (bb[3] - bb[1])) // 2 - 2),
        badge_text,
        fill=(31, 122, 56, 255), # #1F7A38
        font=f_badge,
    )

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    im.save(output_path, 'PNG')
    print(f"Generated 2x2 widget preview: {output_path}")

def generate_medium_preview(output_path: str):
    # Canvas size: 760 x 360 (4x2 aspect ratio)
    w, h = 760, 360
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    # Card background
    margin = 8
    draw.rounded_rectangle(
        [(margin, margin), (w - margin - 1, h - margin - 1)],
        radius=44,
        fill=(255, 255, 255, 255),
        outline=(229, 229, 234, 255),
        width=2,
    )

    # Left Column: Donut Ring & Badge
    left_cx = 142
    ring_cy = 152
    ring_r = 72
    ring_th = 15
    draw_donut_ring(
        draw,
        cx=left_cx,
        cy=ring_cy,
        radius=ring_r,
        thickness=ring_th,
        percentage=86.0,
        track_color=(229, 229, 234, 255),
        progress_color=(52, 199, 89, 255),
    )

    f_pct = get_font(40)
    pct_text = "86%"
    pb = draw.textbbox((0, 0), pct_text, font=f_pct)
    pw = pb[2] - pb[0]
    ph = pb[3] - pb[1]
    draw.text((left_cx - pw // 2, ring_cy - ph // 2 - 3), pct_text, fill=(0, 0, 0, 255), font=f_pct)

    # Badge under donut
    f_badge = get_font(17)
    badge_text = "On Track"
    bb = draw.textbbox((0, 0), badge_text, font=f_badge)
    bw = bb[2] - bb[0]
    badge_w = bw + 28
    badge_h = 32
    badge_x = left_cx - badge_w // 2
    badge_y = 260
    draw.rounded_rectangle(
        [(badge_x, badge_y), (badge_x + badge_w, badge_y + badge_h)],
        radius=16,
        fill=(232, 248, 238, 255),
        outline=(52, 199, 89, 255),
        width=2,
    )
    draw.text(
        (badge_x + 14, badge_y + (badge_h - (bb[3] - bb[1])) // 2 - 2),
        badge_text,
        fill=(31, 122, 56, 255),
        font=f_badge,
    )

    # Divider
    div_x = 274
    draw.line([(div_x, 38), (div_x, h - 38)], fill=(229, 229, 234, 255), width=2)

    # Right Column: Header with Semester Title & Quick Log pill
    right_x = 304
    f_title = get_font(24)
    draw.text((right_x, 42), "Fall 2026", fill=(0, 0, 0, 255), font=f_title)

    # "Log" pill button (Apple Blue #007AFF)
    btn_w = 78
    btn_h = 34
    btn_x = w - margin - 36 - btn_w
    btn_y = 40
    draw.rounded_rectangle(
        [(btn_x, btn_y), (btn_x + btn_w, btn_y + btn_h)],
        radius=17,
        fill=(0, 122, 255, 255), # Apple Blue #007AFF
    )
    f_btn = get_font(18)
    draw.text((btn_x + 16, btn_y + 6), "+ Log", fill=(255, 255, 255, 255), font=f_btn)

    # 3 Subject rows
    subjects = [
        ("Machine Learning", 92, (52, 199, 89, 255)),   # Apple Green
        ("Computer Networks", 84, (0, 122, 255, 255)),  # Apple Blue
        ("Database Systems", 76, (52, 199, 89, 255)),   # Apple Green
    ]

    row_y = 108
    row_spacing = 68
    f_sub = get_font(20)
    f_sub_pct = get_font(19)

    for name, pct, col in subjects:
        # Subject name
        draw.text((right_x, row_y), name, fill=(0, 0, 0, 255), font=f_sub)

        # Percentage
        pct_str = f"{pct}%"
        spb = draw.textbbox((0, 0), pct_str, font=f_sub_pct)
        spw = spb[2] - spb[0]
        draw.text((w - margin - 36 - spw, row_y), pct_str, fill=(0, 0, 0, 255), font=f_sub_pct)

        # Progress bar
        bar_y = row_y + 32
        bar_x = right_x
        bar_w = (w - margin - 36) - right_x
        bar_h = 10

        # Track
        draw.rounded_rectangle(
            [(bar_x, bar_y), (bar_x + bar_w, bar_y + bar_h)],
            radius=5,
            fill=(229, 229, 234, 255),
        )
        # Fill
        fill_w = int(bar_w * (pct / 100.0))
        draw.rounded_rectangle(
            [(bar_x, bar_y), (bar_x + fill_w, bar_y + bar_h)],
            radius=5,
            fill=col,
        )

        row_y += row_spacing

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    im.save(output_path, 'PNG')
    print(f"Generated 4x2 widget preview: {output_path}")

if __name__ == '__main__':
    generate_small_preview('android/app/src/main/res/drawable-nodpi/widget_preview_small.png')
    generate_medium_preview('android/app/src/main/res/drawable-nodpi/widget_preview_medium.png')
    # Also save to drawable/ for maximum compatibility across all Android OS versions
    generate_small_preview('android/app/src/main/res/drawable/widget_preview_small.png')
    generate_medium_preview('android/app/src/main/res/drawable/widget_preview_medium.png')
    print("[SUCCESS] All widget previews generated!")
