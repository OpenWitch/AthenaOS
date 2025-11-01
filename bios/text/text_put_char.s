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
 * INT 13h AH=04h - text_put_char
 * Input:
 * - BL = X position
 * - BH = Y position
 * - CX = character code
 * Output:
 *
 * TODO: accurate out of bounds handling in SJIS modes
 */
    .global text_put_char
text_put_char:
    pusha
    push ds
    push es
    push ss
    push ss
    pop ds
    pop es

    mov al, [text_screen]
    add bl, [text_wx]
    add bh, [text_wy]
    call __display_screen_at
    // DI = pointer to tile

    cmp byte ptr [text_mode], TEXT_MODE_ANK
    je text_put_char_ank

text_put_char_sjis:
    sub sp, 8
    mov dx, sp             // DS:DX = destination
    push [di]
    call text_get_fontdata
    // TODO: handle error code?

    pop bx
    // TODO: how does this handle tiles 512-1023?
    and bx, 0x1FF
    mov cx, 1              // CX = 1
    call font_set_monodata

    add sp, 8
    jmp text_put_char_end

text_put_char_ank:
    cmp cx, 0x80 // for characters outside of range, use "?"
    jb 1f
    mov cx, '?'
1:
    mov al, [text_color]
    shl ax, 9
    add cx, ax
    add cx, [text_base]
    mov [di], cx // [DI] = CX | (text_color << 9)

text_put_char_end:
    pop es
    pop ds
    popa
    ret
