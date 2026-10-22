#!/usr/bin/env python3
import base64
import colorsys
import json
import math
import os
import sys
import zlib
from pathlib import Path

CELLS = 3
FACETS = 5
STEPS = 8
ROLL_MS = 110
REST_MS = 2500
BOB_PX = 1
STRIP_STARS = 4
SWEEP_MS = 100
SS = 3
CHUNK = 4096

LIGHT = (-0.45, -0.7, -0.55)
_ll = math.sqrt(sum(c * c for c in LIGHT))
LX, LY, LZ = (c / _ll for c in LIGHT)


def scene(x, y, z, faceted):
    rho = math.hypot(y, z)
    if faceted:
        sector = 2 * math.pi / FACETS
        phi = (math.atan2(z, y) + sector / 2) % sector - sector / 2
        r = rho * math.cos(phi)
    else:
        r = rho
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
    ring = math.hypot(rho - 1.25, x + 1.0) - 0.5
    if ring < d:
        d, m = ring, "c"
    ball = math.sqrt((x + 4.3) ** 2 + y * y + z * z) - 2.4
    if ball < d:
        d, m = ball, ("s" if abs(z) < 0.7 else "b")
    return d, m


def render_pose(step, w, h, px_size):
    ang = 2 * math.pi * step / STEPS
    ca, sa = math.cos(ang), math.sin(ang)

    def at(f, x, y, z):
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
                    spec = max(0.0, LZ - 2 * diff * nz) ** 28
                    rim = diff < 0.1 and nx * 0.6 + ny * 0.8 > 0.55
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
    px_size = 10.4 / h
    data = {"w": w, "h": h, "poses": [render_pose(s, w, h, px_size) for s in range(STEPS)]}
    tmp = path.parent / f".{path.name}.{os.getpid()}.tmp"
    tmp.write_text(json.dumps(data, separators=(",", ":")))
    tmp.replace(path)
    return data


def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def ramp(rgb, shadow_hue, light_hue):
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
            sx = x - bob
            c = filled(sx, y)
            if not c:
                n = filled(sx, y - 1) or filled(sx - 1, y) or filled(sx + 1, y) or filled(sx, y + 1)
                c = mix(n, pal["ink"], 0.78) if n else None
            out += bytes((*c, 255)) if c else b"\0\0\0\0"
    return bytes(out)


def escape(keys, data=b""):
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


def animation(frames, w, h, cols, rows=1):
    size = f"f=32,s={w},v={h}"
    seqs = []
    for n, (data, gap) in enumerate(frames):
        if n == 0:
            seqs.append(escape(f"a=t,q=2,i=@ID@,{size}", data))
            seqs.append(escape(f"a=p,q=2,U=1,i=@ID@,c={cols},r={rows}"))
            seqs.append(escape(f"a=a,q=2,i=@ID@,r=1,z={gap}"))
        else:
            seqs.append(escape(f"a=f,q=2,i=@ID@,{size},z={gap}", data))
    seqs.append(escape("a=a,q=2,i=@ID@,s=3,v=1"))
    return "".join(seqs)


def still(data, w, h, cols, rows=1):
    return escape(f"a=t,q=2,i=@ID@,f=32,s={w},v={h}", data) + escape(f"a=p,q=2,U=1,i=@ID@,c={cols},r={rows}")


def gem_frames(geo, pal):
    w, h, poses = geo["w"], geo["h"], geo["poses"]
    frames = [(poses[k % STEPS], BOB_PX if 3 <= k <= 6 else 0, ROLL_MS) for k in range(1, STEPS + 1)]
    frames[-1] = (poses[0], 0, REST_MS)
    return [(frame_rgba(pose, pal, w, h, bob), gap) for pose, bob, gap in frames]


