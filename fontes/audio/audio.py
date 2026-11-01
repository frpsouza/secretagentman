"""Sound effects and music for Secret Agent Man (read by tools/build.py).

Notes use pico-8 octave numbering: c0 = pitch 0, a2 = 33 (concert A).
Waveforms: 0 triangle, 1 tilted saw, 2 saw, 3 square, 4 pulse, 5 organ, 6 noise, 7 phaser.
Effects:   0 none, 1 slide, 2 vibrato, 3 drop, 4 fade in, 5 fade out, 6/7 arpeggio.
A raw note is (pitch, wave, volume, effect).
"""

NOTE = {"c": 0, "d": 2, "e": 4, "f": 5, "g": 7, "a": 9, "b": 11}


def pitch(tok):
    n = NOTE[tok[0]]
    rest = tok[1:]
    if rest.startswith("#"):
        n += 1
        rest = rest[1:]
    elif rest.startswith("b") and len(rest) > 1:
        n -= 1
        rest = rest[1:]
    return n + 12 * int(rest)


def seq(text, wave, vol, fx=0, trem=False, vib_long=False):
    """'e2 - . g2' : note, '-' = hold previous, '.' = rest."""
    notes, prev = [], None
    for i, tok in enumerate(text.split()):
        if tok == ".":
            notes.append((0, 0, 0, 0))
            prev = None
        elif tok == "-":
            p, w, v, _ = prev
            notes.append((p, w, v, 2 if vib_long else 0))
        else:
            v = vol
            if trem and i % 2:
                v = max(1, vol - 2)  # surf tremolo picking
            prev = (pitch(tok), wave, v, fx)
            notes.append(prev)
    return notes


