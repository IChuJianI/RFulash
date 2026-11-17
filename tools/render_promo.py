#!/usr/bin/env python3
"""Rebuild the 3.0 store promos on top of the original 2.x artwork.

Everything outside the window/tablet screen stays pixel-identical to the
original images; only the app screenshot inside the mock is replaced with
a freshly rendered 3.0 screen (about panel shows version 3.0).
"""

import os

from PIL import Image, ImageDraw

import render_shots as rs

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIG_DIR = os.environ.get('RFULASH_PROMO_SRC', '')
OUT = os.path.join(ROOT, 'build/promo')

# screen areas measured in the original promos
PC_RECT = (793, 197, rs.PC_SCREEN_W, rs.PC_SCREEN_H)
TAB_RECT = (717, 256, rs.TAB_SCREEN_W, rs.TAB_SCREEN_H)

PC_SHOTS = [
    ('01_native_engine.png', 'home'),
    ('02_instant_play.png', 'player'),
    ('03_open_source.png', 'about'),
]
TAB_SHOTS = [
    ('01_tablet_native_engine.png', 'home'),
    ('02_tablet_instant_play.png', 'player'),
    ('03_tablet_open_source.png', 'about'),
]


def screen_mask(w, h, r_all=0, r_bottom=0, ss=4):
    m = Image.new('L', (w * ss, h * ss), 0)
    d = ImageDraw.Draw(m)
    if r_all:
        d.rounded_rectangle([0, 0, w * ss - 1, h * ss - 1],
                            radius=r_all * ss, fill=255)
    else:
        d.rounded_rectangle([0, -r_bottom * ss, w * ss - 1, h * ss - 1],
                            radius=r_bottom * ss, fill=255)
    return m.resize((w, h), Image.LANCZOS)


def compose(orig_name, screen, rect, mask):
    base = Image.open(os.path.join(ORIG_DIR, orig_name)).convert('RGB')
    x, y, w, h = rect
    assert screen.size == (w, h), (screen.size, rect)
    base.paste(screen, (x, y), mask)
    out = os.path.join(OUT, orig_name)
    os.makedirs(OUT, exist_ok=True)
    base.save(out, 'PNG', optimize=True)
    return out, os.path.getsize(out)


if __name__ == '__main__':
    if not ORIG_DIR:
        raise SystemExit('Set RFULASH_PROMO_SRC to the folder with the original 2.x promo images.')
    pc_mask = screen_mask(rs.PC_SCREEN_W, rs.PC_SCREEN_H, r_bottom=12)
    tab_mask = screen_mask(rs.TAB_SCREEN_W, rs.TAB_SCREEN_H, r_all=26)
    for name, kind in PC_SHOTS:
        path, size = compose(name, rs.promo_pc_screen(kind), PC_RECT, pc_mask)
        print('%-28s %7.1f KB' % (os.path.basename(path), size / 1024))
    for name, kind in TAB_SHOTS:
        path, size = compose(name, rs.promo_tablet_screen(kind), TAB_RECT, tab_mask)
        print('%-28s %7.1f KB' % (os.path.basename(path), size / 1024))
