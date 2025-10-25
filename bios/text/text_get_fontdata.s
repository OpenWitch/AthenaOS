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
 * INT 13h AH=0Dh - text_get_fontdata
 * Input:
 * - CX = Character code
 * - DS:DX = Output buffer (8 bytes)
 */
    .global text_get_fontdata
text_get_fontdata:
    push bx
    push cx
    push dx
    push si
    push di
    push ds
    push es

    // CX => AX
    // DS:DX => ES:DI
    // CS => DS
    mov ax, cx
    push ds
    push cs
    pop ds
    pop es
    mov di, dx

    ss cmp byte ptr [text_mode], 1
    ja .no_ascii
    cmp ax, 0x0080
    jb .ascii
.no_ascii:
    cmp ax, 0x80
    jae .no_table
    cmp ax, 0x20
    jb .no_table
    
    // AX = text_ank_sjis_table[AX - 0x20]
    xchg bx, ax
    add bx, bx
    cs mov bx, [bx + text_ank_sjis_table - 0x40]
    xchg bx, ax

.no_table:
    ss lcall offset text_sjis_handler
    mov ax, 0
    jnc .sjis_continue
.no_sjis:
    mov ax, 0x8000
    jmp .finish

.sjis_continue:
    mov ds, cx

.copy:
    cld
    // copy DS:SI => ES:DI
    movsw
    movsw
    movsw
    movsw

.finish:
    pop es
    pop ds
    pop di
    pop si
    pop dx
    pop cx
    pop bx

    ret

.ascii:
    mov si, offset font_ank
    shl ax, 3
    add si, ax

    xor ax, ax
    jmp .copy

    // input: AX - Shift-JIS character code
    // output: CX:SI - font data location
    // output: carry - set if no data found
    .global text_sjis_default_font_handler
text_sjis_default_font_handler:
    push bx
    push dx
    push ds

    mov si, offset font_sjis
    push si
    mov dx, ax

.loop:
    mov bx, [si]    // BX - start char code
    cmp bx, 0xFFFF
    je .not_found
    add si, 4

    cmp dx, [si]     // end char code?
    jae .loop        // if searched >= end, load next value
                        // ... if searched < end
    cmp dx, bx       // start char code?
    jb .not_found    // if searched < begin, it's not here

    sub dx, bx       // DX = ((character code - start char code) * 3) + offset
    shl dx, 3
    add dx, [si - 2] // + offset
    cmp dx, [si + 2] // compare to next offset
    jae .not_found   // address out of range

    mov cx, cs
    pop si
    add si, dx       // SI = char data start + DX

text_sjis_default_font_handler_finish:
    pop ds
    pop dx
    pop bx
    retf

.not_found:
    pop si
    stc
    jmp text_sjis_default_font_handler_finish
