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
#include "bank/bank_macros.inc"

/**
 * Input:
 * - BX = bank ID (8000 ~ FFFF)
 */
	.section ".text"
    .global __bank_erase_flash_ram
__bank_erase_flash_ram:
	mov ax, 0x1000
	mov ds, ax

	mov bx, 0xAAA
	mov si, 0x555

	mov byte ptr [bx], 0xAA
	mov byte ptr [si], 0x55
	mov byte ptr [bx], 0x80
	mov byte ptr [bx], 0xAA
	mov byte ptr [si], 0x55
	xor bx, bx
	mov byte ptr [bx], 0x30

1:
	nop
	nop
	nop
	mov al, byte [bx]
	nop
	nop
	nop
	cmp al, byte [bx] // DQ2 and/or DQ6 toggles if status register
	jne 1b
9:
	retf
    
    .global __bank_erase_flash_ram_size
__bank_erase_flash_ram_size = . - __bank_erase_flash_ram
