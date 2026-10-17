#!/usr/bin/env python3
"""Render the animated pixel prompt cursor as kitty graphics-protocol payloads.

usage: pixel-cursor.py CELL_W CELL_H COLORS_JSON OUT_DIR

A gem pointer (ball, neck, collar ring, 5-faceted head) that always points right and rolls
once around its own axis, bobs three times, then rests. It's a 3D model lit from the top-left,
ray-marched at 3x3 samples per pixel; each pixel keeps the most common (material, tone) so the
result is crisp pixel art with a fixed palette, never blended.

Two stages, because rendering the shape is slow in pure Python but coloring is instant:
  OUT_DIR/geometry.json   material+tone per pixel per pose. Depends only on the cell size;
                          rendered once (tens of seconds) and reused.
  OUT_DIR/ok.kgp, err.kgp colored animations, rebuilt whenever the wallpaper palette changes;
  OUT_DIR/*-still.kgp      the same pointer at rest (one frame), swapped in after it has played.
Colors all come from matugen's palette: primary (arrow), tertiary (collar), error (failed).
The image id in the payloads is the literal "@ID@", substituted per prompt by pixel-prompt.zsh.
"""

import base64
import colorsys
import json
import math
import os
import sys
import zlib
from pathlib import Path

CELLS = 3  # sprite width in terminal cells
FACETS = 5  # odd, so every roll step shows a different face toward the light
STEPS = 8  # roll poses: few on purpose, it reads as hand-made sprite frames
ROLL_MS = 110
BOB_MS = 300
BOB_PX = 2
SS = 3  # supersamples per axis
CHUNK = 4096  # max base64 bytes per escape code

LIGHT = (-0.45, -0.7, -0.55)  # direction toward the light: up-left, toward the viewer (screen y is down)
_ll = math.sqrt(sum(c * c for c in LIGHT))
LX, LY, LZ = (c / _ll for c in LIGHT)


def scene(x, y, z, faceted):
    """Distance and material at a point in model space (arrow along +x).

    faceted=False is the round cone used for the silhouette (same size at every roll angle);
    faceted=True is the gem, used only for shading normals.
    """
    rho = math.hypot(y, z)
    if faceted:
        sector = 2 * math.pi / FACETS
        phi = (math.atan2(z, y) + sector / 2) % sector - sector / 2
        r = rho * math.cos(phi)
    else:
        r = rho
    # capped cone along x (Inigo Quilez): base x=-0.8 radius 3.9, apex x=5.2
    h, cx, r1 = 3.0, 2.2, 3.9
    qx, qy = r, x - cx
    k2x, k2y = -r1, 2 * h
    cax = qx - min(qx, r1 if qy < 0 else 0.0)
    cay = abs(qy) - h
    t = max(0.0, min(1.0, ((0 - qx) * k2x + (h - qy) * k2y) / (k2x * k2x + k2y * k2y)))
    cbx, cby = qx + k2x * t, qy - h + k2y * t
    sign = -1 if (cbx < 0 and cay < 0) else 1
    d, m = sign * math.sqrt(min(cax * cax + cay * cay, cbx * cbx + cby * cby)), "h"
    neck = max(rho - 0.85, abs(x + 1.6) - 0.9)
    if neck < d:
        d = neck
    ring = math.hypot(rho - 1.25, x + 1.0) - 0.5  # collar torus at the gem's base
    if ring < d:
        d, m = ring, "c"
    ball = math.sqrt((x + 4.3) ** 2 + y * y + z * z) - 2.4
    if ball < d:
        d, m = ball, ("s" if abs(z) < 0.7 else "b")  # painted stripe rolls with the ball
    return d, m


