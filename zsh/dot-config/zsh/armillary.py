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

ART_COLS, ART_ROWS = 16, 8
LOOP = 12000
ART_ID = 0x5A1E57
FRAME_MS = 100
STARS = [(14, 22, 0, 4), (176, 30, 2, 3), (26, 176, 5, 4), (180, 160, 1, 3), (98, 10, 7, 6), (8, 104, 3, 4), (186, 96, 9, 3), (150, 196, 4, 6)]
RINGS = [
    (72, 1.25, 0.35, LOOP, 0, 8, LOOP / 2, "secondary"),
    (62, 0.42, -0.95, -LOOP, LOOP, 6, -LOOP / 3, "tertiary"),
    (52, math.pi / 2, 0, LOOP / 2, 0, 4, LOOP / 4, "on_surface"),
]
PLANET_LIGHT = 0.75
_L = (-0.45, -0.7, 0.55)
LIGHT = tuple(c / math.hypot(*_L) for c in _L)
_H = (LIGHT[0], LIGHT[1], LIGHT[2] + 1)
HALF = tuple(c / math.hypot(*_H) for c in _H)


def rnd(v):
    return math.floor(v + 0.5)


def ring_point(ring, t, th, rr):
    _, tilt, roll, prec, spin = ring[:5]
    pa, sa = 2 * math.pi * t / prec, (2 * math.pi * t / spin if spin else 0)
    x, y, z = rr * math.cos(th + sa), 0.0, rr * math.sin(th + sa)
    y, z = y * math.cos(tilt) - z * math.sin(tilt), y * math.sin(tilt) + z * math.cos(tilt)
    x, y = x * math.cos(roll) - y * math.sin(roll), x * math.sin(roll) + y * math.cos(roll)
    x, z = x * math.cos(pa) + z * math.sin(pa), -x * math.sin(pa) + z * math.cos(pa)
    return x, y, z


def render(t, w, h, k, pal):
    bob = rnd(1.5 * k * math.sin(2 * math.pi * t / (LOOP / 3)))
    cx, cy, R = w / 2, h / 2 + bob, 26 * k
    orb, ring_ramp, ink = pal["orb"], pal["ring"], pal["ink"]
    col, zb = [None] * (w * h), [-1e9] * (w * h)
    planets = []
    for i, ring in enumerate(RINGS):
        x, y, z = ring_point(ring, t, 2 * math.pi * (t / ring[6] + i * 0.3), (ring[0] - 0.6) * k)
        planets.append((x, y, z, pal[ring[7]], pal[ring[7] + "_rgb"]))
    pulse = 0.08 * math.sin(2 * math.pi * t / (LOOP / 5))
    for y in range(max(0, int(cy - R)), min(h, int(cy + R) + 1)):
        for x in range(max(0, int(cx - R)), min(w, int(cx + R) + 1)):
            dx, dy = (x + 0.5 - cx) / R, (y + 0.5 - cy) / R
            d2 = dx * dx + dy * dy
            if d2 > 1:
                continue
            nz = math.sqrt(1 - d2)
            r = math.sqrt(d2)
            tone = 5 if r < 0.32 + pulse else 4 if r < 0.55 + pulse else 3 if r < 0.78 else 2 if r < 0.92 else 1
            best, best_ramp = 0.0, None
            for px, py, pz, pramp, _ in planets:
                lx, ly, lz = px - dx * R, py - dy * R, pz - nz * R
                dist = math.sqrt(lx * lx + ly * ly + lz * lz)
                c = max(0.0, (dx * lx + dy * ly + nz * lz) / dist) * PLANET_LIGHT / (1 + (dist / (34 * k)) ** 2)
                if c > best:
                    best, best_ramp = c, pramp
            c = orb[tone]
            if best > 0.18:
                c = pc.mix(c, best_ramp[min(5, tone + 1)], 0.55 if best > 0.45 else 0.3)
            col[y * w + x], zb[y * w + x] = c, nz * R
    for y in range(max(0, int(cy - R - 5)), min(h, int(cy + R) + 6)):
        for x in range(max(0, int(cx - R - 5)), min(w, int(cx + R) + 6)):
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if R + 1 < d < R + 4 and (x + y) % 2 == 0 and not col[y * w + x]:
                col[y * w + x], zb[y * w + x] = orb[2], -999

    def plot(x, y, z, c):
        x, y = rnd(x), rnd(y)
        if not (0 <= x < w and 0 <= y < h):
            return
        i = y * w + x
        if z < 0 and zb[i] > -900 and math.hypot(x + 0.5 - cx, y + 0.5 - cy) < R:
            return
        if z >= zb[i]:
            col[i], zb[i] = c, z

    for ring in RINGS:
        r = ring[0] * k
        n = math.ceil(r * 9)
        for j in range(n):
            th = 2 * math.pi * j / n
            for rr in (r, r - 1.2):
                x, y, z = ring_point(ring, t, th, rr)
                lam = (x * LIGHT[0] + y * LIGHT[1] + z * LIGHT[2]) / rr
                tone = 5 if lam > 0.88 else max(1, min(4, rnd(1 + 3 * (0.6 * (z / rr + 1) / 2 + 0.4 * (lam + 1) / 2))))
                for px, py, pz, _, _ in planets:
                    if math.hypot(px - x, py - y, pz - z) < 14 * k:
                        tone = min(5, tone + 1)
                plot(cx + x, cy + y, z, ring_ramp[tone])
        for b in range(ring[5]):
            x, y, z = ring_point(ring, t, 2 * math.pi * b / ring[5], r - 0.6)
            for j in range(2):
                for i in range(2):
                    plot(cx + x - 1 + i + 0.5, cy + y - 1 + j + 0.5, z + 0.5, ring_ramp[5 if z > 0 else 2])
    for px, py, pz, pramp, _ in planets:
        for j in range(-2, 3):
            for i in range(-2, 3):
                d = i * i + j * j
                if d <= 5:
                    plot(cx + px + i, cy + py + j, pz + 3, pal["peak"] if d == 0 else pramp[5] if d <= 2 else pramp[3])
    out = col[:]
    for y in range(h):
        for x in range(w):
            if col[y * w + x]:
                continue
            n = (
                (y > 0 and col[(y - 1) * w + x])
                or (x > 0 and col[y * w + x - 1])
                or (x < w - 1 and col[y * w + x + 1])
                or (y < h - 1 and col[(y + 1) * w + x])
            )
            if n:
                out[y * w + x] = pc.mix(n, ink, 0.78)
    for px, py, pz, pramp, _ in planets:
        gx, gy = rnd(cx + px), rnd(cy + py)
        if pz < 0 and math.hypot(gx + 0.5 - cx, gy + 0.5 - cy) < R:
            continue
        for j in range(-5, 6):
            for i in range(-5, 6):
                x, y = gx + i, gy + j
                if 3.2 < math.hypot(i, j) < 5.2 and (x + y) % 2 == 0 and 0 <= x < w and 0 <= y < h and not out[y * w + x]:
                    out[y * w + x] = pramp[2]
    for sx, sy, ph, per in STARS:
        v = math.sin(2 * math.pi * (t / (LOOP / per) + ph / 10))
        x, y = rnd(cx + (sx - 96) * k), rnd(cy - bob + (sy - 104) * k) + bob
        if not (1 <= x < w - 1 and 1 <= y < h - 1):
            continue
        if v > 0.86:
            out[y * w + x] = pal["peak"]
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                out[(y + dy) * w + x + dx] = pal["tertiary_rgb"]
        elif v > 0.2:
            out[y * w + x] = pal["tertiary_rgb"]
        elif v > -0.4:
            out[y * w + x] = pal["dim"]
    data = bytearray(w * h * 4)
    for i, c in enumerate(out):
        if c:
            data[i * 4 : i * 4 + 4] = bytes((*c, 255))
    return bytes(data)


