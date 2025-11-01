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
 * INT 12h AH=08h - screen_get_char
 * Input:
 * - AL = screen ID
 * - BL = X position
 * - BH = Y position
 * - CL = width
 * - CH = height
 * - DS:DX = character buffer
 * Output:
 * - AX = If width or height == 0, the character at the location.
 */
    .global screen_get_char
screen_get_char:
    push bx
    push cx
    push dx
    push si
    push di
    push ds
    push es

    // DS:SI = source, ES:DI = destination
    push ss
    push ds
    pop es
    pop ds
    call __display_screen_at
    mov si, di
    mov di, dx

    // CL, CH = width, height
    test cl, cl
    jz 2f
    test ch, ch
    jz 2f

    cld
1:
    // copy row using MOVSW
    push cx
    push si
    xor ch, ch
    rep movsw
    pop si
    pop cx

    // advance to next column
    add si, 32 * 2
    dec ch
    jnz 1b
    jmp 3f

2:
    // read single character
    mov ax, [si]

3:
    pop es
    pop ds
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret
