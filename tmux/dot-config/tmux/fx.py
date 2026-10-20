#!/usr/bin/env python3
import os
import random
import signal
import subprocess
import sys
import time
from pathlib import Path

FRAME_S = 1 / 30
FRAMES = {"switch": 12, "attach": 14, "bell": 8}
ARROW = "\uf04b"  # 0xProto has no ▶; the fallback glyph sits below the text
CURSOR_IN = ["  ", "  ", "  ", "  ", " " + ARROW, " " + ARROW, ARROW + " ", ARROW + " ", " " + ARROW, ARROW + " ", ARROW + " ", ARROW + " "]
SHADOW_IN = [" "] * 6 + ["░", "▒", "▓", "▓", "▌", "▌"]
KEYS = ["bar", "primary", "on_primary", "primary_container", "on_primary_container", "tertiary", "tertiary_container",
        "on_tertiary_container", "on_surface_variant", "outline", "error", "red", "cyan"]


def wake_shells(session):
    # SIGUSR1 kills shells without the pixel-prompt trap, so only signal registered ones
    reg = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") / "pixel-prompt" / "shells"
    for pid in tmux("list-panes", "-s", "-t", session, "-F", "#{pane_pid}").split():
        try:
            start = Path(f"/proc/{pid}/stat").read_text().rsplit(") ", 1)[1].split()[19]
            if (reg / pid).read_text().strip() == start:
                os.kill(int(pid), signal.SIGUSR1)
        except (OSError, IndexError):
            pass


def tmux(*args):
    return subprocess.run(["tmux", *args], capture_output=True, text=True).stdout


def cells(text, fg, bg=None, bold=False):
    return [[ch, fg, bg, bold] for ch in text]


def render(name, wins, c, fx, f):
    row, chip, spans = [], None, {}
    row += cells(f" {name} ", c["on_primary"], c["primary"], True) + cells("▌ ", c["tertiary"])
    for index, title, active, activity, bell, last in wins:
        start = len(row)
        if active:
            cur, bg, fg, shadow = ARROW + " ", c["primary_container"], c["on_primary_container"], "▌"
            if fx == "switch":
                cur, shadow = CURSOR_IN[f], SHADOW_IN[f]
                if f < 6:
                    bg, fg = c["tertiary_container"], c["on_tertiary_container"]
            row += cells(" " + cur, c["tertiary"])
            chip = (len(row), len(row) + len(index) + len(title) + 3)
            row += cells(f" {index} {title} ", fg, bg, True) + cells(shadow, c["tertiary"]) + cells(" ", None)
        else:
            cur, cfg = (ARROW + " ", c["outline"]) if fx == "switch" and last and f < 3 else ("  ", None)
            row += cells(" " + cur, cfg) + cells(f" {index} {title}", c["on_surface_variant"])
            if activity:
                row += cells(" •", c["tertiary"], None, True)
            if bell:
                row += cells(" !", c["error"], None, True)
            row += cells(" ", None)
        spans[index] = (start, len(row))
    return row, chip, spans


def tear(row, a, b, f, strength, c):
    if strength <= 0:
        return
    snap = [cell[:] for cell in row]
    for x in range(max(0, a), min(len(row), b)):
        if snap[x][0] == " " and random.random() > 0.2:
            continue
        p = random.random()
        ink = c["red"] if random.random() < 0.5 else c["cyan"]
        if p < strength:
            src = min(len(row) - 1, max(0, x + random.choice((-1, 1)) * (1 + f % 2)))
            row[x] = [snap[src][0], ink, snap[src][2], snap[src][3]]
        elif p < strength + 0.06:
            row[x] = [random.choice("▚▞░▔"), ink, snap[x][2], snap[x][3]]


def misregister(row, a, b, d, c):
    snap = [cell[:] for cell in row]
    for x in range(a, b):
        row[x] = [" ", None, None, False]
    for x in range(a, b):
        if 0 <= x + d < len(row):
            row[x + d] = snap[x]
    ghost = a + d - 1 if d > 0 else b + d
    if 0 <= ghost < len(row):
        row[ghost] = ["▌", c["red"] if d > 0 else c["cyan"], None, False]


