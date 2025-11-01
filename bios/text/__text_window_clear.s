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


    .global __text_window_clear
__text_window_clear:
    pusha
    push ds
    push es
    push ss
    push ss
    pop ds
    pop es

    cmp byte ptr [text_mode], 0
    je __text_window_clear_ank
__text_window_clear_sjis:
    mov si, 1
    jmp __text_window_clear_loop
    
__text_window_clear_ank:
    mov si, 0
    
    // SI = increment value
__text_window_clear_loop:
    // DI (temporary) = value to set on screen
    mov di, [text_base]
    mov al, [text_color]
    shl ax, 9
    add di, ax
    // BL = X, BH = Y
    mov bx, [text_wx]
    push di
    // ES:DI = location to write to
    mov al, [text_screen]
    call __display_screen_at
    // AX = value to set on screen
    pop ax
    // DX = height counter
    xor dx, dx
    mov dl, [text_wh]
2:
    push di
    // CX = width counter
    xor cx, cx
    mov cl, [text_ww]
1:
    stosw
    add ax, si
    loop 1b
    pop di
    add di, 64
    dec dx
    jnz 2b

__text_window_clear_end:
    pop es
    pop ds
    popa
    ret
