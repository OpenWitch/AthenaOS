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

	.section .start, "ax"
	.global _start
_start:
	cld

	// set correct bank for data/bss initialization
	mov al, 0x03
	out 0xC1, al

	// prepare ES for data/BSS
	// stack pointer configured by BIOS
	push 0x1000
	pop es

	// initialize data/BSS
	push cs
	pop ds
	mov si, offset "__text_end"
	mov di, offset "__data_start"
	mov cx, offset "__data_length_words"
	rep movsw
	mov cx, offset "__bss_length_words"
	xor ax, ax
	rep stosw

	// initialize DS
	push es
	pop ds

	// jump to main
	call main

	// exit BIOS
	int 0x10
