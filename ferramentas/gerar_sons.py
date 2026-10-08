"""Gera, por síntese, as musiquinhas dos anúncios e o som do deslize.

Uso (precisa de Python 3 com numpy):  python ferramentas/gerar_sons.py jogo/sons
Sons feitos para o Confrontation (sem licença de terceiros)."""
import sys
import wave
import numpy as np

OUT = sys.argv[1]
SR = 44100


def note(name):
    names = {'C': -9, 'C#': -8, 'D': -7, 'D#': -6, 'E': -5, 'F': -4, 'F#': -3, 'G': -2, 'G#': -1, 'A': 0, 'A#': 1, 'B': 2}
    pitch, octave = name[:-1], int(name[-1])
    return 440.0 * 2 ** ((names[pitch] + 12 * (octave - 4)) / 12)


def env(n, attack=0.005, release=0.25, sustain=1.0):
    t = np.arange(n) / SR
    e = np.minimum(1.0, t / max(attack, 1e-4))
    rel_start = n / SR - release
    e = e * np.where(t > rel_start, np.clip((n / SR - t) / max(release, 1e-4), 0, 1), 1.0)
    return e * sustain


def bell(freq, dur, decay=4.0):
    t = np.arange(int(dur * SR)) / SR
    tone = (np.sin(2 * np.pi * freq * t) + 0.5 * np.sin(2 * np.pi * freq * 2.76 * t) * np.exp(-t * 6)
            + 0.25 * np.sin(2 * np.pi * freq * 5.4 * t) * np.exp(-t * 10))
    return tone * np.exp(-t * decay) * env(len(t), 0.002, 0.05)


def brass(freq, dur, bright=8):
    t = np.arange(int(dur * SR)) / SR
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5.5 * t) * np.minimum(1, t * 3)
    phase = 2 * np.pi * freq * np.cumsum(vib) / SR
    tone = sum(np.sin(k * phase) / k * np.exp(-k / bright) for k in range(1, 12))
    return tone * env(len(t), 0.02, min(0.15, dur * 0.4))


def drum(dur=0.25, pitch=90):
    t = np.arange(int(dur * SR)) / SR
    body = np.sin(2 * np.pi * pitch * t * np.exp(-t * 8)) * np.exp(-t * 14)
    noise = np.random.default_rng(1).uniform(-1, 1, len(t)) * np.exp(-t * 30) * 0.5
    return body + noise


def place(track, sound, at, gain=1.0):
    i = int(at * SR)
    end = min(len(track), i + len(sound))
    track[i:end] += sound[:end - i] * gain


def echo(x, delay=0.12, feedback=0.3, mix=0.25):
    d = int(delay * SR)
    y = x.copy()
    for k in range(1, 4):
        y[d * k:] += x[:-d * k] * (feedback ** k) * mix
    return y


def save(name, x, peak=0.8):
    x = x / max(np.max(np.abs(x)), 1e-6) * peak
    pcm = (x * 32767).astype(np.int16)
    with wave.open(f'{OUT}/{name}', 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print(name, '%.2fs' % (len(x) / SR))


# HEADSHOT: dois sinos rápidos e brilhantes
x = np.zeros(int(0.9 * SR))
place(x, bell(note('E6'), 0.6), 0.0)
place(x, bell(note('B6'), 0.8), 0.09)
save('anuncio_headshot.wav', echo(x), 0.7)

# DOUBLE KILL: arpejo de 3 notas + acorde curto
x = np.zeros(int(1.2 * SR))
for i, n in enumerate(['C5', 'E5', 'G5']):
    place(x, brass(note(n), 0.16), i * 0.1, 0.8)
for n in ['C5', 'E5', 'G5', 'C6']:
    place(x, brass(note(n), 0.55), 0.32, 0.45)
place(x, drum(), 0.32, 0.6)
save('anuncio_double.wav', echo(x))

# TRIPLE KILL: arpejo mais longo subindo + acorde
x = np.zeros(int(1.6 * SR))
for i, n in enumerate(['G4', 'C5', 'E5', 'G5', 'C6']):
    place(x, brass(note(n), 0.14), i * 0.08, 0.8)
for n in ['C5', 'E5', 'G5', 'C6', 'E6']:
    place(x, brass(note(n), 0.8), 0.42, 0.4)
place(x, drum(0.3, 80), 0.42, 0.7)
place(x, bell(note('C7'), 0.9, 3), 0.42, 0.25)
save('anuncio_triple.wav', echo(x))

# MULTI / QUADRA / ACE: fanfarra
x = np.zeros(int(2.4 * SR))
seq = [('G4', 0.0, 0.12), ('G4', 0.13, 0.12), ('G4', 0.26, 0.12), ('C5', 0.4, 0.3), ('E5', 0.72, 0.14), ('G5', 0.88, 0.14)]
for n, at, d in seq:
    place(x, brass(note(n), d + 0.05), at, 0.8)
for n in ['C5', 'E5', 'G5', 'C6', 'E6', 'G6']:
    place(x, brass(note(n), 1.2), 1.05, 0.35)
for at in [0.0, 0.4, 1.05]:
    place(x, drum(0.35, 70), at, 0.7)
place(x, bell(note('G6'), 1.2, 2.5), 1.05, 0.3)
save('anuncio_multi.wav', echo(x, 0.15, 0.35))

# SEQUÊNCIA (3, 5, 7, 10 sem morrer): acorde "poderoso" subindo
x = np.zeros(int(1.5 * SR))
for i, base in enumerate(['A4', 'C5', 'E5']):
    for interval in [1.0, 1.5]:
        place(x, brass(note(base) * interval, 0.18), i * 0.12, 0.6)
for n in ['E5', 'A5', 'C#6', 'E6']:
    place(x, brass(note(n), 0.8), 0.4, 0.4)
place(x, drum(0.3, 75), 0.0, 0.5)
place(x, drum(0.3, 75), 0.4, 0.7)
save('anuncio_sequencia.wav', echo(x))

# DESLIZE: "shhh" de atrito, ruído filtrado com começo forte e fim suave
n = int(0.6 * SR)
rng = np.random.default_rng(7)
noise = rng.uniform(-1, 1, n)
low = np.zeros(n)
a = 0.08
for i in range(1, n):
    low[i] = low[i - 1] + a * (noise[i] - low[i - 1])
grit = (noise - low) * 0.25 + low * 1.2
t = np.arange(n) / SR
shape = np.minimum(1, t / 0.03) * np.exp(-t * 3.2)
rough = 1 + 0.25 * np.sin(2 * np.pi * 23 * t) * rng.uniform(0.5, 1, n)
save('deslize.wav', grit * shape * rough, 0.6)
