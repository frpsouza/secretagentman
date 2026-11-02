"""Builds secretagentman.p8 from the sources in fontes/.

  fontes/lua/*.lua          game code, one module per pico-8 editor tab (MODULES order)
  fontes/sprites/*.txt      sprite sheet (ASCII pixel art)
  fontes/audio/audio.py     sound effects and music

Also writes fontes/sprites/spritesheet.png (4x preview of the sheet)
and fontes/audio/midi/*.mid (music previews, see tools/midi.py).
Usage: python tools/build.py
"""
import glob
import os
import re
import struct
import sys
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "fontes")
OUT = os.path.join(ROOT, "secretagentman.p8")
sys.path.insert(0, os.path.join(SRC, "audio"))
import audio  # noqa: E402

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import midi  # noqa: E402

MODULES = ["main", "level", "physics", "actors", "draw"]

PAL = [(0, 0, 0), (29, 43, 83), (126, 37, 83), (0, 135, 81), (171, 82, 54), (95, 87, 79),
       (194, 195, 199), (255, 241, 232), (255, 0, 77), (255, 163, 0), (255, 236, 39),
       (0, 228, 54), (41, 173, 255), (131, 118, 156), (255, 119, 168), (255, 204, 170)]


# ---------------------------------------------------------------- sprites
def load_sheet():
    sheet = [[14] * 128 for _ in range(128)]
    for path in sorted(glob.glob(os.path.join(SRC, "sprites", "*.txt"))):
        block = None
        with open(path, encoding="utf-8") as f:
            for n, line in enumerate(f, 1):
                line = line.rstrip()
                if line.startswith("#"):
                    continue
                if line.startswith("@"):
                    _, x, y = line.split()[:3]
                    block = [int(x), int(y), 0]
                    continue
                if not line:
                    block = None
                    continue
                if block is None:
                    sys.exit("%s:%d: pixel row outside a '@' block" % (path, n))
                x0, y0, row = block
                for i, ch in enumerate(line):
                    sheet[y0 + row][x0 + i] = 14 if ch == "." else int(ch, 16)
                block[2] += 1
    return sheet


def write_png(path, sheet, scale=4):
    raw = b""
    for r in sheet:
        line = b"".join(bytes(PAL[c]) * scale for c in r)
        raw += (b"\x00" + line) * scale

    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)

    w, h = len(sheet[0]) * scale, len(sheet) * scale
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


# ---------------------------------------------------------------- sound
def sfx_line(notes, speed):
    notes = list(notes)[:32]
    notes += [(0, 0, 0, 0)] * (32 - len(notes))
    return "%02x%02x%02x%02x" % (0, speed, 0, 0) + "".join("%02x%x%x%x" % n for n in notes)


def build_sfx():
    return [sfx_line(*audio.SFX[i]) if i in audio.SFX else sfx_line([], 16) for i in range(64)]


def build_music():
    lines = ["%02x %02x%02x%02x%02x" % pat for pat in audio.MUSIC]
    return lines + ["00 40404040"] * (64 - len(lines))


# ---------------------------------------------------------------- tokens
def count_tokens(code):
    """Approximation of pico-8's token counter."""
    code = re.sub(r"--\[\[.*?\]\]", "", code, flags=re.S)
    code = re.sub(r"--[^\n]*", "", code)
    toks = re.findall(
        r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|0x[0-9a-fA-F.]+|\d+\.?\d*|\.\d+|'
        r"[A-Za-z_]\w*|\.\.\.?|[<>=~!]=|\\|\+=|-=|\*=|/=|%=|\.\.=|[-+*/%^#<>=(){}\[\];:,.@&|]",
        code,
    )
    free = {",", ".", ":", ";", ")", "]", "}", "end", "local"}
    return sum(1 for t in toks if t not in free)


def main():
    parts = []
    for m in MODULES:
        with open(os.path.join(SRC, "lua", m + ".lua"), encoding="utf-8") as f:
            parts.append(f.read().strip("\n"))
    code = "\n-->8\n".join(parts)  # -->8 starts a new tab in the pico-8 editor
    tokens = count_tokens(code)
    print("approx tokens: %d / 8192, chars: %d / 65535" % (tokens, len(code)))
    if tokens > 8192:
        print("WARNING: over token limit")
    sheet = load_sheet()
    write_png(os.path.join(SRC, "sprites", "spritesheet.png"), sheet)
    out = ["pico-8 cartridge // http://www.pico-8.com", "version 41", "__lua__", code.rstrip("\n"),
           "__gfx__"]
    out += ["".join("%x" % c for c in row) for row in sheet]
    out.append("__sfx__")
    out += build_sfx()
    out.append("__music__")
    out += build_music()
    label = os.path.join(SRC, "label.txt")  # 128x128 cart label (needed for html export)
    if os.path.exists(label):
        with open(label, encoding="utf-8") as f:
            out += ["__label__"] + [r.strip() for r in f if r.strip()]
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out) + "\n\n")
    print("wrote", OUT)
    print("midi previews in", midi.export(audio, os.path.join(SRC, "audio", "midi")))


if __name__ == "__main__":
    main()
