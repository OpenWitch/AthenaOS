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
	jnz __bank_fill_block_flash_ram
	
	// check if we can write buffered:
	// length needs to be <= 256
	cmp cx, 256
	ja __bwb_write_slow

	// + addresses must fit within one 512-byte block
	mov ax, di
	add ax, cx
	dec ax
	xor ax, di
	and ax, 0xFE00
	jnz __bwb_write_slow

__bwb_write_fast:
	// start write
	dec cx
	mov byte ptr es:[di], 0x25
	mov byte ptr es:[di], cl

	shr cx, 1
	.balign 2, 0x90
	rep movsw
	jnc 1f
	movsb
1:
	movsb

	// confirm write
	mov byte ptr es:[di], 0x29

	// wait for confirmation
	// CX is 0, so set it to 1
	inc cx
	jmp 3f

__bwb_write_slow:
1:
	mov byte ptr es:[di], 0xA0
	movsb
3:
	// wait for confirmation
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
	mov byte ptr es:[di], 0x00
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
	jmp 9b
    
    .global __bank_write_fill_block_flash_ram_size
__bank_write_fill_block_flash_ram_size = . - __bank_write_fill_block_flash_ram
