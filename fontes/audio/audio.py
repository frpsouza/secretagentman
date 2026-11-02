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
# index: (notes, speed). Indices are referenced by sfx(n) in fontes/lua/*.lua.
SFX = {
    0: ([(60, 6, 7, 0), (48, 6, 6, 0), (36, 6, 4, 5), (30, 6, 2, 5)], 3),  # player shot
    1: ([(52, 6, 6, 0), (40, 6, 5, 0), (30, 6, 3, 5)], 4),  # enemy shot
    2: ([(36, 3, 5, 0), (33, 3, 5, 0), (30, 3, 4, 0), (26, 3, 4, 0), (22, 3, 3, 0), (18, 3, 2, 5)], 4),  # enemy down
    3: ([(p, 2, 5, 0) for p in range(40, 10, -3)] + [(10, 2, 3, 5)], 6),  # player dies
    4: ([(36, 4, 5, 0), (40, 4, 5, 0), (43, 4, 5, 0), (48, 4, 5, 0), (48, 4, 4, 5)], 5),  # plans collected
    5: ([(63, 6, 5, 0), (58, 6, 4, 0), (61, 6, 3, 0), (55, 6, 3, 0), (60, 6, 2, 5), (50, 6, 1, 5)], 2),  # lamp glass
    6: ([(45, 0, 5, 0), (41, 0, 4, 5)], 10),  # lift ding
    7: ([(24, 1, 5, 1), (31, 1, 5, 1), (36, 1, 4, 1), (41, 1, 3, 1), (44, 1, 2, 5)], 2),  # jump
    8: ([(40, 3, 5, 0), (47, 3, 5, 0), (52, 3, 5, 0), (52, 3, 3, 5)], 4),  # start
    9: ([(20, 6, 7, 3), (14, 2, 7, 3), (10, 6, 6, 3), (8, 2, 5, 5), (6, 6, 4, 5)], 4),  # crushed / fall
    10: ([(8 + i // 2, 2, 5 if i % 2 == 0 else 3, 0) for i in range(24)], 3),  # car engine
    11: ([(28, 4, 5, 0), (31, 4, 5, 0), (35, 4, 5, 0), (39, 4, 5, 0),
          (40, 4, 5, 2), (40, 4, 4, 2), (40, 4, 3, 2), (40, 4, 2, 5)], 8),  # all plans / mission jingle
    12: ([(14, 7, 3, 1), (18, 7, 3, 1), (16, 7, 2, 5)], 6),  # door
    13: ([(20, 6, 4, 5), (14, 3, 5, 3), (10, 3, 3, 5), (30, 6, 2, 5), (28, 6, 2, 5), (26, 6, 1, 5)], 5),  # parachute landing
    15: ([(50 - i * 2, 0, 4, 1) for i in range(14)] + [(22, 0, 2, 5)], 3),  # falling down a shaft (whistle)
    14: ([(40, 2, 5, 0), (38, 2, 5, 0), (35, 2, 5, 0), (31, 2, 5, 2), (31, 2, 4, 2), (31, 2, 3, 5)], 14),  # game over
}

# ---------------------------------------------------------------- music
# Original 60s surf/spy groove: a 12-bar blues in E. One pattern = 2 bars
# (32 sixteenths). The bass plays the one-bar riff on every bar, moved to
# the chord of that bar:  E E | E E | A A | E E | B A | E B (turnaround).
SPEED = 13
RIFF = [0, None, 0, None, 3, None, 0, None, 5, None, 0, None, 6, None, 5, None]  # e . e . g . e . a . e . bb . a .
E, A, B = 4, 9, 11  # e0, a0, b0


def bass(*roots):
    """The riff once per bar, transposed to each root."""
    return [(r + i, 1, 5, 0) if i is not None else (0, 0, 0, 0) for r in roots for i in RIFF]


BEAT = "K . H . S . H . K . K H S . H H " * 2
FILL = "K . H . S . H . K . K H S . H H K . H . S . S . S S S S S S S S"
# lead, two bars per pattern, following the chords
LEAD_1 = ("e3 - - . d3 e3 . b2 - - - . a2 - g2 . "      # E: falling call from the high e
          "e2 - . g2 - . a2 . bb2 - b2 - - - . .")       # E: bluesy climb bending bb up to b
LEAD_2 = ("g3 - e3 - d3 e3 . b2 - - - . d3 - e3 . "      # E: the answer
          "g3 - - . e3 - d3 - b2 - - - . . . .")
LEAD_3 = ("a3 - - . g3 a3 . e3 - - - . d3 - c3 . "      # A: the call moved to the IV
          "a2 - . c3 - . d3 . eb3 - e3 - - - . .")
LEAD_4 = ("e3 e3 e3 e3 d3 d3 d3 d3 b2 b2 b2 b2 a2 a2 b2 b2 "  # E: surf tremolo picking
          "d3 d3 d3 d3 b2 b2 a2 a2 g2 g2 e2 e2 e2 e2 . .")
LEAD_5 = ("f#3 - - - a3 - f#3 - d#3 - - - b2 - - . "    # B7
          "e3 - - - c#3 - a2 - g2 - - - a2 - - .")       # A7
LEAD_6 = ("e3 - - - b2 - g2 - e2 - - - . . . . "        # E: resolve
          "f#2 - a2 - b2 - d#3 - f#3 - - - . . . .")     # B7 turnaround, back to the top

SFX.update({
    25: ([(52, 0, 5, 0), (52, 0, 5, 0), (52, 0, 4, 0), (48, 0, 5, 0), (48, 0, 4, 0), (48, 0, 3, 5)], 8),  # lift arrives at your floor (ding-dong)
    26: ([(14, 3, 6, 3), (10, 6, 4, 5), (8, 6, 2, 5)], 4),  # landing in a shaft (survived)
    27: ([(16, 6, 3, 5), (12, 6, 1, 5)], 3),  # jump landing tap
})

SFX.update({
    16: (bass(E, E), SPEED),
    17: (bass(A, A), SPEED),
    18: (bass(B, A), SPEED),
    28: (bass(E, B), SPEED),
    19: (drums(BEAT), SPEED),
    20: (drums(FILL, fill=True), SPEED),
    21: (seq(LEAD_1, 4, 4, vib_long=True), SPEED),
    24: (seq(LEAD_2, 4, 4, vib_long=True), SPEED),
    23: (seq(LEAD_3, 4, 4, vib_long=True), SPEED),
    22: (seq(LEAD_4, 4, 4, trem=True), SPEED),
    29: (seq(LEAD_5, 4, 4, vib_long=True), SPEED),
    30: (seq(LEAD_6, 4, 4, vib_long=True), SPEED),
})

OFF = 0x40  # channel disabled (channel 3 is left free for sound effects)
# (flags, ch0, ch1, ch2, ch3); flags: 1 = loop start, 2 = loop end, 4 = stop
MUSIC = [
    (0, 16, 19, OFF, OFF),  # intro: the riff on E, bass + drums
    (1, 16, 19, 21, OFF),  # bars 1-2   E E   <- loop start
    (0, 16, 19, 24, OFF),  # bars 3-4   E E
    (0, 17, 19, 23, OFF),  # bars 5-6   A A
    (0, 16, 19, 22, OFF),  # bars 7-8   E E   (tremolo)
    (0, 18, 19, 29, OFF),  # bars 9-10  B A
    (2, 28, 20, 30, OFF),  # bars 11-12 E B   turnaround + fill -> loop end
]
