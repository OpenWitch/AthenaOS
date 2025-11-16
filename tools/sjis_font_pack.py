#!/usr/bin/env python3
#
# Copyright (c) 2023 Adrian "asie" Siekierka
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

from PIL import Image
import argparse
import struct
import sys

# [
#   uint16_t sjis_start; // Shift-JIS glyph start
#   uint16_t offset; // offset in bytes, relative to the point after this variable + 2
# ]...
# uint16_t sjis_start = 0xFFFF;
# [
#   uint8_t[8] glyph;
# ]...

parser = argparse.ArgumentParser(
    prog = 'sjis_font_pack',
    description = 'PNG to WonderWitch-format JIS font converter'
)
parser.add_argument('input')
parser.add_argument('output')
args = parser.parse_args()

jis_whitespace = {
    0x2121: True
}

# Read PNG glyph data.
im = Image.open(args.input).convert("RGBA")
glyph_width = int(im.size[0] / 8)
glyph_height = int(im.size[1] / 8)

glyphs = {}

for iy in range(0, glyph_height):
    cy = 0x21 + iy

    # convert from JIS-0208 (cx,cy) to Shift-JIS (sx,sy)
    # sx is the low byte, sy is the high byte
    if cy <= 94:
        sy = ((cy + 1) >> 1) + 112
    else:
        sy = ((cy + 1) >> 1) + 176

    for ix in range(0, glyph_width):
        cx = 0x21 + ix

        has_data = ((cx << 8) | cy) in jis_whitespace
        row_data = []
        for gy in range(0, 8):
            b = 0
            for gx in range(0, 8):
                pxl = im.getpixel((ix*8+gx, iy*8+gy))
                if pxl[0] < 128:
                    b = b | (0x80 >> gx)
            row_data.append(b)
            if b != 0:
                has_data = True

        if not has_data:
            continue

        if (cy & 1) == 1:
            sx = cx + 31 + int(cx / 96)
        else:
            sx = cx + 126

        glyph = {"index": (sy << 8) | sx, "data": row_data}
        glyphs[glyph["index"]] = glyph

# Run-length pack the glyphs.

glyphs_rl = []
curr_glyph = None

for i in range(min(glyphs.keys()), max(glyphs.keys()) + 1):
    if i in glyphs:
        glyph = glyphs[i]
        if curr_glyph is None:
            curr_glyph = {"index": i, "data": []}
            glyphs_rl.append(curr_glyph)
        curr_glyph["data"] += glyph["data"]
    else:
        curr_glyph = None

# Write glyph data.
with open(args.output, "wb") as fout:
    offset = 4 * len(glyphs_rl) + 2
    relative_header_offset = 0

    for row in glyphs_rl:
        relative_header_offset += 4
        fout.write(struct.pack("<HH", row["index"], offset - relative_header_offset))
        offset += len(row["data"])
    fout.write(struct.pack("<H", 0xFFFF))
    for row in glyphs_rl:
        fout.write(bytes(row["data"]))