def frame(name, wins, c, fx, f, bell_index=None):
    row, chip, spans = render(name, wins, c, fx, f)
    if fx == "attach":
        tear(row, 0, len(row), f, 0.45 - f * 0.04, c)
    elif fx == "switch" and chip:
        if f < 3:
            tear(row, chip[0] - 3, chip[1] + 3, f, (0.55, 0.45, 0.3)[f], c)
        elif f < 6:
            misregister(row, chip[0], chip[1], (2, -1, 1)[f - 3], c)
    elif fx == "bell" and bell_index in spans:
        a, b = spans[bell_index]
        for x in range(a, b):
            if row[x][0] != " ":
                row[x][1] = c["cyan"] if f % 2 else c["red"]
        tear(row, a, b, f, 0.45 - f * 0.06, c)
    return row


def to_style(row, bar):
    out, last = [], None
    for ch, fg, bg, bold in row:
        style = (fg or "default", bg or bar, bold)
        if style != last:
            out.append(f"#[fg={style[0]},bg={style[1]},{'bold' if bold else 'nobold'}]")
            last = style
        out.append("##" if ch == "#" else ch)
    return "".join(out)


def main():
    fx, session = sys.argv[1], sys.argv[2]
    bell_index = sys.argv[3] if len(sys.argv) > 3 else None
    info = tmux("display", "-p", "-t", session, "\t".join([f"#{{@c_{k}}}" for k in KEYS] + ["#{@fx_pid}", "#{session_name}"]))
    *vals, prev, name = info.rstrip("\n").split("\t")
    c = dict(zip(KEYS, vals))
    if prev.isdigit():
        try:
            os.kill(int(prev), signal.SIGTERM)
        except ProcessLookupError:
            pass
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    tmux("set", "-t", session, "@fx_pid", str(os.getpid()))
    fmt = "#{window_index}\t#{window_name}\t#{window_active}\t#{window_activity_flag}\t#{window_bell_flag}\t#{window_last_flag}"
    wins = []
    for line in tmux("list-windows", "-t", session, "-F", fmt).splitlines():
        index, title, *flags = line.split("\t")
        wins.append((index, title, *(v == "1" for v in flags)))
    if fx == "attach":
        tmux("set", "-t", session, "@lamp_need", "1")
        wake_shells(session)
    clients = tmux("list-clients", "-t", session, "-F", "#{client_name}").split()
    refresh = [arg for cl in clients for arg in (";", "refresh-client", "-S", "-t", cl)]

    start = time.monotonic()
    for f in range(FRAMES[fx]):
        tmux("set", "-t", session, "@fx_left", to_style(frame(name, wins, c, fx, f, bell_index), c["bar"]), *refresh)
        time.sleep(max(0, start + (f + 1) * FRAME_S - time.monotonic()))
    if tmux("show", "-qv", "-t", session, "@fx_pid").strip() == str(os.getpid()):
        tmux("set", "-u", "-t", session, "@fx_left", ";", "set", "-u", "-t", session, "@fx_pid", *refresh)


def self_check():
    c = {k: f"#{i:06x}" for i, k in enumerate(KEYS)}
    wins = [("1", "zsh", False, True, False, True), ("2", "n#vim", True, False, False, False)]
    for fx, n in FRAMES.items():
        for f in range(n):
            row = frame("dot", wins, c, fx, f, "1")
            assert len(row) == len(render("dot", wins, c, fx, f)[0]), "frames must keep the strip width"
    clean = to_style(render("dot", wins, c, "none", 0)[0], c["bar"])
    assert "n##vim" in clean and ARROW in clean, clean
    print("ok")


if __name__ == "__main__":
    self_check() if sys.argv[1:] == ["--check"] else main()
