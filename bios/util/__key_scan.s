/**
 * Copyright (c) 2023, 2024 Adrian "asie" Siekierka
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

	.arch	i186
	.code16
	.intel_syntax noprefix

#include "common.inc"

// Clobbers AL
// Returns keys held in CX
    .global __key_scan
__key_scan:
    mov al, 0x10
    out WS_KEY_SCAN_PORT, al
    daa
    in  al, WS_KEY_SCAN_PORT
    and al, 0x0F
    mov ch, al

    mov al, 0x20
    out WS_KEY_SCAN_PORT, al
    daa
    in  al, WS_KEY_SCAN_PORT
    shl al, 4
    mov cl, al

    mov al, 0x40
    out WS_KEY_SCAN_PORT, al
    daa
    in  al, WS_KEY_SCAN_PORT
    and al, 0x0F
    or  cl, al

    ret
