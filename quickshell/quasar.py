#!/usr/bin/env python3

import fcntl
import json
import math
import multiprocessing
import struct
import subprocess
import sys
import time
import zlib
from contextlib import contextmanager
from pathlib import Path

W, BACK_H = 170, 1440
FPS, LOOP = 20, 90
FRAMES = FPS * LOOP
INC, TILT = math.radians(90 - 76), math.radians(10)
RS, RIN, ROUT = 6.0, 9.0, 74.0
TAU = 2 * math.pi
GIF_COLORS = 32
BACK_COLORS = 8
USAGE = """usage: quasar.py blur <cache> <wallpaper>
       quasar.py recolor <colors.json> <cache> [frame]
       quasar.py render <colors.json> <cache> <height>
       quasar.py --check"""
KEEP_HEIGHTS = 3


def hex_rgb(h):
    return tuple(int(h[i : i + 2], 16) for i in (1, 3, 5))


def mix(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def ramp(base, ink):
    return [ink, mix(ink, base, 0.34), mix(ink, base, 0.68), base, mix(base, (255,) * 3, 0.3), mix(base, (255,) * 3, 0.62)]


def bayer(x, y):
    def b2(ax, ay):
        return (ax / 2 + ay * ay * 0.75) % 1

    return b2(x // 2, y // 2) * 0.25 + b2(x, y)


def hash2(x, y):
    q0, q1, q2 = (x * 0.1031) % 1, (y * 0.1031) % 1, (x * 0.1031) % 1
    d = q0 * (q1 + 33.33) + q1 * (q2 + 33.33) + q2 * (q0 + 33.33)
    q0, q1, q2 = q0 + d, q1 + d, q2 + d
    return ((q0 + q1) * q2) % 1


def tone(r, v, x, y):
    v = min(max(v, 0.0), 0.9999) * 5
    lo = int(v)
    return 1 + 6 * r + lo + (1 if v - lo > bayer(x, y) else 0)


def snap(omega):
    return TAU * max(1, round(omega * LOOP / TAU)) / LOOP


def intensity(h):
    return min(0.9, max(0.35, 0.35 + 0.55 * (h - 250) / 900))


RING_OMEGA = {ri: snap(3.2 * ((ri + 0.5) / 1.15 / 9) ** -1.5) for ri in range(int(RIN * 1.15), int(ROUT * 1.15) + 1)}
WIG_OMEGA = snap(5.0)
JET_SHIFT = 56 * LOOP


def blinkers(h):
    return [
        (int(hash2(i, 1.3) * W), int(hash2(i, 7.1) * h), snap(TAU / (3 + 6 * hash2(i, 4.4))), hash2(i, 9.2) * TAU, 1 + (i & 1))
        for i in range(max(8, h // 22))
    ]


def disk_value(px, py, cx, cy, tilt, t, k):
    dx, dy = px + 0.5 - cx, py + 0.5 - cy
    ct, st, ci, si = math.cos(tilt), math.sin(tilt), math.cos(INC), math.sin(INC)
    qx, qy = dx * ct + dy * st, -dx * st + dy * ct
    x, z = qx, -qy / si
    r = math.hypot(x, z)
    front, dist = z * ci > 0, math.hypot(dx, dy)
    if not (RIN < r < ROUT) or (not front and dist <= RS + 1.5):
        return 0.0, 0.0, front
    th = math.atan2(z, x)
    ri = int(r * 1.15)
    hh = hash2(ri, 3.7)
    ph = th - RING_OMEGA[ri] * t + hh * TAU
    m = 3 + int(hh * 6)
    streak = (0.5 + 0.5 * math.sin(ph * m)) ** 3 + 0.6 * (0.5 + 0.5 * math.sin(ph * (m + 4) + 1.7)) ** 6
    dens = 1 - (r - RIN) / (ROUT - RIN)
    heat = (RIN / r) ** 0.8
    streak += 1.4 * (RIN / r) ** 3
    beam = 1 + 0.5 * math.cos(th) * ci
    return k * 2.4 * (0.1 + streak) * (0.25 + dens) * (0.4 + 0.6 * heat) * beam, heat, front


def frame(f, h):
    t = f / FPS
    k, cx, cy, reach = intensity(h), W // 2, h // 2, h * 0.47
    tilt = TILT * math.sin(TAU * t / LOOP)
    ct, st = math.cos(tilt), math.sin(tilt)
    out = bytearray(W * h)
    cap = 0.55 + 0.45 * k

    for sx, sy, om, ph, r in blinkers(h):
        b = (0.5 + 0.5 * math.sin(om * t + ph)) ** 4
        if b < 0.08:
            continue
        out[sy * W + sx] = 1 + 6 * r + (5 if b > 0.55 else 3)
        if b > 0.8:
            for ax, ay in ((sx - 1, sy), (sx + 1, sy), (sx, sy - 1), (sx, sy + 1)):
                if 0 <= ax < W and 0 <= ay < h:
                    out[ay * W + ax] = 1 + 6 * r + 3

    def put(x, y, v, r):
        vv = min(cap, 1 - math.exp(-v * 1.3))
        if v > 0.03 and min(1.0, vv * 2) > bayer(x, y):
            out[y * W + x] = tone(r, 0.22 + 0.75 * vv, x, y)

    ux, uy = -st, ct
    for py in range(h):
        a = (py + 0.5 - cy) / uy
        if not (RS + 2 < abs(a) < reach):
            continue
        side, life = (1 if a > 0 else -1), 1 - abs(a) / reach
        wig = 0.9 * math.sin(abs(a) * 0.09 - t * WIG_OMEGA + side * 2)
        grain = hash2((math.floor(abs(a) - t * 56)) % JET_SHIFT, side)
        if grain < 0.3:
            continue
        ax = cx + ux * a
        for px in range(int(ax) - 4, int(ax) + 5):
            if 0 <= px < W:
                off = (px + 0.5 - cx) * uy - (py + 0.5 - cy) * ux
                core = math.exp(-((off - wig) ** 2) / 0.4)
                put(px, py, k * 2.2 * life * life * core * (0.3 + grain), 2)

    span = int(ROUT * math.sin(INC) + ROUT * abs(st)) + 4
    for py in range(max(0, cy - span), min(h, cy + span + 1)):
        for px in range(max(0, cx - int(ROUT) - 2), min(W, cx + int(ROUT) + 3)):
            v, heat, front = disk_value(px, py, cx, cy, tilt, t, k)
            dist = math.hypot(px + 0.5 - cx, py + 0.5 - cy)
            if v:
                put(px, py, v, 1 if heat > 0.55 else 0)
            if dist < RS and not (front and v > 0.03):
                out[py * W + px] = 1
            up = -math.sin(math.atan2(py + 0.5 - cy, px + 0.5 - cx) - tilt)
            if up > 0.05:
                if abs(dist - RS - 0.5) < 0.7 and 0.8 > bayer(px, py):
                    out[py * W + px] = tone(1, 0.62 + 0.3 * k, px, py)
                elif abs(dist - RS * 1.8) < 1 and 0.65 * up * (0.5 + k) > bayer(px, py):
                    out[py * W + px] = tone(0, 0.5 + 0.35 * up, px, py)
    return bytes(out)


def lzw(px, min_size):
    clear, eoi = 1 << min_size, (1 << min_size) + 1
    size, nxt, table = min_size + 1, eoi + 1, {}
    out, buf, nb = bytearray(), 0, 0

    def flush(code):
        nonlocal buf, nb
        buf |= code << nb
        nb += size
        while nb >= 8:
            out.append(buf & 0xFF)
            buf >>= 8
            nb -= 8

    flush(clear)
    cur = px[0]
    for k in px[1:]:
        key = (cur << 8) | k
        if key in table:
            cur = table[key]
            continue
        flush(cur)
        if nxt < 4096:
            table[key] = nxt
            nxt += 1
            if nxt > (1 << size) and size < 12:
                size += 1
        else:
            flush(clear)
            table, nxt, size = {}, eoi + 1, min_size + 1
        cur = k
    flush(cur)
    flush(eoi)
    if nb:
        out.append(buf & 0xFF)
    return bytes(out)


def gif_frame(px, h):
    data = lzw(px, 5)
    blocks = b"".join(bytes([len(data[i : i + 255])]) + data[i : i + 255] for i in range(0, len(data), 255))
    gce = b"\x21\xf9\x04" + bytes([0b00001001]) + struct.pack("<H", 100 // FPS) + b"\x00\x00"
    return gce + b"\x2c" + struct.pack("<HHHH", 0, 0, W, h) + b"\x00\x05" + blocks + b"\x00"


def gif(frames_px, pal, h):
    head = b"GIF89a" + struct.pack("<HH", W, h) + b"\xf4\x00\x00" + gif_table(pal)
    loop = b"\x21\xff\x0bNETSCAPE2.0\x03\x01\x00\x00\x00"
    return head + loop + b"".join(frames_px) + b"\x3b"


def gif_table(pal):
    return b"".join(bytes(c) for c in pal) + b"\x00" * (3 * (GIF_COLORS - len(pal)))


def recolor_gif(data, pal):
    return data[:13] + gif_table(pal) + data[13 + 3 * GIF_COLORS :]


GIF_HEAD = 13 + 3 * GIF_COLORS + 19


def gif_frames(data):
    frames, p = [], GIF_HEAD
    while data[p] != 0x3B:
        q = p + 8 + 10 + 1
        while data[q]:
            q += data[q] + 1
        frames.append(data[p : q + 1])
        p = q + 1
    return frames


def rotate(data, k):
    frames = gif_frames(data)
    k %= len(frames)
    return data[:GIF_HEAD] + b"".join(frames[k:] + frames[:k]) + b"\x3b"


def png_chunk(kind, body):
    return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body))


def backdrop_png(pal, alpha):
    rows = []
    for y in range(BACK_H):
        t = max(0.0, 2 - abs(y / BACK_H - 0.5) * 6)
        lo = int(min(t, 1.999))
        row = bytearray(b"\x00")
        for x in range(W):
            hi = t - lo > bayer(x, y)
            c = (1 if hi else 0) if lo < 1 else (2 if hi else 1)
            hh = hash2(x + 0.5, y + 0.5)
            if hh > 0.9975:
                c = 3 if (hh * 7) % 1 < 0.5 else 4
            row.append(c)
        rows.append(bytes(row))
    ihdr = struct.pack(">IIBBBBB", W, BACK_H, 8, 3, 0, 0, 0)
    body = png_chunk(b"IHDR", ihdr) + png_plte(pal, alpha) + png_chunk(b"IDAT", zlib.compress(b"".join(rows), 9))
    return b"\x89PNG\r\n\x1a\n" + body + png_chunk(b"IEND", b"")


def png_plte(pal, alpha):
    plte = b"".join(bytes(c) for c in pal) + b"\x00" * (3 * (BACK_COLORS - len(pal)))
    trns = bytes([0, alpha, alpha, 255, 255] + [255] * (BACK_COLORS - 5))
    return png_chunk(b"PLTE", plte) + png_chunk(b"tRNS", trns)


def recolor_png(data, pal, alpha):
    start = data.index(b"PLTE") - 4
    end = data.index(b"IDAT") - 4
    return data[:start] + png_plte(pal, alpha) + data[end:]


def palettes(colors):
    def c(key, fallback):
        return hex_rgb(colors.get(key, fallback))

    surface = c("surface", "#1a120d")
    deep = mix(surface, c("primary_container", "#723610"), 0.45)
    ink = mix(surface, (0, 0, 0), 0.5)
    ramps = [ramp(c(k, f), ink) for k, f in (("primary", "#ffb4a5"), ("tertiary", "#dcc48c"), ("secondary", "#e7bdb2"))]
    gif_pal = [(0, 0, 0)] + [col for r in ramps for col in r]
    gif_pal[1] = ink
    back_pal = [(0, 0, 0), mix(surface, deep, 0.5), deep, ramps[1][3], ramps[2][3]]
    return surface, gif_pal, back_pal


def blur_wallpaper(src, dst):
    subprocess.run(
        ["magick", f"{src}[0]", "-alpha", "off", "-resize", "3440x1440^", "-gravity", "center", "-extent", "3440x1440",
         "-resize", "25%", "-blur", "0x2.5", "-modulate", "100,117", "-brightness-contrast", "0x-11", str(dst)],
        check=True,
    )


@contextmanager
def locked(cache):
    with open(cache / ".lock", "w") as f:
        fcntl.flock(f, fcntl.LOCK_EX)
        yield


def read_state(cache):
    try:
        return json.loads((cache / "state.json").read_text())
    except (OSError, ValueError):
        return {"stamp": 0, "heights": []}


def write_state(cache, state):
    tmp = cache / ".state.json.tmp"
    tmp.write_text(json.dumps(state))
    tmp.replace(cache / "state.json")


def blur(cache, wallpaper):
    tmp = cache / ".wall-pending.png"
    blur_wallpaper(wallpaper, tmp)
    tmp.replace(cache / "wall-pending.png")


def recolor(colors, cache, start=0):
    surface, gif_pal, back_pal = palettes(colors)
    alpha = 230
    with locked(cache):
        st = read_state(cache)
        old, new = st.get("stamp", 0), int(time.time() * 1000)
        for h in st.get("heights", []):
            src = cache / f"quasar-{h}-{old}.gif"
            if src.exists():
                (cache / f"quasar-{h}-{new}.gif").write_bytes(rotate(recolor_gif(src.read_bytes(), gif_pal), start))
        bsrc = cache / f"backdrop-{old}.png"
        back = recolor_png(bsrc.read_bytes(), back_pal, alpha) if bsrc.exists() else backdrop_png(back_pal, alpha)
        (cache / f"backdrop-{new}.png").write_bytes(back)
        if (cache / "wall-pending.png").exists():
            (cache / "wall-pending.png").replace(cache / f"wall-{new}.png")
            st["wall"] = f"wall-{new}.png"
        st.update(stamp=new, surface="#%02x%02x%02x" % surface, palette=colors.get("primary", "") + colors.get("surface", ""))
        st["heights"] = [h for h in st.get("heights", []) if (cache / f"quasar-{h}-{new}.gif").exists()]
        write_state(cache, st)
        for f in [*cache.glob("quasar-*.gif"), *cache.glob("backdrop-*.png"), *cache.glob("wall-*.png")]:
            if not f.stem.endswith((str(new), "pending")) and f.name != st.get("wall"):
                f.unlink()


def remember(heights, h):
    return [x for x in heights if x != h][1 - KEEP_HEIGHTS :] + [h]


def render_frame(args):
    f, h = args
    return gif_frame(frame(f, h), h)


def render(colors_json, cache, h):
    with multiprocessing.get_context("fork").Pool() as pool:
        frames = pool.map(render_frame, [(f, h) for f in range(FRAMES)], chunksize=30)
    with locked(cache):
        st = read_state(cache)
        if not st.get("stamp"):
            return
        _, gif_pal, _ = palettes(load_colors(colors_json))
        (cache / f"quasar-{h}-{st['stamp']}.gif").write_bytes(gif(frames, gif_pal, h))
        kept = remember(st.get("heights", []), h)
        for x in set(st.get("heights", [])) - set(kept):
            (cache / f"quasar-{x}-{st['stamp']}.gif").unlink(missing_ok=True)
        st["heights"] = kept
        write_state(cache, st)


def load_colors(path):
    try:
        return json.loads(Path(path).read_text())
    except (OSError, ValueError):
        return {}


def self_check():
    h = 600
    a, b = frame(0, h), frame(FRAMES, h)
    assert a == b, "the loop isn't seamless"
    assert sum(1 for v in a if v) > 500, "empty frame"
    assert frame(FRAMES // 4, h) != a, "nothing moves"
    assert intensity(1100) > intensity(400), "intensity doesn't grow with free space"
    assert remember([400, 800, 1100], 600) == [800, 1100, 600] and remember([400, 800], 400) == [800, 400]
    _, pal, back = palettes({})
    _, pal2, back2 = palettes({"primary": "#00ff00"})
    g = gif([gif_frame(a, h)], pal, h)
    assert recolor_gif(g, pal2)[13 + 3] == 0 or recolor_gif(g, pal2) != g, "recolour didn't touch the palette"
    assert len(recolor_gif(g, pal2)) == len(g)
    two = gif([gif_frame(a, h), gif_frame(frame(1, h), h)], pal, h)
    assert len(gif_frames(two)) == 2 and len(rotate(two, 1)) == len(two), "frame rotation lost data"
    assert gif_frames(rotate(two, 1))[0] == gif_frames(two)[1], "rotation doesn't start at the frame asked for"
    p = backdrop_png(back, 230)
    assert recolor_png(p, back2, 230).startswith(b"\x89PNG") and len(recolor_png(p, back2, 230)) == len(p)
    print("ok")


def main():
    cmd = sys.argv[1:]
    if cmd == ["--check"]:
        return self_check()
    cache = Path(cmd[2] if cmd[0] != "blur" else cmd[1])
    cache.mkdir(parents=True, exist_ok=True)
    if cmd[0] == "blur":
        blur(cache, cmd[2])
    elif cmd[0] == "recolor":
        recolor(load_colors(cmd[1]), cache, int(cmd[3]) if len(cmd) > 3 else 0)
    elif cmd[0] == "render":
        render(cmd[1], cache, int(cmd[3]))
    else:
        sys.exit(USAGE)


if __name__ == "__main__":
    main()