def render_pose(step, w, h, px_size):
    """Material+tone code per pixel ("h3", "b5", ...) or "" for empty."""
    ang = 2 * math.pi * step / STEPS
    ca, sa = math.cos(ang), math.sin(ang)

    def at(f, x, y, z):  # world -> model: undo the roll about x
        return scene(x, y * ca + z * sa, -y * sa + z * ca, f)

    rows = []
    for py in range(h):
        row = []
        for px in range(w):
            votes, hits = {}, 0
            for sy in range(SS):
                for sx in range(SS):
                    wx = (px + (sx + 0.5) / SS - w / 2) * px_size - 0.55
                    wy = (py + (sy + 0.5) / SS - h / 2) * px_size
                    wz, hit = -8.0, None
                    for _ in range(56):
                        d, m = at(False, wx, wy, wz)
                        if d < 0.01:
                            hit = m
                            break
                        wz += d * 0.7
                        if wz > 8:
                            break
                    if not hit:
                        continue
                    hits += 1
                    e = 0.02
                    nx = at(True, wx + e, wy, wz)[0] - at(True, wx - e, wy, wz)[0]
                    ny = at(True, wx, wy + e, wz)[0] - at(True, wx, wy - e, wz)[0]
                    nz = at(True, wx, wy, wz + e)[0] - at(True, wx, wy, wz - e)[0]
                    nl = math.sqrt(nx * nx + ny * ny + nz * nz) or 1.0
                    nx, ny, nz = nx / nl, ny / nl, nz / nl
                    diff = nx * LX + ny * LY + nz * LZ
                    # reflect the light about the normal; the viewer looks along +z (from -z)
                    spec = max(0.0, LZ - 2 * diff * nz) ** 28
                    rim = diff < 0.1 and nx * 0.6 + ny * 0.8 > 0.55  # reflected light, lower right
                    if spec > 0.5:
                        tone = 5
                    elif diff > 0.75:
                        tone = 4
                    elif diff > 0.45:
                        tone = 3
                    elif diff > 0.15 or rim:
                        tone = 2
                    elif diff > -0.2:
                        tone = 1
                    else:
                        tone = 0
                    code = f"{hit}{tone}"
                    votes[code] = votes.get(code, 0) + 1
            row.append(max(votes, key=votes.get) if hits * 2 >= SS * SS else "")
        rows.append(row)
    return rows


def geometry(cell_w, cell_h, path):
    if path.exists():
        return json.loads(path.read_text())
    w, h = CELLS * cell_w, cell_h
    px_size = 10.4 / h  # the model is ~26 px tall at the reference 12x26 cell
    data = {"w": w, "h": h, "poses": [render_pose(s, w, h, px_size) for s in range(STEPS)]}
    tmp = path.parent / f".{path.name}.{os.getpid()}.tmp"  # per process: shells may render at once
    tmp.write_text(json.dumps(data, separators=(",", ":")))
    tmp.replace(path)
    return data


def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def ramp(rgb, shadow_hue, light_hue):
    """Six tones, deep shadow to glint. Saturation is scaled down as tones darken: matugen
    accents are pastels (HLS saturation ~1), and darkening those at full saturation turns them
    into vivid red."""
    hh, ll, ss = colorsys.rgb_to_hls(*(c / 255 for c in rgb))

    def at(dh, s_scale, dl):
        r, g, b = colorsys.hls_to_rgb((hh + dh / 360) % 1, max(0, min(1, ll + dl)), max(0, min(1, ss * s_scale)))
        return (round(r * 255), round(g * 255), round(b * 255))

    return [
        at(shadow_hue, 0.32, -0.42),
        at(shadow_hue * 0.6, 0.45, -0.28),
        at(shadow_hue * 0.25, 0.65, -0.12),
        at(0, 1, 0),
        at(light_hue, 1, 0.1),
        at(light_hue * 1.5, 1, 0.2),
    ]


def palette(accent, collar):
    head = ramp(accent, -8, 8)
    return {
        "h": head,
        "b": ramp(mix(accent, (255, 250, 244), 0.78), -8, 6),
        "s": ramp(mix(accent, (40, 30, 30), 0.35), -6, 6),
        "c": ramp(collar, -10, 8),
        "ink": mix(head[0], (0, 0, 0), 0.6),
    }


def frame_rgba(pose, pal, w, h, bob):
    grid = [[pal[c[0]][int(c[1])] if c else None for c in row] for row in pose]

    def filled(x, y):
        return 0 <= x < w and 0 <= y < h and grid[y][x]

    out = bytearray()
    for y in range(h):
        for x in range(w):
            sx = x - bob  # bob shifts the whole sprite right
            c = filled(sx, y)
            if not c:
                # selective outline: the neighbor's color pushed toward the ink
                n = filled(sx, y - 1) or filled(sx - 1, y) or filled(sx + 1, y) or filled(sx, y + 1)
                c = mix(n, pal["ink"], 0.78) if n else None
            out += bytes((*c, 255)) if c else b"\0\0\0\0"
    return bytes(out)


