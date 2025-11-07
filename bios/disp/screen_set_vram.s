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

/**
 * INT 12h AH=21h - screen_set_vram
 * Input:
 * - AL = screen ID (0, 1)
 * - BL = VRAM location >> 11
 * Output:
 */
    .global screen_set_vram
screen_set_vram:
    pusha

#ifdef MEM_PTR_SCR1
    push bx
    push ax
#endif
    // Configure I/O port
    mov cl, al
    shl cl, 2  // CL = 0 (SCREEN1), 4 (SCREEN2)
    mov al, 0xF0
    rol al, cl // AL = 0xF0 (SCREEN1), 0x0F (SCREEN2)
    and bl, 0xF
    shl bl, cl // BL = address (shifted)
    mov cl, al // CL = inverted mask

    in al, WS_SCR_BASE_PORT
    and al, cl
    or al, bl
    out WS_SCR_BASE_PORT, al

#ifdef MEM_PTR_SCR1
    // Configure memory
    pop bx
    pop ax
    shl ax, 11
    add bx, bx // 0x4200, 0x4202 -> 0x232, 0x234
    ss mov word ptr [bx + (0xBE00 + MEM_PTR_SCR1)], ax
#endif

    popa
    ret
