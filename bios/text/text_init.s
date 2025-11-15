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
 * INT 13h AH=00h - text_screen_init
 */
    .global text_screen_init
text_screen_init:
    pusha
    // Initialize screen from 0,0 to 28,18
    mov bx, ( 0 | ( 0 << 8))
    mov cx, (28 | (18 << 8))
    mov dx, (512 - SCREEN_TILE_COUNT)
    ss cmp byte ptr [text_mode], TEXT_MODE_ANK
    jne 1f
    mov dx, 512
    ss sub dx, [text_ank_count]
1:
    call text_window_init
    popa
    ret

/**
 * INT 13h AH=01h - text_window_init
 * Input:
 * - BL: Window X
 * - BH: Window Y
 * - CL: Window width
 * - CH: Window height
 * - DX: Text tile base
 */
    .global text_window_init
text_window_init:
    pusha
    push ds
    push es
    push ss
    pop ds

    mov [text_wx], bx
    mov [text_ww], cx
    mov [text_base], dx

    // Init tiles
    cmp byte ptr [text_mode], TEXT_MODE_ANK
    je __text_window_init_ank

__text_window_init_sjis:
    // memset(0x2000 + (text_base << 4), 0, window_width * window_height * sizeof(ws_tile_t));
    mov di, [text_base]
    shl di, 4
    add di, 0x2000    // DI = 0x2000 + (text_base << 4)
    mov ax, [text_ww]
    mov cl, ah
    mul cl
    shl ax, 3
    mov cx, ax        // CX = ((text_ww * text_wh) * 16) / 2
    xor ax, ax

    push ss
    pop es

    cld
    rep stosw
    jmp __text_window_init_end

__text_window_init_ank:
    // font_set_monodata(text_base, 128, font_ank);
    mov bx, dx // assumption: DX unchanged
    ss mov cx, [text_ank_count]
    ss lds dx, [text_ank_data]
    ss cmp byte ptr [text_ank_color], 0
    push offset __text_window_init_end
    jnz font_set_colordata
    jmp font_set_monodata

__text_window_init_end:
    // Clear screen
    call __text_window_clear
    pop es
    pop ds
    popa
    ret