def self_check():
    pal = palette({})
    a, b, c = (render(t, 192, 208, 1.0, pal) for t in (0, LOOP, FRAME_MS))
    differ = lambda x, y: sum(x[i : i + 4] != y[i : i + 4] for i in range(0, len(x), 4))
    assert differ(a, b) * 20 < differ(a, c), "the loop isn't seamless"
    assert any(a[i + 3] for i in range(0, len(a), 4)), "empty frame"
    print("ok")


def palette(colors):
    def c(key, fallback):
        return pc.hex_rgb(colors.get(key, fallback))

    pal = {
        "orb": pc.ramp(c("primary", "#ffb68a"), -8, 8),
        "ring": pc.ramp(c("tertiary", "#cbc992"), -10, 8),
        "peak": c("on_surface", "#f0dfd7"),
        "dim": c("outline_variant", "#52443c"),
    }
    pal["ink"] = pc.mix(pal["orb"][0], (0, 0, 0), 0.6)
    for key, fallback in (("secondary", "#e5bfa9"), ("tertiary", "#cbc992"), ("on_surface", "#f0dfd7")):
        pal[key + "_rgb"] = c(key, fallback)
        pal[key] = pc.ramp(pal[key + "_rgb"], -8, 8)
    return pal


def main():
    if sys.argv[1:] == ["--check"]:
        return self_check()
    cw, ch, colors_json, out_dir = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3], Path(sys.argv[4])
    try:
        colors = json.loads(Path(colors_json).read_text())
    except (OSError, ValueError):
        colors = {}
    out_dir.mkdir(parents=True, exist_ok=True)

    def write(file, text):
        tmp = out_dir / f".{file}.{os.getpid()}.tmp"
        tmp.write_text(text)
        tmp.replace(out_dir / file)

    pal = palette(colors)
    w, h = ART_COLS * cw, ART_ROWS * ch
    # fork: the default (forkserver) would re-import this script
    with multiprocessing.get_context("fork").Pool() as pool:
        imgs = pool.starmap(render, [(t, w, h, cw / 12, pal) for t in range(0, LOOP, FRAME_MS)])
    frames = [(img, FRAME_MS) for img in imgs]
    write("armillary.kgp", pc.animation(frames, w, h, ART_COLS, ART_ROWS).replace("@ID@", str(ART_ID)))
    write("title.vars", f"art_id {ART_ID}\n")  # written last


if __name__ == "__main__":
    main()
