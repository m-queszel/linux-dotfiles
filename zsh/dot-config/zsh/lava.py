#!/usr/bin/env python3
import importlib
import json
import math
import multiprocessing
import os
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
pc = importlib.import_module("pixel-cursor")

CELLS = 10
FRAMES = 240
GAP_MS = 33
LAMP_ID = 0x1A7A1A  # must match the @lamp colour in tmux.conf
DESIGN_W, DESIGN_H = 120, 26
# x amp, x cycles/loop, x phase, y amp, y cycles/loop, y phase, radius (120x26 design px)
BLOBS = [
    (38, 1, 0.0, 5, 1, 0.2, 8),
    (30, -1, 0.4, 5, 2, 0.7, 7),
    (22, 2, 0.15, 4, -1, 0.1, 6.5),
    (34, -2, 0.75, 5, 1, 0.45, 6),
    (16, 1, 0.55, 3, 3, 0.9, 5),
]
BAYER = (0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5)


def dith(x, y, t):
    return t * 16 > BAYER[(y & 3) * 4 + (x & 3)]


def render(f, w, h, pal):
    t, sx, sy = f / FRAMES, DESIGN_W / w, DESIGN_H / h
    blobs = [
        (DESIGN_W / 2 + a * math.sin(2 * math.pi * (k * t + ph)), DESIGN_H / 2 + b * math.sin(2 * math.pi * (m * t + ps)), r * r)
        for a, k, ph, b, m, ps, r in BLOBS
    ]
    core, body, edge = pal
    out = bytearray(w * h * 4)
    for y in range(h):
        dy0 = (y + 0.5) * sy
        for x in range(w):
            dx0 = (x + 0.5) * sx
            v = 0.0
            for bx, by, r2 in blobs:
                dx, dy = dx0 - bx, (dy0 - by) * 1.25
                v += r2 / (dx * dx + dy * dy + 0.01)
            if v > 2.6:
                c = core
            elif v > 1.25:
                c = core if dith(x, y, (v - 1.25) / 1.35 * 0.6) else body
            elif v > 1:
                c = body
            elif v > 0.78 and dith(x, y, (v - 0.78) / 0.22):
                c = edge
            else:
                continue
            i = (y * w + x) * 4
            out[i : i + 4] = bytes((*c, 255))
    return bytes(out)


def palette(colors):
    def c(key, fallback):
        return pc.hex_rgb(colors.get(key, fallback))

    primary = c("primary", "#ffb4a5")
    return pc.mix(primary, (255, 255, 255), 0.35), primary, pc.mix(primary, c("tertiary", "#dcc48c"), 0.6)


def self_check():
    pal = palette({})
    a, b = render(0, DESIGN_W, DESIGN_H, pal), render(FRAMES, DESIGN_W, DESIGN_H, pal)
    assert a == b, "the loop isn't seamless"
    assert any(a[3::4]), "empty frame"
    assert render(0, 240, 52, pal).count(255) > a.count(255), "doesn't scale with the cell size"
    print("ok")


def main():
    if sys.argv[1:] == ["--check"]:
        return self_check()
    cw, ch, colors_json, out_dir = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3], Path(sys.argv[4])
    try:
        colors = json.loads(Path(colors_json).read_text())
    except (OSError, ValueError):
        colors = {}
    out_dir.mkdir(parents=True, exist_ok=True)
    w, h, pal = CELLS * cw, ch, palette(colors)
    # fork: the default (forkserver) would re-import this script
    with multiprocessing.get_context("fork").Pool() as pool:
        imgs = pool.starmap(render, [(f, w, h, pal) for f in range(FRAMES)])
    tmp = out_dir / f".lava.kgp.{os.getpid()}.tmp"
    tmp.write_text(pc.animation([(img, GAP_MS) for img in imgs], w, h, CELLS).replace("@ID@", str(LAMP_ID)))
    tmp.replace(out_dir / "lava.kgp")


if __name__ == "__main__":
    main()
