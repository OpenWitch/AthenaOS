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
 * INT 13h AH=06h - text_put_substring
 * Input:
 * - BL = X position
 * - BH = Y position
 * - DS:DX = string
 * - CX = limit
 * Output:
 */
    .global text_put_substring
text_put_substring:
    push si
    push bx
    push cx
    push ax
    mov si, dx
1:
    // Load one character, two characters if >= 0x80 (for Shift-JIS)
    xor ax, ax
    lodsb
    test al, al
    jz 3f // == 0?
    cmp al, 0x80
    jb 2f // < 0x80?
    mov ah, al
    lodsb
2:
    push cx
    mov cx, ax
    call text_put_char
    pop cx
    inc bl
    loop 1b
3:
    pop ax
    pop cx
    pop bx
    pop si
    ret
