#!/usr/bin/env python3
"""Renders the AlergenScan app icon.

Kept as a script rather than a checked-in binary so the icon can be tweaked and
regenerated: `python3 Tools/make_icon.py`. Writes the 1024pt icon straight into
the asset catalog.
"""
from PIL import Image, ImageDraw
import pathlib

S = 4                      # supersample factor; downsampled at the end
SIZE = 1024
W = SIZE * S

TOP        = (17, 66, 71)      # deep teal
BOTTOM     = (7, 33, 37)
SHELL      = (243, 227, 195)   # warm cream
SHELL_EDGE = (206, 179, 132)
BRACKET    = (255, 176, 32)    # amber

def px(v: float) -> float:
    return v * S

img = Image.new("RGB", (W, W), TOP)
d = ImageDraw.Draw(img)

# Vertical gradient background.
for y in range(W):
    t = y / (W - 1)
    d.line([(0, y), (W, y)],
           fill=tuple(round(a + (b - a) * t) for a, b in zip(TOP, BOTTOM)))

# ── Peanut, drawn flat then rotated ──────────────────────────────────────
peanut = Image.new("RGBA", (W, W), (0, 0, 0, 0))
p = ImageDraw.Draw(peanut)
cx = cy = px(512)
r, off, waist = px(128), px(140), px(70)

for dx in (-off, off):
    p.ellipse([cx + dx - r, cy - r, cx + dx + r, cy + r], fill=SHELL)
p.rectangle([cx - off, cy - waist, cx + off, cy + waist], fill=SHELL)

# Shell seam: three short strokes across the waist, just enough texture to
# read as a peanut rather than a blob without muddying it at small sizes.
for dx in (-px(26), px(26)):
    p.line([(cx + dx, cy - px(44)), (cx + dx, cy + px(44))],
           fill=SHELL_EDGE, width=int(px(6)))

peanut = peanut.rotate(25, resample=Image.BICUBIC, center=(cx, cy))
img.paste(peanut, (0, 0), peanut)

# ── Viewfinder brackets ──────────────────────────────────────────────────
# Drawn as one rounded-rectangle outline with the middle of each side punched
# out, which keeps the corner elbows exactly round.
inset, arm, thick, rad = px(112), px(210), px(46), px(104)
lo, hi = inset, W - inset

frame = Image.new("RGBA", (W, W), (0, 0, 0, 0))
f = ImageDraw.Draw(frame)
f.rounded_rectangle([lo, lo, hi, hi], radius=int(rad),
                    outline=BRACKET, width=int(thick))
f.rectangle([lo + arm, 0, hi - arm, W], fill=(0, 0, 0, 0))
f.rectangle([0, lo + arm, W, hi - arm], fill=(0, 0, 0, 0))
img.paste(frame, (0, 0), frame)

out = pathlib.Path("App/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png")
img.resize((SIZE, SIZE), Image.LANCZOS).save(out)
print("wrote", out)
