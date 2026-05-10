#!/usr/bin/env python3
# Convert a raw binary to Verilog $readmemh word-hex format (one 32-bit LE word per line).
import sys

with open(sys.argv[1], 'rb') as f:
    data = f.read()

while len(data) % 4:
    data += b'\x00'

for i in range(0, len(data), 4):
    print(f'{int.from_bytes(data[i:i+4], "little"):08x}')
