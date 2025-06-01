#!/usr/bin/env python3

import math
import struct
import sys

i16 = struct.Struct('<h')
i32 = struct.Struct('<l')

S = 10            # Duration in seconds
FREQ = 440        # Frequency in Hz (A4)
SAMPLE_RATE = 48000

def main():
    raw = b''.join(collect(sample(FREQ)))
    with open('tones.wav', 'wb') as f:
        for bs in wave_file(raw):
            f.write(bs)
    with open('tones.hex', 'wb') as f:
        for bs in hex_file(raw):
            f.write(bs)

def sample(f):
    for t in range(S * SAMPLE_RATE):
        val = math.sin(math.tau * t / SAMPLE_RATE * f)
        yield val  # Mono signal, used for both L and R

def collect(mono):
    for s in mono:
        packed = i16.pack(int(s * 0x7FFF))  # Max amplitude
        yield packed  # Left
        yield packed  # Right (duplicate for stereo)

def wave_file(raw):
    yield b'RIFF'
    yield i32.pack(len(raw) + 36)
    yield b'WAVE'

    yield b'fmt '
    yield i32.pack(16)
    yield i16.pack(1)          # PCM format
    yield i16.pack(2)          # 2 channels
    yield i32.pack(SAMPLE_RATE)
    yield i32.pack(SAMPLE_RATE * 4)  # byte rate (48kHz * 2ch * 2bytes)
    yield i16.pack(4)          # block align
    yield i16.pack(16)         # bits per sample

    yield b'data'
    yield i32.pack(len(raw))
    yield raw

def hex_file(raw):
    for i in range(0, len(raw), 32):
        bs = bytes(hex_record(i >> 2, raw[i:i+32]))
        cs = -sum(bs) & 0xFF
        yield f':{bs.hex()}{cs:02x}\n'.encode()
    yield b':00000001FF\n'

def hex_record(addr, data):
    yield len(data) & 0xFF      # byte count
    yield (addr >> 8) & 0xFF    # address MSB
    yield addr & 0xFF           # address LSB
    yield 0                     # record type
    for b in data:
        yield b & 0xFF          # ensure valid byte


if __name__ == '__main__':
    sys.exit(main())
