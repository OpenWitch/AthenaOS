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
 * INT 15h AH=00h - sound_init
 * Input: -
 * Output: -
 *
 * Initializes the sound system.
 */
	.global sound_init
sound_init:
	pusha
	push es

	// clear sound channel/output registers
	xor ax, ax
	out IO_SND_CH_CTRL, ax

	// clear wave table
	push ss
	pop es

	mov di, MEM_WAVETABLE
	mov cx, 32
	cld
	rep stosw

	// configure wavetable base
	mov al, (MEM_WAVETABLE >> 6)
	out IO_SND_WAVE_BASE, al

	// clear all other sound ports
	xor ax, ax
	out 0x80, ax
	out 0x82, ax
	out 0x84, ax
	out 0x86, ax
	out 0x88, ax
	out 0x8A, ax
	out 0x8C, ax
	out 0x8E, al
	out 0x94, al

	pop es
	popa
	ret