def escape(keys, data=b""):
    """Graphics escape(s) for keys + optional pixel data, zlib-compressed and chunked."""
    if not data:
        return f"\x1b_G{keys}\x1b\\"
    b64 = base64.standard_b64encode(zlib.compress(data, 9)).decode()
    parts = [b64[i : i + CHUNK] for i in range(0, len(b64), CHUNK)]
    seqs = []
    for n, part in enumerate(parts):
        more = 1 if n < len(parts) - 1 else 0
        head = f"{keys},o=z,m={more}" if n == 0 else f"q=2,m={more}"
        seqs.append(f"\x1b_G{head};{part}\x1b\\")
    return "".join(seqs)


def payload(geo, pal):
    w, h, poses = geo["w"], geo["h"], geo["poses"]
    frames = [(poses[k % STEPS], 0, ROLL_MS) for k in range(1, STEPS + 1)]
    frames += [(poses[0], bob, BOB_MS) for bob in (BOB_PX, 0, BOB_PX, 0, BOB_PX, 0)]
    frames.append((poses[0], 0, BOB_MS))  # rests here when the animation ends
    size = f"f=32,s={w},v={h}"
    seqs = []
    for n, (pose, bob, gap) in enumerate(frames):
        data = frame_rgba(pose, pal, w, h, bob)
        if n == 0:
            seqs.append(escape(f"a=t,q=2,i=@ID@,{size}", data))
            seqs.append(escape(f"a=p,q=2,U=1,i=@ID@,c={CELLS},r=1"))
            seqs.append(escape(f"a=a,q=2,i=@ID@,r=1,z={gap}"))
        else:
            seqs.append(escape(f"a=f,q=2,i=@ID@,{size},z={gap}", data))
    seqs.append(escape("a=a,q=2,i=@ID@,s=3,v=2"))  # v=2: play the frames once, then stop
    return "".join(seqs)


def still(geo, pal):
    """The resting pointer as a one-frame image. Sent over a finished prompt's id, it replaces
    that prompt's 16-frame animation, so kitty doesn't keep every prompt's frames."""
    w, h = geo["w"], geo["h"]
    data = frame_rgba(geo["poses"][0], pal, w, h, 0)
    return escape(f"a=t,q=2,i=@ID@,f=32,s={w},v={h}", data) + escape(f"a=p,q=2,U=1,i=@ID@,c={CELLS},r=1")


def self_check():
    # The silhouette must not change while rolling (the even-arrowhead fix)
    a = render_pose(0, 12, 13, 0.8)
    b = render_pose(1, 12, 13, 0.8)
    assert [[bool(c) for c in r] for r in a] == [[bool(c) for c in r] for r in b], "silhouette changes"
    assert ramp((255, 182, 138), -8, 8)[3] == (255, 182, 138), "base tone must be the accent itself"
    # Lit from the top-left: the upper half of the head must be brighter than the lower half
    pose = render_pose(0, 36, 26, 0.4)
    tones = lambda rows: [int(c[1]) for r in rows for c in r if c.startswith("h")]
    top, bottom = tones(pose[:13]), tones(pose[13:])
    assert sum(top) / len(top) > sum(bottom) / len(bottom), "light comes from below"
    print("ok")


def main():
    if sys.argv[1:] == ["--check"]:
        return self_check()
    cell_w, cell_h, colors_json, out_dir = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3], Path(sys.argv[4])
    try:
        colors = json.loads(Path(colors_json).read_text())
    except (OSError, ValueError):
        colors = {}
    out_dir.mkdir(parents=True, exist_ok=True)
    geo = geometry(cell_w, cell_h, out_dir / "geometry.json")
    collar = hex_rgb(colors.get("tertiary", "#cbc992"))
    for name, key, fallback in (("ok", "primary", "#ffb68a"), ("err", "error", "#ffb4ab")):
        pal = palette(hex_rgb(colors.get(key, fallback)), collar)
        for file, text in ((f"{name}.kgp", payload(geo, pal)), (f"{name}-still.kgp", still(geo, pal))):
            tmp = out_dir / f".{file}.{os.getpid()}.tmp"
            tmp.write_text(text)
            tmp.replace(out_dir / file)  # atomic: a prompt never reads half a file


if __name__ == "__main__":
    main()
