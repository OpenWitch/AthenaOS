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

#include "../common.inc"

/**
 * INT 12h AH=07h - screen_set_char
 * Input:
 * - AL = screen ID
 * - BL = X position
 * - BH = Y position
 * - CL = width
 * - CH = height
 * - DS:DX = character buffer
 */
    .global screen_set_char
screen_set_char:
    pusha
    push es

    // ES:DI = destination
    push ss
    pop es
    call __display_screen_at

    // DS:SI = source
    mov si, dx

    // CL, CH = width, height
    test cl, cl
    jz 2f
    test ch, ch
    jz 2f

    cld
1:
    // copy row using MOVSW
    push cx
    push di
    xor ch, ch
    rep movsw
    pop di
    pop cx

    // advance to next column
    add di, 32 * 2
    dec ch
    jnz 1b

2:
    pop es
    popa
    ret
