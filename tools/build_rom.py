#!/usr/bin/env python3
#
# Copyright (c) 2023, 2024 Adrian "asie" Siekierka
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import argparse
import struct
import sys

parser = argparse.ArgumentParser(
    prog = 'build_rom',
    description = 'Concatenates .RAW images to a ROM file.'
)
parser.add_argument('-s', '--size')
parser.add_argument('output')
parser.add_argument('system')
parser.add_argument('soft')
parser.add_argument('files', nargs='*')

args = parser.parse_args()
system_data = None
soft_data = None
files = {}

with open(args.system, "rb") as fin:
    system_data = fin.read()
with open(args.soft, "rb") as fin:
    soft_data = fin.read()
for fn in args.files:
    with open(fn, "rb") as fin:
        files[fn] = fin.read()

if len(system_data) != 65536:
    raise Exception('The System image should be exactly 64 kilobytes')

rom_size = 768 * 1024
if len(files) == 0:
    rom_size = 512 * 1024
if args.size:
    rom_size = int(args.size) * 1024
rom_start = (1024 * 1024) - rom_size

with open(args.output, "wb") as fout:
    fout.write(bytes([0xFF] * (rom_size - (128 * 1024))))
    fout.write(bytes(soft_data))
    fout.write(bytes([0xFF] * ((64 * 1024) - len(soft_data))))
    fout.write(bytes(system_data))

    file_pos = len(args.files) * 64
    file_count = 0

    for fn in args.files:
        print(fn)
        data = files[fn]
        if data[0:4] == bytes("#!ws", "ascii"):
            file_data = data[128:]
            file_header = bytearray(data[64:128])
        else:
            raise Exception('Non-.fx files are not currently supported')

        file_len = (len(file_data) + 15) & (~15)
        file_segment = (file_pos + rom_start) >> 4

        file_header[40:44] = struct.pack('<HH', 0, file_segment)

        fout.seek(file_count * 64)
        fout.write(bytes(file_header))
        fout.seek(file_pos)
        fout.write(bytes(file_data))

        file_pos += file_len
        file_count += 1

    # write AthenaOS ROM filesystem footer
    if len(args.files) > 0:
        fout.seek(rom_size - (64 * 1024) - 32)
        fout.write(struct.pack('<HHHHHH', 0x5AA5, 1, rom_start >> 4, file_count, 0, 0))

    # write OS footer
    fout.seek(rom_size - (64 * 1024) - 16)
    fout.write(struct.pack('<BHHBH', 0xEA, 0x0000, 0xE000, 0x00, int((len(soft_data) + 127) / 128)))