def strip_frames(cell_w, cell_h, dim, star, peak, bg):
    w, h, cy = (STRIP_STARS + 1) * cell_w, cell_h, cell_h // 2
    sweep = 12
    rest = (STEPS - 1) * ROLL_MS + REST_MS - sweep * SWEEP_MS
    frames = []
    for f in range(sweep + 1):
        px = {}
        for k in range(STRIP_STARS):
            x, d = k * cell_w + cell_w // 2, abs(f - (2 + 2 * k)) if f < sweep else 9
            if d == 0:
                px[x, cy] = peak
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    px[x + dx, cy + dy] = star
            else:
                px[x, cy] = star if d == 1 else dim
        d = abs(f - 10) if f < sweep else 9
        arm = 3 if d == 0 else 2 if d == 1 else 1
        x = STRIP_STARS * cell_w + cell_w // 2
        px[x, cy] = peak if arm >= 2 else star
        for i in range(1, arm + 1):
            c = mix(star, bg, 0.35) if i == arm and arm > 1 else star
            for dx, dy in ((i, 0), (-i, 0), (0, i), (0, -i)):
                px[x + dx, cy + dy] = c
        data = bytearray(w * h * 4)
        for (x, y), c in px.items():
            data[(y * w + x) * 4 : (y * w + x) * 4 + 4] = bytes((*c, 255))
        frames.append((bytes(data), SWEEP_MS if f < sweep else rest))
    return frames


def self_check():
    a = render_pose(0, 12, 13, 0.8)
    b = render_pose(1, 12, 13, 0.8)
    assert [[bool(c) for c in r] for r in a] == [[bool(c) for c in r] for r in b], "silhouette changes"
    assert ramp((255, 182, 138), -8, 8)[3] == (255, 182, 138), "base tone must be the accent itself"
    pose = render_pose(0, 36, 26, 0.4)
    tones = lambda rows: [int(c[1]) for r in rows for c in r if c.startswith("h")]
    top, bottom = tones(pose[:13]), tones(pose[13:])
    assert sum(top) / len(top) > sum(bottom) / len(bottom), "light comes from below"
    gem = gem_frames({"w": 12, "h": 13, "poses": [a] * STEPS}, palette((255, 182, 138), (203, 201, 146)))
    p = animation(gem, 12, 13, CELLS)
    assert p.count("a=f,") == STEPS - 1 and "v=1" in p and f"z={REST_MS}" in p, "idle loop"
    strip = strip_frames(12, 26, (1, 1, 1), (2, 2, 2), (3, 3, 3), (0, 0, 0))
    assert sum(g for _, g in strip) == sum(g for _, g in gem), "strip out of step with the gem"
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

    def color(key, fallback):
        return hex_rgb(colors.get(key, fallback))

    def write(file, text):
        tmp = out_dir / f".{file}.{os.getpid()}.tmp"
        tmp.write_text(text)
        tmp.replace(out_dir / file)

    dim, star = color("outline_variant", "#52443c"), color("tertiary", "#cbc992")
    paper = color("surface_dim", "#e8d7cf") if colors.get("mode") == "light" else color("surface", "#1a120d")
    strip = strip_frames(cell_w, cell_h, dim, star, color("on_surface", "#f0dfd7"), paper)
    sw = (STRIP_STARS + 1) * cell_w
    write("strip.kgp", animation(strip, sw, cell_h, STRIP_STARS + 1))
    write("strip-still.kgp", still(strip[-1][0], sw, cell_h, STRIP_STARS + 1))
    write("dim", "%d;%d;%d" % dim)
    geo = geometry(cell_w, cell_h, out_dir / "geometry.json")
    w, h = geo["w"], geo["h"]
    for name, key, fallback in (("ok", "primary", "#ffb68a"), ("err", "error", "#ffb4ab")):
        pal = palette(color(key, fallback), star)
        write(f"{name}.kgp", animation(gem_frames(geo, pal), w, h, CELLS))
        write(f"{name}-still.kgp", still(frame_rgba(geo["poses"][0], pal, w, h, 0), w, h, CELLS))


if __name__ == "__main__":
    main()
