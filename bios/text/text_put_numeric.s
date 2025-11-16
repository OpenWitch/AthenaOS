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

// Scary...

#define FLAG_HEX        0x01
#define FLAG_PAD_ZEROES 0x02
#define FLAG_ALIGN_LEFT 0x04
#define FLAG_SIGNED     0x08
#define FLAG_DS_BX      0x80
#define NUMBER_BUFFER_SIZE 8

text_num_table:
	.byte '0', '1', '2', '3', '4', '5', '6' ,'7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'

__tpn_put:
	test ch, FLAG_DS_BX
	jz 1f
	// write to DS:BX
	mov [bx], al
	jmp 2f
1:
	// write to display
	push cx
	mov cx, ax
	call text_put_char
	pop cx
2:
	inc bx
	ret

/**
 * INT 13h AH=07h - text_put_numeric
 * Input:
 * - BL = X position
 * - BH = Y position
 * - CL = width
 * - CH = flags:
 *   - bit 0: output in hexademical
 *   - bit 1: pad with zeroes instead of spaces
 *   - bit 2: align to left instead of right  
 *   - bit 3: treat number as signed instead of unsigned
 *   - bit 7: use DS:SI as output buffer instead of screen
 * - DX = number
 * - DS:BX = buffer, optional
 * Output:
 */
	.global text_put_numeric
text_put_numeric:
    test cl, cl
    jz 9f

	test ch, FLAG_HEX
	jz 1f
	and ch, ~(FLAG_ALIGN_LEFT | FLAG_SIGNED)
	or ch, (FLAG_PAD_ZEROES)
1:
	// Allocate stack space
	push bx
	push cx
	push dx
	push si
	push di
	push bp
	mov bp, sp
	sub sp, NUMBER_BUFFER_SIZE

	// Handle signed flag
	// After this, FLAG_SIGNED reflects if we should add the '-' character,
	// and DX is an unsigned number
	test ch, FLAG_SIGNED
	jz __tpn_no_signed
	test dh, 0x80
	jz __tpn_number_unsigned
__tpn_number_signed:
	// convert to unsigned - we'll re-add the sign later
	neg dx
	jmp __tpn_no_signed
__tpn_number_unsigned:
	and ch, ~FLAG_SIGNED
__tpn_no_signed:

	// Write number to buffer
	mov di, bp // DI = end of number buffer
	mov ax, dx // AX = number
	xor dx, dx
__tpn_buffer_number_loop:
	test ch, FLAG_HEX
	jz __tpn_buffer_number_div_dec
__tpn_buffer_number_div_hex:
	// Extract hex digit
	mov dl, al
	and dl, 0x0F
	shr ax, 4
	jmp __tpn_buffer_number_div_end
__tpn_buffer_number_div_dec:
	// Extract decimal digit
	mov si, 10 // SI = divisor used by decimal extraction
	xor dx, dx
	div si
__tpn_buffer_number_div_end:
	// DH = 0
	// DL = number % n
	// AX = number / n
	mov si, dx
	dec bp // BP = (eventually) start of number buffer
	// Write character to number buffer
	cs mov dl, [text_num_table + si]
	mov [bp], dl
	test ax, ax
	jnz __tpn_buffer_number_loop

	// Add '-' character
	test ch, FLAG_SIGNED
	jz 5f
	dec bp
	mov byte ptr [bp], '-'
5:

	// DX = actual string length, BP = string start
	sub di, bp
	mov dx, di

	// AX = written byte count
	// (always max(width, actual string length)
	mov ax, dx
	cmp al, cl
	ja 5f
	xor ax, ax
	mov al, cl
5:
	push ax

	// Handle alignment
	test ch, FLAG_ALIGN_LEFT // Is left-aligned? (no alignment)
	jnz __tpn_align_end
	cmp cl, dl // Is width <= string length?
	jbe __tpn_align_end // (always true if width == 0)

	// CL = bytes to pad
	sub cl, dl
	push ax
	// AL = padding character
	test ch, FLAG_PAD_ZEROES
	mov al, ' '
	jz 5f
4:
	mov al, '0'
5:
	call __tpn_put
	dec cl
	jnz 5b
	pop ax
__tpn_align_end:

__tpn_write_loop:
	// BP = first character to write, DL = characters to write
	mov al, [bp]
	call __tpn_put
	inc bp
	dec dl
	jnz __tpn_write_loop

	// Write NUL character
	test ch, FLAG_DS_BX
	jz 5f
	mov byte ptr [bx], 0
5:

	pop ax
	add sp, NUMBER_BUFFER_SIZE

	pop bp
	pop di
	pop si
	pop dx
	pop cx
	pop bx
9:
	ret
