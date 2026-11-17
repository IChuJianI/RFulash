#!/usr/bin/env python3
"""RFulash store screenshots at exact store resolutions.

The content (file names, scores) is fictional; layout tokens, chrome and
component geometry mirror entry/src/main/ets (dark theme).
"""

import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'build/shots')
ICON_PATH = os.path.join(ROOT, 'store/icon/rfulash_icon_1024.png')
FONT_PATH = '/system/fonts/HarmonyOS_Sans_SC.ttf'

SS = 2

BG = (14, 17, 22)
SURFACE = (26, 31, 39)
FILL = (38, 45, 56)
TEXT = (255, 255, 255)
TEXT2 = (183, 184, 185)
TEXT3 = (138, 148, 166)
ACCENT = (237, 111, 33)
ON_ACCENT = (255, 255, 255)
DIV_SURFACE = (49, 53, 61)
DIV_FILL = (60, 66, 77)
ACCENT_SOFT = (58, 43, 38)
SCRIM = (0, 0, 0, 150)

FILES_A = ['小羊快跑.swf', '星际漫游.swf', '森林冒险.swf', '弹珠物语.swf']
FILES_B = ['像素赛车.swf', '经典城堡.swf']


class C:
    def __init__(self, w, h):
        self.W = w
        self.H = h
        self.img = Image.new('RGBA', (w * SS, h * SS), (0, 0, 0, 255))
        self.d = ImageDraw.Draw(self.img)
        self.fc = {}
        self.icon_src = Image.open(ICON_PATH).convert('RGBA')

    def p(self, v):
        return int(round(v * SS))

    def font(self, size, weight='Regular'):
        key = (size, weight)
        if key not in self.fc:
            f = ImageFont.truetype(FONT_PATH, max(4, self.p(size)))
            try:
                f.set_variation_by_name(weight)
            except Exception:
                pass
            self.fc[key] = f
        return self.fc[key]

    def tw(self, s, size, weight='Regular'):
        return self.font(size, weight).getlength(s) / SS

    def text(self, x, y, s, size=20, weight='Regular', color=TEXT, anchor='lm'):
        self.d.text((self.p(x), self.p(y)), s, font=self.font(size, weight),
                    fill=color, anchor=anchor)

    def rect(self, x, y, w, h, fill):
        self.d.rectangle([self.p(x), self.p(y), self.p(x + w), self.p(y + h)], fill=fill)

    def rrect(self, x, y, w, h, rad, fill=None, outline=None, ow=1):
        kw = {}
        if fill is not None:
            kw['fill'] = fill
        if outline is not None:
            kw['outline'] = outline
            kw['width'] = max(1, self.p(ow))
        self.d.rounded_rectangle([self.p(x), self.p(y), self.p(x + w), self.p(y + h)],
                                 radius=self.p(rad), **kw)

    def ellipse(self, x, y, w, h, fill=None, outline=None, ow=1):
        kw = {}
        if fill is not None:
            kw['fill'] = fill
        if outline is not None:
            kw['outline'] = outline
            kw['width'] = max(1, self.p(ow))
        self.d.ellipse([self.p(x), self.p(y), self.p(x + w), self.p(y + h)], **kw)

    def line(self, pts, fill, width=2, joint='curve'):
        self.d.line([(self.p(x), self.p(y)) for x, y in pts],
                    fill=fill, width=max(1, self.p(width)), joint=joint)

    def poly(self, pts, fill):
        self.d.polygon([(self.p(x), self.p(y)) for x, y in pts], fill=fill)

    def rrect_alpha(self, x, y, w, h, rad, fill=None, outline=None, ow=1):
        layer = Image.new('RGBA', self.img.size, (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        kw = {}
        if fill is not None:
            kw['fill'] = fill
        if outline is not None:
            kw['outline'] = outline
            kw['width'] = max(1, self.p(ow))
        d.rounded_rectangle([self.p(x), self.p(y), self.p(x + w), self.p(y + h)],
                            radius=self.p(rad), **kw)
        self.img.alpha_composite(layer)
        self.d = ImageDraw.Draw(self.img)

    def scrim(self, alpha=150):
        layer = Image.new('RGBA', self.img.size, (0, 0, 0, alpha))
        self.img.alpha_composite(layer)
        self.d = ImageDraw.Draw(self.img)

    def shadow(self, x, y, w, h, rad, blur, dy, alpha=150):
        layer = Image.new('RGBA', self.img.size, (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        d.rounded_rectangle([self.p(x), self.p(y + dy), self.p(x + w), self.p(y + dy + h)],
                            radius=self.p(rad), fill=(0, 0, 0, alpha))
        layer = layer.filter(ImageFilter.GaussianBlur(self.p(blur)))
        self.img.alpha_composite(layer)
        self.d = ImageDraw.Draw(self.img)

    def app_icon(self, x, y, size, rad):
        n = self.p(size)
        src = self.icon_src.resize((n, n), Image.LANCZOS)
        mask = Image.new('L', (n, n), 0)
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, n - 1, n - 1],
                                               radius=self.p(rad), fill=255)
        self.img.paste(src, (self.p(x), self.p(y)), mask)
        self.d = ImageDraw.Draw(self.img)

    def render(self):
        return self.img.convert('RGB').resize((self.W, self.H), Image.LANCZOS)

    def save(self, name):
        os.makedirs(os.path.dirname(name), exist_ok=True)
        out = self.render()
        out.save(name, 'PNG', optimize=True)
        return os.path.getsize(name)


# ── line glyphs ─────────────────────────────────────────────────────────

def glyph(c, name, cx, cy, s, color, width=None):
    lw = width if width is not None else max(2.0, s * 0.09)

    if name == 'home':
        c.line([(cx - s * .5, cy - s * .02), (cx, cy - s * .48),
                (cx + s * .5, cy - s * .02)], color, lw)
        c.line([(cx - s * .34, cy - s * .12), (cx - s * .34, cy + s * .44),
                (cx + s * .34, cy + s * .44), (cx + s * .34, cy - s * .12)], color, lw)
        c.line([(cx - s * .1, cy + s * .44), (cx - s * .1, cy + s * .12),
                (cx + s * .1, cy + s * .12), (cx + s * .1, cy + s * .44)], color, lw)
    elif name == 'play':
        c.poly([(cx - s * .26, cy - s * .4), (cx + s * .42, cy),
                (cx - s * .26, cy + s * .4)], color)
    elif name == 'pause':
        c.rrect(cx - s * .3, cy - s * .4, s * .2, s * .8, s * .04, fill=color)
        c.rrect(cx + s * .1, cy - s * .4, s * .2, s * .8, s * .04, fill=color)
    elif name == 'folder':
        x0, y0, w, h = cx - s * .5, cy - s * .3, s, s * .62
        c.line([(x0, y0), (x0 + s * .34, y0), (x0 + s * .44, y0 - s * .12),
                (x0 + w, y0 - s * .12), (x0 + w, y0 + h), (x0, y0 + h), (x0, y0)],
               color, lw)
    elif name == 'film':
        x0, y0 = cx - s * .46, cy - s * .34
        w, h = s * .92, s * .68
        c.d.rounded_rectangle([c.p(x0), c.p(y0), c.p(x0 + w), c.p(y0 + h)],
                              radius=c.p(s * .1), outline=color, width=max(1, c.p(lw)))
        for i in range(3):
            yy = y0 + h * (0.16 + i * 0.28)
            c.ellipse(x0 + w * .1, yy, s * .1, s * .1, fill=color)
            c.ellipse(x0 + w * .8, yy, s * .1, s * .1, fill=color)
        c.line([(x0 + w * .3, y0 + h * .5), (x0 + w * .7, y0 + h * .5)], color, lw * .8)
    elif name == 'clock':
        c.ellipse(cx - s * .43, cy - s * .43, s * .86, s * .86, outline=color, ow=lw)
        c.line([(cx, cy), (cx, cy - s * .26)], color, lw)
        c.line([(cx, cy), (cx + s * .2, cy + s * .12)], color, lw)
    elif name == 'gear':
        rr = s * .27
        c.ellipse(cx - rr, cy - rr, rr * 2, rr * 2, outline=color, ow=lw)
        c.ellipse(cx - s * .07, cy - s * .07, s * .14, s * .14, outline=color, ow=lw * .8)
        import math
        for i in range(8):
            a = math.pi * 2 * i / 8
            c.line([(cx + math.cos(a) * rr * 1.15, cy + math.sin(a) * rr * 1.15),
                    (cx + math.cos(a) * rr * 1.6, cy + math.sin(a) * rr * 1.6)],
                   color, lw)
    elif name == 'fullscreen':
        d = s * .42
        c.line([(cx - d, cy - d * .55), (cx - d, cy - d), (cx - d * .55, cy - d)], color, lw)
        c.line([(cx + d * .55, cy - d), (cx + d, cy - d), (cx + d, cy - d * .55)], color, lw)
        c.line([(cx + d, cy + d * .55), (cx + d, cy + d), (cx + d * .55, cy + d)], color, lw)
        c.line([(cx - d * .55, cy + d), (cx - d, cy + d), (cx - d, cy + d * .55)], color, lw)
    elif name == 'close':
        d = s * .3
        c.line([(cx - d, cy - d), (cx + d, cy + d)], color, lw)
        c.line([(cx + d, cy - d), (cx - d, cy + d)], color, lw)
    elif name == 'search':
        c.ellipse(cx - s * .38, cy - s * .38, s * .55, s * .55, outline=color, ow=lw)
        c.line([(cx + s * .08, cy + s * .08), (cx + s * .38, cy + s * .38)], color, lw)
    elif name == 'chevron_right':
        c.line([(cx - s * .12, cy - s * .26), (cx + s * .12, cy),
                (cx - s * .12, cy + s * .26)], color, lw)
    elif name == 'chevron_down':
        c.line([(cx - s * .26, cy - s * .12), (cx, cy + s * .12),
                (cx + s * .26, cy - s * .12)], color, lw)
    elif name == 'check':
        c.line([(cx - s * .32, cy + s * .02), (cx - s * .08, cy + s * .26),
                (cx + s * .34, cy - s * .26)], color, lw)
    elif name == 'shield':
        c.line([(cx, cy - s * .42), (cx + s * .34, cy - s * .26), (cx + s * .3, cy + s * .12),
                (cx, cy + s * .42), (cx - s * .3, cy + s * .12), (cx - s * .34, cy - s * .26),
                (cx, cy - s * .42)], color, lw)
        c.line([(cx - s * .14, cy), (cx - s * .02, cy + s * .12),
                (cx + s * .16, cy - s * .1)], color, lw)
    elif name == 'info':
        c.ellipse(cx - s * .42, cy - s * .42, s * .84, s * .84, outline=color, ow=lw)
        c.ellipse(cx - s * .05, cy - s * .24, s * .1, s * .1, fill=color)
        c.line([(cx, cy - s * .04), (cx, cy + s * .22)], color, lw)
    else:
        raise ValueError(name)


# ── chrome ──────────────────────────────────────────────────────────────

def status_bar(c, k=1.0):
    h = 48 * k
    c.rect(0, 0, c.W, h, BG)
    c.text(44 * k, h / 2 + 1, '10:24', 24 * k, 'Medium', TEXT)
    x = c.W - 60 * k
    c.rrect(x, h / 2 - 9 * k, 36 * k, 18 * k, 5 * k, outline=TEXT, ow=2 * k)
    c.rrect(x + 3 * k, h / 2 - 6 * k, 24 * k, 12 * k, 3 * k, fill=TEXT)
    c.rect(x + 37 * k, h / 2 - 4 * k, 3 * k, 8 * k, TEXT)
    # wifi arcs
    wx = c.W - 118 * k
    for i, r in enumerate([10, 17, 24]):
        r *= k
        c.d.arc([c.p(wx - r), c.p(h / 2 - r + 6 * k), c.p(wx + r), c.p(h / 2 + r + 6 * k)],
                start=225, end=315, fill=TEXT, width=max(1, c.p(2 * k)))
    c.ellipse(wx - 2 * k, h / 2 + 2 * k, 4 * k, 4 * k, fill=TEXT)


def sidebar(c, active, S, h):
    sw = 280 * S
    c.rect(0, 0, sw, h, SURFACE)
    c.app_icon(18 * S, 18 * S, 38 * S, 11 * S)
    c.text(66 * S, 33 * S, 'RFulash', 17 * S, 'Bold', TEXT)
    c.text(66 * S, 52 * S, '鸿蒙原生 Flash 播放器', 11 * S, 'Regular', TEXT2)

    y = 96 * S
    for idx, (label, icon) in enumerate([('首页', 'home'), ('播放', 'play')]):
        x, w, hh = 12 * S, sw - 24 * S, 40 * S
        if idx == active:
            c.rrect(x, y, w, hh, 8 * S, fill=ACCENT_SOFT)
            col = ACCENT
        else:
            col = TEXT
        glyph(c, icon, x + 22 * S, y + hh / 2, 18 * S, col)
        c.text(x + 40 * S, y + hh / 2 + 1, label, 15 * S, 'Medium' if idx == active else 'Regular', col)
        y += 44 * S

    ay = h - 54 * S
    glyph(c, 'info', 34 * S, ay + 20 * S, 18 * S, TEXT)
    c.text(52 * S, ay + 21 * S, '关于', 15 * S, 'Regular', TEXT)


def title_bar(c, x0, y0, w, title, sub, icons, S, h):
    c.rect(x0, y0, w, h, SURFACE)
    cx = x0 + w / 2
    if sub:
        c.text(cx, y0 + h * 0.36, title, 16 * S, 'Medium', TEXT, 'mm')
        c.text(cx, y0 + h * 0.7, sub, 11 * S, 'Regular', TEXT2, 'mm')
    else:
        c.text(cx, y0 + h / 2 + 1, title, 17 * S, 'Medium', TEXT, 'mm')
    x = x0 + w - 30 * S
    for icon in reversed(icons):
        glyph(c, icon, x - 11 * S, y0 + h / 2, 21 * S, TEXT)
        x -= 36 * S


def home_content(c, cx, y, S):
    icon = 80 * S
    c.app_icon(cx - icon / 2, y, icon, 22 * S)
    yy = y + icon + 22 * S
    c.text(cx, yy, 'RFulash', 26 * S, 'Bold', TEXT, 'mm')
    yy += 22 * S
    c.text(cx, yy, '鸿蒙原生 Flash 播放器', 14 * S, 'Regular', TEXT2, 'mm')
    yy += 22 * S
    c.text(cx, yy, '原生 Ruffle 引擎驱动，无需浏览器。选择本地 SWF 文件，', 14 * S, 'Regular', TEXT2, 'mm')
    yy += 22 * S
    c.text(cx, yy, '即可获得完整的 Flash 播放体验。', 14 * S, 'Regular', TEXT2, 'mm')

    card_w = 720 * S
    card_x = cx - card_w / 2
    yy += 30 * S
    c.text(card_x, yy, '三步开始播放', 15 * S, 'Medium', TEXT)
    card_y = yy + 18 * S
    row_h = 62 * S
    c.rrect(card_x, card_y, card_w, row_h * 3, 15 * S, fill=SURFACE)
    steps = [('1', '打开 SWF', '选择本地 SWF 文件，立即开始播放'),
             ('2', '播放库', '自动收录 下载/RFulash/players 里的文件'),
             ('3', '沉浸播放', '全屏、画面缩放与键鼠操作一应俱全')]
    for i, (num, name, desc) in enumerate(steps):
        cy = card_y + row_h * i + row_h / 2
        c.ellipse(card_x + 16 * S, cy - 14 * S, 28 * S, 28 * S, fill=ACCENT_SOFT)
        c.text(card_x + 30 * S, cy + 1, num, 13 * S, 'Medium', ACCENT, 'mm')
        c.text(card_x + 56 * S, cy - 11 * S, name, 15 * S, 'Medium', TEXT)
        c.text(card_x + 56 * S, cy + 11 * S, desc, 13 * S, 'Regular', TEXT2)
        if i < 2:
            c.line([(card_x + 56 * S, card_y + row_h * (i + 1)),
                    (card_x + card_w - 16 * S, card_y + row_h * (i + 1))], DIV_SURFACE, 1)

    by = card_y + row_h * 3 + 26 * S
    c.rrect(card_x, by, card_w, 48 * S, 10 * S, fill=ACCENT)
    glyph(c, 'folder', cx - 52 * S, by + 24 * S, 18 * S, ON_ACCENT, max(2.0, 2.0 * S))
    c.text(cx + 4 * S, by + 25 * S, '打开 SWF', 16 * S, 'Medium', ON_ACCENT, 'mm')

    py = by + 48 * S + 18 * S
    glyph(c, 'shield', cx - 92 * S, py, 13 * S, TEXT2, max(1.5, 1.5 * S))
    c.text(cx - 76 * S, py + 1, '所有文件均在本机解析，不上传网络', 12 * S, 'Regular', TEXT2)


def tab_bar(c, S, h):
    bw = 260 * S
    bh = 56 * S
    x = (c.W - bw) / 2
    y = h - bh - 16 * S
    c.rrect_alpha(x, y, bw, bh, 28 * S, fill=(24, 27, 32, 150),
                  outline=(255, 255, 255, 46), ow=1)
    half = bw / 2
    glyph(c, 'home', x + half / 2, y + bh * .38, 19 * S, ACCENT, max(2.0, 2.2 * S))
    c.text(x + half / 2, y + bh * .74, '首页', 11 * S, 'Medium', ACCENT, 'mm')
    glyph(c, 'play', x + half + half / 2, y + bh * .38, 19 * S, TEXT2, max(2.0, 2.2 * S))
    c.text(x + half + half / 2, y + bh * .74, '播放', 11 * S, 'Regular', TEXT2, 'mm')

# ── movie frame (fictional pixel-art SWF) ───────────────────────────────

def make_movie(w=480, h=270):
    im = Image.new('RGB', (w, h), (116, 200, 255))
    d = ImageDraw.Draw(im)
    for y in range(h):
        t = y / max(1, h - 1)
        d.line([(0, y), (w, y)], fill=(int(96 + 132 * t), int(196 + 52 * t), int(255 - 30 * t)))
    for cx, cy, s in ((160, 44, 1.0), (256, 28, .72), (330, 72, .55)):
        d.ellipse([cx - 26 * s, cy - 8 * s, cx + 26 * s, cy + 12 * s], fill=(250, 252, 255))
        d.ellipse([cx - 8 * s, cy - 16 * s, cx + 12 * s, cy + 8 * s], fill=(250, 252, 255))
    d.polygon([(0, 196), (96, 118), (196, 196)], fill=(62, 152, 118))
    d.polygon([(126, 196), (256, 104), (392, 196)], fill=(50, 136, 104))
    d.rectangle([0, 176, w, h], fill=(94, 192, 94))
    d.rectangle([0, 176, w, 184], fill=(120, 210, 114))
    for yy in range(188, h, 22):
        for xx in range(0, w, 22):
            if (xx // 22 + yy // 22) % 2 == 0:
                d.rectangle([xx, yy, xx + 22, yy + 22], fill=(86, 182, 86))
    for fx in range(16, w, 64):
        d.rectangle([fx, 148, fx + 6, 196], fill=(160, 112, 68))
        d.rectangle([fx - 3, 154, fx + 9, 160], fill=(190, 140, 90))
        d.rectangle([fx - 3, 172, fx + 9, 178], fill=(190, 140, 90))
    # sheep
    for bx in (96, 400):
        d.rectangle([bx - 2, 176, bx + 4, 194], fill=(70, 66, 62))
        d.rectangle([bx + 26, 176, bx + 32, 194], fill=(70, 66, 62))
        d.ellipse([bx, 150, bx + 46, 190], fill=(250, 250, 245))
        d.ellipse([bx + 34, 150, bx + 56, 174], fill=(60, 58, 56))
        d.ellipse([bx + 40, 156, bx + 44, 160], fill=(255, 255, 255))
    # player rabbit
    px, py = 236, 158
    d.ellipse([px, py, px + 34, py + 36], fill=(240, 130, 52))
    d.ellipse([px + 18, py - 18, px + 44, py + 10], fill=(244, 144, 64))
    d.ellipse([px + 22, py - 34, px + 30, py - 8], fill=(244, 144, 64))
    d.ellipse([px + 34, py - 32, px + 42, py - 8], fill=(244, 144, 64))
    d.ellipse([px + 35, py - 8, px + 39, py - 4], fill=(40, 30, 22))
    d.rectangle([px + 4, py + 34, px + 10, py + 46], fill=(60, 50, 40))
    d.rectangle([px + 24, py + 34, px + 30, py + 46], fill=(60, 50, 40))
    # coins
    for cx, cy in ((320, 104), (356, 88), (392, 104)):
        d.ellipse([cx - 11, cy - 11, cx + 11, cy + 11], fill=(255, 214, 64))
        d.ellipse([cx - 7, cy - 7, cx + 7, cy + 7], fill=(255, 240, 150))
        d.rectangle([cx - 2, cy - 6, cx + 2, cy + 6], fill=(214, 150, 30))
    # hud
    f = ImageFont.truetype(FONT_PATH, 17)
    d.text((14, 12), 'SCORE 1200', font=f, fill=(255, 255, 255))
    d.text((w - 64, 12), 'x 3', font=f, fill=(255, 255, 255))
    for i in range(3):
        hx = w - 52 + i * 16
        d.ellipse([hx, 54, hx + 7, 61], fill=(255, 92, 92))
        d.ellipse([hx + 6, 54, hx + 13, 61], fill=(255, 92, 92))
        d.polygon([(hx, 58), (hx + 13, 58), (hx + 6, 68)], fill=(255, 92, 92))
    return im


def draw_movie(c, x, y, w, h):
    movie = make_movie()
    scaled = movie.resize((c.p(w), c.p(h)), Image.NEAREST)
    c.img.paste(scaled, (c.p(x), c.p(y)))
    c.d = ImageDraw.Draw(c.img)


# ── promo reel (ray_of_light frame cropped from the original promo) ────

REEL_PATH = os.path.join(ROOT, 'tools/assets/ray_of_light.png')


def draw_reel(c, x, y, w, h):
    """Contain-fit the original demo frame in the stage, black bars around."""
    reel = Image.open(REEL_PATH).convert('RGB')
    scale = min(w / reel.width, h / reel.height)
    rw = int(round(reel.width * scale))
    rh = int(round(reel.height * scale))
    big = reel.resize((c.p(rw), c.p(rh)), Image.LANCZOS)
    c.img.paste(big, (c.p(x + (w - rw) / 2), c.p(y + (h - rh) / 2)))
    c.d = ImageDraw.Draw(c.img)


# ── sheets ──────────────────────────────────────────────────────────────

def sheet_frame(c, x, y, w, h, S, title):
    c.shadow(x + 6, y + 22, w - 12, h - 22, 24 * S, 28 * S, 8, 190)
    c.rrect(x, y, w, h, 20 * S, fill=SURFACE, outline=(58, 63, 72), ow=1)
    c.text(x + w / 2, y + 40 * S, title, 20 * S, 'Medium', TEXT, 'mm')
    glyph(c, 'close', x + w - 34 * S, y + 40 * S, 17 * S, TEXT2)


def action_row(c, x, y, w, labels, S):
    gap = 18 * S
    sizes = [c.tw(t, 14 * S, 'Medium') for t in labels]
    total = sum(sizes) + gap * (len(labels) - 1)
    xx = x + w - total
    for t, tw in zip(labels, sizes):
        c.text(xx, y, t, 14 * S, 'Medium', ACCENT)
        xx += tw + gap


def group_header(c, x, y, w, S, name, count, collapsed=False):
    h = 44 * S
    c.rrect(x, y, w, h, 10 * S, fill=FILL)
    glyph(c, 'folder', x + 22 * S, y + h / 2, 17 * S, TEXT2, max(1.8, 1.8 * S))
    c.text(x + 40 * S, y + h / 2 + 1, name, 14 * S, 'Medium', TEXT)
    c.text(x + w - 24 * S, y + h / 2 + 1, f'{count} 个', 12 * S, 'Regular', TEXT3, 'rm')
    glyph(c, 'chevron_down' if not collapsed else 'chevron_right',
          x + w - 10 * S, y + h / 2, 10 * S, TEXT3, max(1.6, 1.6 * S))
    return h


def file_row(c, x, y, w, S, name):
    h = 44 * S
    c.rrect(x, y, w, h, 10 * S, fill=FILL)
    c.text(x + 12 * S, y + h / 2 + 1, name, 14 * S, 'Regular', TEXT)
    return h


def library_sheet(c, S):
    w = 480 * S
    h = 560 * S
    x = (c.W - w) / 2
    y = (c.H - h) / 2
    sheet_frame(c, x, y, w, h, S, '播放库')
    ix = x + 16 * S
    iw = w - 32 * S
    action_row(c, ix, y + 78 * S, iw, ['导入', '新建分组', '搜索', '刷新', '清空'], S)

    yy = y + 112 * S
    gap = 8 * S
    yy += group_header(c, ix, yy, iw, S, '默认', len(FILES_B)) + gap
    for name in FILES_B:
        yy += file_row(c, ix, yy, iw, S, name) + gap
    yy += 4 * S
    yy += group_header(c, ix, yy, iw, S, '动画短片', len(FILES_A)) + gap
    for name in FILES_A:
        yy += file_row(c, ix, yy, iw, S, name) + gap


def setting_card(c, x, y, w, S, rows):
    h = 48 * S
    c.rrect(x, y, w, h * len(rows), 15 * S, fill=FILL)
    for i, (label, value) in enumerate(rows):
        cy = y + h * i + h / 2
        c.text(x + 16 * S, cy + 1, label, 14 * S, 'Regular', TEXT)
        if value:
            c.text(x + w - 34 * S, cy + 1, value, 13 * S, 'Regular', TEXT3, 'rm')
        glyph(c, 'chevron_right', x + w - 20 * S, cy, 10 * S, TEXT3, max(1.6, 1.6 * S))
        if i < len(rows) - 1:
            c.line([(x + 16 * S, y + h * (i + 1)), (x + w - 16 * S, y + h * (i + 1))],
                   DIV_FILL, 1)
    return h * len(rows)


def settings_sheet(c, S):
    w = 480 * S
    h = 560 * S
    x = (c.W - w) / 2
    y = (c.H - h) / 2
    sheet_frame(c, x, y, w, h, S, '播放器设置')
    ix = x + 16 * S
    iw = w - 32 * S
    yy = y + 76 * S
    c.text(ix + 4 * S, yy, '基本与核心', 12 * S, 'Regular', TEXT3)
    yy += 14 * S
    yy += setting_card(c, ix, yy, iw, S,
                       [('播放设置', ''), ('声音设置', '100%'),
                        ('画面设置', '高'), ('显示设置', '适应窗口')]) + 20 * S
    c.text(ix + 4 * S, yy, '外观风格', 12 * S, 'Regular', TEXT3)
    yy += 14 * S
    yy += setting_card(c, ix, yy, iw, S,
                       [('外观设置', '深色'), ('沉浸光感', '标准'),
                        ('主题设置', '橙色')]) + 20 * S
    c.text(ix + 4 * S, yy, '关于', 12 * S, 'Regular', TEXT3)
    yy += 14 * S
    setting_card(c, ix, yy, iw, S, [('关于 RFulash', '')])


def about_sheet(c, S):
    w = 480 * S
    h = 560 * S
    x = (c.W - w) / 2
    y = (c.H - h) / 2
    sheet_frame(c, x, y, w, h, S, '关于')
    ix = x + 16 * S
    iw = w - 32 * S
    gap = 8 * S
    cw = (iw - gap) / 2
    yy = y + 76 * S

    c.rrect(ix, yy, iw, 96 * S, 15 * S, fill=FILL)
    c.app_icon(ix + 16 * S, yy + 24 * S, 48 * S, 14 * S)
    c.text(ix + 78 * S, yy + 37 * S, 'RFulash', 17 * S, 'Medium', TEXT)
    c.text(ix + 78 * S, yy + 60 * S, '鸿蒙原生 Flash 播放器', 12 * S, 'Regular', TEXT2)
    yy += 96 * S + 12 * S

    def info_card(cx, label, value, accent=False, chevron=False):
        c.rrect(cx, yy, cw, 60 * S, 15 * S, fill=FILL)
        if chevron:
            c.text(cx + 16 * S, yy + 30 * S, label, 15 * S, 'Medium', TEXT)
            glyph(c, 'chevron_right', cx + cw - 20 * S, yy + 30 * S, 10 * S,
                  TEXT3, max(1.6, 1.6 * S))
            return
        c.text(cx + 16 * S, yy + 20 * S, label, 12 * S, 'Regular', TEXT2)
        c.text(cx + 16 * S, yy + 42 * S, value, 15 * S, 'Medium',
               ACCENT if accent else TEXT)

    info_card(ix, '版本', '3.0')
    info_card(ix + cw + gap, '开发者', '李晨')
    yy += 60 * S + 12 * S
    info_card(ix, '包名', 'com.52wfun.rfulash')
    info_card(ix + cw + gap, '官网', 'www.52wfun.com', accent=True)
    yy += 60 * S + 12 * S
    info_card(ix, '联系邮箱', '3093376617@qq.com', accent=True)
    info_card(ix + cw + gap, '开源许可', '', chevron=True)


# ── promo screens (exact size of the window/tablet mocks) ──────────────

PC_SCREEN_W, PC_SCREEN_H = 1091, 692
TAB_SCREEN_W, TAB_SCREEN_H = 1153, 768


def promo_pc_screen(kind):
    c = C(PC_SCREEN_W, PC_SCREEN_H)
    c.rect(0, 0, PC_SCREEN_W, PC_SCREEN_H, BG)
    S = 1.0
    sw = 280 * S
    bar = 48 * S
    if kind == 'home':
        sidebar(c, 0, S, PC_SCREEN_H)
        title_bar(c, sw, 0, PC_SCREEN_W - sw, '首页', '',
                  ['folder', 'film', 'clock', 'gear'], S, bar)
        home_content(c, sw + (PC_SCREEN_W - sw) / 2, bar + 28 * S, S)
    elif kind == 'player':
        sidebar(c, 1, S, PC_SCREEN_H)
        title_bar(c, sw, 0, PC_SCREEN_W - sw, 'ray_of_light.swf', '',
                  ['folder', 'film', 'clock', 'pause', 'gear', 'fullscreen'], S, bar)
        c.rect(sw, bar, PC_SCREEN_W - sw, PC_SCREEN_H - bar, (0, 0, 0))
        draw_reel(c, sw, bar, PC_SCREEN_W - sw, PC_SCREEN_H - bar)
        c.text(sw + 14 * S, bar + 18 * S, '60 fps', 12 * S, 'Regular', (0, 255, 0))
    elif kind == 'about':
        sidebar(c, 0, S, PC_SCREEN_H)
        title_bar(c, sw, 0, PC_SCREEN_W - sw, '首页', '',
                  ['folder', 'film', 'clock', 'gear'], S, bar)
        home_content(c, sw + (PC_SCREEN_W - sw) / 2, bar + 28 * S, S)
        c.scrim(95)
        about_sheet(c, S)
    else:
        raise ValueError(kind)
    return c.render()


def promo_tablet_screen(kind):
    c = C(TAB_SCREEN_W, TAB_SCREEN_H)
    c.rect(0, 0, TAB_SCREEN_W, TAB_SCREEN_H, BG)
    S = 1.5 * TAB_SCREEN_W / 1920
    k = TAB_SCREEN_W / 1920
    sb = 48 * k
    bar = 56 * S
    status_bar(c, k)
    if kind == 'home':
        title_bar(c, 0, sb, TAB_SCREEN_W, '首页', '',
                  ['folder', 'film', 'clock', 'gear'], S, bar)
        home_content(c, TAB_SCREEN_W / 2, sb + bar + 30 * S, S)
        tab_bar(c, S, TAB_SCREEN_H)
    elif kind == 'player':
        title_bar(c, 0, sb, TAB_SCREEN_W, 'ray_of_light.swf', '',
                  ['folder', 'film', 'clock', 'pause', 'gear', 'fullscreen'], S, bar)
        top = sb + bar
        c.rect(0, top, TAB_SCREEN_W, TAB_SCREEN_H - top, (0, 0, 0))
        draw_reel(c, 0, top, TAB_SCREEN_W, TAB_SCREEN_H - top)
        tab_bar(c, S, TAB_SCREEN_H)
    elif kind == 'about':
        title_bar(c, 0, sb, TAB_SCREEN_W, '首页', '',
                  ['folder', 'film', 'clock', 'gear'], S, bar)
        home_content(c, TAB_SCREEN_W / 2, sb + bar + 30 * S, S)
        tab_bar(c, S, TAB_SCREEN_H)
        c.scrim(95)
        about_sheet(c, S)
    else:
        raise ValueError(kind)
    return c.render()


# ── pages ───────────────────────────────────────────────────────────────

def pc_home():
    c = C(1920, 1080)
    c.rect(0, 0, 1920, 1080, BG)
    S = 1.23
    sidebar(c, 0, S, 1080)
    sw = 280 * S
    bar = 48 * S
    title_bar(c, sw, 0, 1920 - sw, '首页', '', ['folder', 'film', 'clock', 'gear'], S, bar)
    home_content(c, sw + (1920 - sw) / 2, bar + 28 * S, S)
    return c.save(os.path.join(OUT, 'pc_01_home.png'))


def pc_player():
    c = C(1920, 1080)
    c.rect(0, 0, 1920, 1080, BG)
    S = 1.23
    sidebar(c, 1, S, 1080)
    sw = 280 * S
    bar = 48 * S
    title_bar(c, sw, 0, 1920 - sw, '小羊快跑.swf', '',
              ['folder', 'film', 'clock', 'pause', 'gear', 'fullscreen'], S, bar)
    c.rect(sw, bar, 1920 - sw, 1080 - bar, (0, 0, 0))
    stage_w = 1920 - sw
    stage_h = 1080 - bar
    mw = stage_w
    mh = mw * 9 / 16
    my = bar + (stage_h - mh) / 2
    draw_movie(c, sw, my, mw, mh)
    c.text(sw + 14 * S, bar + 18 * S, '24 fps', 12 * S, 'Regular', (0, 255, 0))
    return c.save(os.path.join(OUT, 'pc_02_player.png'))


def pc_library():
    c = C(1920, 1080)
    c.rect(0, 0, 1920, 1080, BG)
    S = 1.23
    sidebar(c, 0, S, 1080)
    sw = 280 * S
    bar = 48 * S
    title_bar(c, sw, 0, 1920 - sw, '首页', '', ['folder', 'film', 'clock', 'gear'], S, bar)
    home_content(c, sw + (1920 - sw) / 2, bar + 28 * S, S)
    c.scrim(95)
    library_sheet(c, S)
    return c.save(os.path.join(OUT, 'pc_03_library.png'))


def tablet_home():
    c = C(1920, 1280)
    c.rect(0, 0, 1920, 1280, BG)
    S = 1.5
    sb = 48
    bar = 56 * S
    status_bar(c)
    title_bar(c, 0, sb, 1920, '首页', '', ['folder', 'film', 'clock', 'gear'], S, bar)
    home_content(c, 960, sb + bar + 30 * S, S)
    tab_bar(c, S, 1280)
    return c.save(os.path.join(OUT, 'tablet_01_home.png'))


def tablet_player():
    c = C(1920, 1280)
    c.rect(0, 0, 1920, 1280, BG)
    S = 1.5
    sb = 48
    bar = 56 * S
    status_bar(c)
    title_bar(c, 0, sb, 1920, '星际漫游.swf', '',
              ['folder', 'film', 'clock', 'pause', 'gear', 'fullscreen'], S, bar)
    top = sb + bar
    c.rect(0, top, 1920, 1280 - top, (0, 0, 0))
    mw = 1920
    mh = mw * 9 / 16
    my = top + (1280 - top - mh) / 2
    draw_movie(c, 0, my, mw, mh)
    tab_bar(c, S, 1280)
    return c.save(os.path.join(OUT, 'tablet_02_player.png'))


def tablet_library():
    c = C(1920, 1280)
    c.rect(0, 0, 1920, 1280, BG)
    S = 1.5
    sb = 48
    bar = 56 * S
    status_bar(c)
    title_bar(c, 0, sb, 1920, '首页', '', ['folder', 'film', 'clock', 'gear'], S, bar)
    home_content(c, 960, sb + bar + 30 * S, S)
    tab_bar(c, S, 1280)
    c.scrim(95)
    library_sheet(c, S)
    return c.save(os.path.join(OUT, 'tablet_03_library.png'))


def tablet_settings():
    c = C(1920, 1280)
    c.rect(0, 0, 1920, 1280, BG)
    S = 1.5
    sb = 48
    bar = 56 * S
    status_bar(c)
    title_bar(c, 0, sb, 1920, '首页', '', ['folder', 'film', 'clock', 'gear'], S, bar)
    home_content(c, 960, sb + bar + 30 * S, S)
    tab_bar(c, S, 1280)
    c.scrim(95)
    settings_sheet(c, S)
    return c.save(os.path.join(OUT, 'tablet_04_settings.png'))


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for fn in (pc_home, pc_player, pc_library, tablet_home,
               tablet_player, tablet_library, tablet_settings):
        print('%-18s %7.1f KB' % (fn.__name__, fn() / 1024))