def drums(text, fill=False):
    kit = {
        "K": (16, 3, 6, 3),  # kick
        "S": (38, 6, 5, 5),  # snare
        "H": (60, 6, 2, 5),  # hi-hat
        ".": (0, 0, 0, 0),
    }
    out = []
    for i, tok in enumerate(text.split()):
        p, w, v, f = kit[tok]
        if fill and tok == "S":
            v = min(7, 3 + i // 6)
        out.append((p, w, v, f))
    return out


# ---------------------------------------------------------------- sfx
# index: (notes, speed). Indices are referenced by sfx(n) in game.lua.
SFX = {
    0: ([(60, 6, 7, 0), (48, 6, 6, 0), (36, 6, 4, 5), (30, 6, 2, 5)], 3),  # player shot
    1: ([(52, 6, 6, 0), (40, 6, 5, 0), (30, 6, 3, 5)], 4),  # enemy shot
    2: ([(36, 3, 5, 0), (33, 3, 5, 0), (30, 3, 4, 0), (26, 3, 4, 0), (22, 3, 3, 0), (18, 3, 2, 5)], 4),  # enemy down
    3: ([(p, 2, 5, 0) for p in range(40, 10, -3)] + [(10, 2, 3, 5)], 6),  # player dies
    4: ([(36, 4, 5, 0), (40, 4, 5, 0), (43, 4, 5, 0), (48, 4, 5, 0), (48, 4, 4, 5)], 5),  # plans collected
    5: ([(63, 6, 5, 0), (58, 6, 4, 0), (61, 6, 3, 0), (55, 6, 3, 0), (60, 6, 2, 5), (50, 6, 1, 5)], 2),  # lamp glass
    6: ([(45, 0, 5, 0), (41, 0, 4, 5)], 10),  # lift ding
    7: ([(24, 4, 3, 1), (30, 4, 3, 1), (36, 4, 2, 1), (40, 4, 1, 5)], 2),  # jump
    8: ([(40, 3, 5, 0), (47, 3, 5, 0), (52, 3, 5, 0), (52, 3, 3, 5)], 4),  # start
    9: ([(20, 6, 7, 3), (14, 2, 7, 3), (10, 6, 6, 3), (8, 2, 5, 5), (6, 6, 4, 5)], 4),  # crushed / fall
    10: ([(8 + i // 2, 2, 5 if i % 2 == 0 else 3, 0) for i in range(24)], 3),  # car engine
    11: ([(28, 4, 5, 0), (31, 4, 5, 0), (35, 4, 5, 0), (39, 4, 5, 0),
          (40, 4, 5, 2), (40, 4, 4, 2), (40, 4, 3, 2), (40, 4, 2, 5)], 8),  # all plans / mission jingle
    12: ([(14, 7, 3, 1), (18, 7, 3, 1), (16, 7, 2, 5)], 6),  # door
    14: ([(40, 2, 5, 0), (38, 2, 5, 0), (35, 2, 5, 0), (31, 2, 5, 2), (31, 2, 4, 2), (31, 2, 3, 5)], 14),  # game over
}

# ---------------------------------------------------------------- music
# Original 60s surf/spy groove in E: blues bass ostinato, surf-tremolo lead.
SPEED = 13
BASS_E = ("e0 . e0 . g0 . e0 . a0 . e0 . bb0 . a0 . "
          "e0 . e0 . g0 . e0 . d1 . b0 . a0 . g0 .")
BASS_A = ("a0 . a0 . c1 . a0 . d1 . a0 . eb1 . d1 . "
          "a0 . a0 . c1 . a0 . g1 . e1 . d1 . c1 .")
BASS_BA = ("b0 . b0 . d1 . b0 . e1 . b0 . f1 . e1 . "
           "a0 . a0 . c1 . a0 . d1 . a0 . eb1 . d1 .")
BEAT = "K . H . S . H . K . K H S . H H " * 2
FILL = "K . H . S . H . K . K H S . H H K . H . S . S . S S S S S S S S"
LEAD_A = ("e2 - - g2 a2 - bb2 a2 g2 - e2 - d2 e2 - - "
          "e2 - - g2 a2 - b2 - d3 - b2 a2 g2 - e2 -")
LEAD_B = ("b2 b2 b2 b2 a2 a2 a2 a2 g2 g2 g2 g2 e2 e2 e2 e2 "
          "g2 g2 g2 g2 a2 a2 b2 b2 e3 e3 e3 e3 e3 e3 e3 .")
LEAD_C = ("a2 - c3 - d3 - eb3 d3 c3 - a2 - g2 a2 - - "
          "a2 - c3 - d3 - e3 - g3 - e3 d3 c3 - a2 -")
LEAD_D = ("b2 - - - b2 a2 - - a2 g2 - - e2 g2 a2 bb2 "
          "b2 - e3 - - - - - e2 - - - - - . .")

SFX.update({
    16: (seq(BASS_E, 1, 5), SPEED),
    17: (seq(BASS_A, 1, 5), SPEED),
    18: (seq(BASS_BA, 1, 5), SPEED),
    19: (drums(BEAT), SPEED),
    20: (drums(FILL, fill=True), SPEED),
    21: (seq(LEAD_A, 4, 4, vib_long=True), SPEED),
    22: (seq(LEAD_B, 4, 4, trem=True), SPEED),
    23: (seq(LEAD_C, 4, 4, vib_long=True), SPEED),
    24: (seq(LEAD_D, 4, 4, vib_long=True), SPEED),
})

OFF = 0x40  # channel disabled (channel 3 is left free for sound effects)
# (flags, ch0, ch1, ch2, ch3); flags: 1 = loop start, 2 = loop end, 4 = stop
MUSIC = [
    (0, 16, 19, OFF, OFF),  # intro: bass + drums
    (1, 16, 19, 21, OFF),  # theme A          <- loop start
    (0, 16, 19, 22, OFF),  # tremolo break
    (0, 17, 19, 23, OFF),  # IV chord
    (0, 16, 19, 21, OFF),  # theme A
    (2, 18, 20, 24, OFF),  # turnaround + fill -> loop end
]
