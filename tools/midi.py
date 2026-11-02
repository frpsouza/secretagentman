"""MIDI previews of the pico-8 music in fontes/audio/audio.py (called by build.py).

Writes to fontes/audio/midi/:
  theme.mid   whole song (intro + loop played twice)
  bass.mid, drums.mid, lead.mid   one part each

A pico-8 note is a 16th note; at speed s it lasts s*183/22050 seconds.
Pico-8 pitch 33 is concert A (440 Hz) = midi 69, so midi = pitch + 36.
"""
import os
import struct

PPQ = 96
STEP = PPQ // 4  # ticks per pico-8 note (a 16th)
# music channel -> (name, midi channel, general midi program)
PARTS = {0: ("bass", 0, 33), 1: ("drums", 9, 0), 2: ("lead", 1, 26)}


def vlq(n):
    out = [n & 0x7F]
    n >>= 7
    while n:
        out.insert(0, (n & 0x7F) | 0x80)
        n >>= 7
    return bytes(out)


def track(events):
    """events: (tick, bytes) -> MTrk chunk."""
    data, now = b"", 0
    for tick, ev in sorted(events, key=lambda e: (e[0], e[1][0] & 0xF0 != 0x80)):
        data += vlq(tick - now) + ev
        now = tick
    data += b"\x00\xff\x2f\x00"
    return b"MTrk" + struct.pack(">I", len(data)) + data


def drum_key(pitch):
    return 36 if pitch < 30 else 38 if pitch < 50 else 42  # kick, snare, closed hat


def notes_of(sfx, drums):
    """Pico-8 notes -> (start step, length, midi key, velocity); held notes are merged."""
    out = []
    for i, (p, w, v, fx) in enumerate(sfx):
        if v == 0:
            continue
        key = drum_key(p) if drums else p + 36
        vel = int(v / 7 * 127)
        prev = out[-1] if out else None
        if not drums and prev and prev[0] + prev[1] == i and prev[2] == key and prev[3] == vel:
            out[-1] = (prev[0], prev[1] + 1, key, vel)  # '-' hold
        else:
            out.append((i, 1, key, vel))
    return out


def song(audio):
    order = list(range(len(audio.MUSIC)))
    loop = [i for i, m in enumerate(audio.MUSIC) if m[0] & 1][0]
    return order + order[loop:]  # intro, then the loop twice


def write(path, audio, parts):
    speed = audio.SPEED
    tempo = int(4 * speed * 183 / 22050 * 1e6)  # microseconds per quarter
    head = [(0, b"\xff\x51\x03" + tempo.to_bytes(3, "big"))]
    tracks = [track(head)]
    for chan in parts:
        name, mch, prog = PARTS[chan]
        ev = [(0, b"\xff\x03" + vlq(len(name)) + name.encode()), (0, bytes([0xC0 | mch, prog]))]
        for n, pat in enumerate(song(audio)):
            idx = audio.MUSIC[pat][1 + chan]
            if idx & 0x40 or idx not in audio.SFX:
                continue
            base = n * 32 * STEP
            for st, ln, key, vel in notes_of(audio.SFX[idx][0], chan == 1):
                t0 = base + st * STEP
                ev.append((t0, bytes([0x90 | mch, key, vel])))
                ev.append((t0 + ln * STEP - (2 if chan == 1 else 1), bytes([0x80 | mch, key, 0])))
        tracks.append(track(ev))
    with open(path, "wb") as f:
        f.write(b"MThd" + struct.pack(">IHHH", 6, 1, len(tracks), PPQ) + b"".join(tracks))


def export(audio, outdir):
    os.makedirs(outdir, exist_ok=True)
    write(os.path.join(outdir, "theme.mid"), audio, [0, 1, 2])
    for chan, (name, _, _) in PARTS.items():
        write(os.path.join(outdir, name + ".mid"), audio, [chan])
    return outdir
