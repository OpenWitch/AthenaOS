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
 * INT 14h AH=07h - comm_receive_block
 * Input:
 * - CX = Length, in bytes
 * - DS:DX = Input buffer
 * Output:
 * - AX = Status
 * - DX = Number of bytes received
 */
    .global comm_receive_block
comm_receive_block:
    push cx
    push dx
    push di
    push es
    push ds
    pop es
    mov di, dx

    // check for CX == 0
    xor ax, ax
    test cx, cx
    jz 9f

    mov dx, ax // DX = 0

1:
    call comm_receive_char
    test ah, ah
    jnz 9f // if error, return error

    stosb // write received character
    inc dx
    loop 1b

9:
    pop es
    pop di
    pop dx
    pop cx
    ret

