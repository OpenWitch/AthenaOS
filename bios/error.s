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


	.section ".text.error_handle", "ax"
error_handle_reg_names_row1:
	.ascii "FLAXCXDXBX"
error_handle_reg_names_row2:
	.ascii "BPSIDIDSES"

// Print register row (names)
error_handle_print_reg_names_row:
	mov cx, 2
	mov ax, 0x0605
1:
	push ax
	int 0x13
	pop ax
	add bl, 5
	add dx, 2
	dec al
	jnz 1b
	ret

// Print register row (numbers)
error_handle_print_num_row:
	add bp, 10
	mov bl, 2
1:
	sub bp, 2
	mov dx, [bp]
	push ax
	int 0x13
	pop ax
	add bl, 5
	cmp bl, 22
	jbe 1b
	ret

#define ERROR_HANDLE_USER_STACK(n) ((n) + 24)

// Prepare error handler screen, print registers
error_handle_start:
	pushf
	cli
	pusha
	push ds
	push es
	mov bp, sp
	// +0	ES
	// +2	DS
	// +4	DI
	// +6	SI
	// +8	BP
	// +10	SP
	// +12	BX
	// +14	DX
	// +16	CX
	// +18	AX
	// +20  FLAGS
	// +22	[error_handle_start return]
	// +24	... user space ...

	// Disable interrupts
	xor ax, ax
	out WS_INT_ENABLE_PORT, al

	// Initialize text screen
	mov ax, 0x2100 // Set screen 1 location to 0x3000
	mov bl, (0x3000 >> 11)
	int 0x12
	mov ax, 0x9BDF // Initialize LCD shade LUT
	out WS_LCD_SHADE_45_PORT, ax
	mov ax, 0x0246
	out WS_LCD_SHADE_01_PORT, ax
	mov ax, 0x0257 // Set palette 0 colors
	out WS_SCR_PAL_0_PORT, ax
	mov ax, 0x0200 // Set mode to 0 (ASCII)
	xor bx, bx
	int 0x13
	mov ax, 0x0900 // Set palette to 0
	int 0x13
	mov ax, 0x0E00 // Set screen to 0
	int 0x13
	xor ax, ax // Initialize screen
	int 0x13

	in al, WS_SYSTEM_CTRL_COLOR_PORT
	and al, 0x9F
	out WS_SYSTEM_CTRL_COLOR_PORT, al
	ss mov word ptr [0xFE00], 0x0FFF
	ss mov word ptr [0xFE06], 0x0000

	// Print register state
	mov ah, 0x07
	mov cx, 0x0304
	mov bh, 5
	call error_handle_print_num_row
	add bp, 12
	mov bh, 4
	call error_handle_print_num_row
	sub bp, 12

	// Set DS to CS (for string printing)
	push cs
	pop ds

	// Print register names
	mov dx, offset error_handle_reg_names_row1
	mov bx, 0x0302
	call error_handle_print_reg_names_row
	mov dx, offset error_handle_reg_names_row2
	mov bx, 0x0604
	call error_handle_print_reg_names_row

	add sp, 22
	ret

error_handle_end:
	mov ah, 0x00 // Show display
	mov bx, 0x0001
	int 0x12

	hlt
1:	jmp 1b

	.section ".text.error_handle_generic", "ax"
s_generic_error:
	.asciz "Generic error"

#ifdef BIOS_CATCH_IRQ_ERRORS
	.global error_handle_irq
error_handle_irq:
#endif
	.global error_handle_generic
error_handle_generic:
	call error_handle_start

	// Print generic error message
	mov bx, 0x0101
	mov dx, offset s_generic_error
	mov ah, 0x05
	int 0x13

	jmp error_handle_end

	.section ".text.error_handle_write_to_rom", "ax"
s_cannot_write_to_rom:
	.asciz "Cannot write to ROM"

	.global error_handle_write_to_rom
error_handle_write_to_rom:
	call error_handle_start

	// Print generic error message
	mov bx, 0x0101
	mov dx, offset s_cannot_write_to_rom
	mov ah, 0x05
	int 0x13

	jmp error_handle_end

	.section ".text.error_handle_irq", "ax"
s_unimplemented_int:
//	        123456789012345678901
	.asciz "Unimplemented INT   h"

error_handle_irq:
	call error_handle_start

	// Print unimplemented INT message
	mov bx, 0x0101
	mov dx, offset s_unimplemented_int
	mov ah, 0x05
	int 0x13
	
	mov bl, 19
	mov cx, 0x0302
	mov dx, [bp + ERROR_HANDLE_USER_STACK(0)]
	mov ah, 0x07
	int 0x13
	
	jmp error_handle_end

.irp i,17,18,19,20,21,22,23,24
	.section ".text.error_handle_irq\i\()", "ax"
	.global error_handle_irq\i
error_handle_irq\i\():
	push offset \i
	jmp error_handle_irq
.endr
