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

	// Input: AL = screen ID
	// Output: DI = VRAM location
	// Clobber: AX
	.section ".text.__display_screen_location", "ax"
	.global __display_screen_location
__display_screen_location:
	push cx

	add al, al
	add al, al
	mov cl, 11
	sub cl, al // CL = 11 (SCREEN1), 7 (SCREEN2)

	in al, WS_SCR_BASE_PORT
	shl ax, cl
	and ax, 0x7800
	mov di, ax

	pop cx
	ret

	// Input: AL = screen ID, BL = X, BH = Y
	// Output: DI = VRAM location
	// Clobber: AX, BX
	.section ".text.__display_screen_at", "ax"
	.global __display_screen_at
__display_screen_at:
	push cx

	add al, al
	add al, al
	mov cl, 11
	sub cl, al // CL = 11 (SCREEN1), 7 (SCREEN2)

	in al, WS_SCR_BASE_PORT
	shl ax, cl
	and ax, 0x7800
	mov di, ax

	pop cx

	push bx
	and bx, 0x001F
	add di, bx
	add di, bx // * 2
	pop bx
	and bx, 0x1F00
	shr bx, 1
	shr bx, 1  // (bh >> 2) == ((bx >> 8) << 6)
	add di, bx

	ret

	// Output: DI = sprite location
	// Clobber: AX
	.section ".text.__display_sprite_location", "ax"
	.global __display_sprite_location
__display_sprite_location:
	in al, WS_SPR_BASE_PORT
	shl ax, 9
	and ah, 0x7E
	mov di, ax
	ret

	// Input: BX = sprite ID
	// Output: DI = sprite location
	// Clobber: AX
	.section ".text.__display_sprite_at", "ax"
	.global __display_sprite_at
__display_sprite_at:
	mov di, bx
	add di, di
	add di, di

	in al, WS_SPR_BASE_PORT
	shl ax, 9
	and ah, 0x7E
	add di, ax
	ret
