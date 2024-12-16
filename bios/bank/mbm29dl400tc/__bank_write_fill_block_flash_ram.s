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
 * - AH = 0 if write, 1 if fill
 * - AL = fill value
 * - BX = bank ID (8000 ~ FFFF)
 * - CX = bytes to write
 * - DX = address within bank
 * - DS:SI = input buffer
 */
	.section ".text"
    .global __bank_write_fill_block_flash_ram
__bank_write_fill_block_flash_ram:
	mov di, dx

	mov bx, 0xAAA

	mov byte ptr es:[bx], 0xAA
	mov byte ptr es:[0x555], 0x55
	mov byte ptr es:[bx], 0x20

	cld
	
	test ah, ah
	jz __bank_write_block_flash_ram
	call __bank_fill_block_flash_ram
	jmp 9f
	
__bank_write_block_flash_ram:
1:
	mov byte ptr es:[di], 0xA0
2:
	movsb
3:
	nop
	nop
	mov al, byte ptr es:[di]
	nop
	nop
	cmp al, byte ptr es:[di]
	jne 3b
	loop 1b

9:
	mov byte ptr es:[di], 0x90
	mov byte ptr es:[di], 0xF0
	retf

__bank_fill_block_flash_ram:
1:
	mov byte ptr es:[di], 0xA0
2:
	stosb
3:
	nop
	nop
	mov ah, byte ptr es:[di]
	nop
	nop
	cmp ah, byte ptr es:[di]
	jne 3b
	loop 1b
	ret
    
    .global __bank_write_fill_block_flash_ram_size
__bank_write_fill_block_flash_ram_size = . - __bank_write_fill_block_flash_ram
