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

    // Input:
	// - AL = timer type (0 = HBlank, 1 = VBlank)
	// - BL = timer value (0 = disabled, 1 = enabled, 3 = autopreset)
	// Clobber: AL, BL, CL
__timer_set_type_irq:
	push bx
	mov cl, al
	shl cl, 1 // shift: 0 = HBlank, 2 = VBlank

	mov bh, 0xFC
	rol bh, cl // BH = shifted timer mask
	shl bl, cl // BL = shifted timer value

	// Apply timer value
	in al, WS_TIMER_CTRL_PORT
	and al, bh
	or al, bl
	out WS_TIMER_CTRL_PORT, al // AL = ((AL & BH) | BL)

	// Disable/enable interrupt
	mov bh, 0x7F
	ror bh, cl // BH = shifted IRQ mask
	in al, WS_INT_ENABLE_PORT
	and al, bh
	pop bx
	shl bl, 7
	shr bl, cl // BL = shifted IRQ value
	or al, bl
	out WS_INT_ENABLE_PORT, al // AL = ((AL & BH) | BL)

	ret

/**
 * INT 16h AH=07h - timer_enable
 * Input:
 * - AL = Timer (0 = HBlank, 1 = VBlank).
 * - BX = Timer configuration
 *   - bit 0 = 0 - one-shot, 1 - repeat
 * - CX = Timer counter reload value
 */
	.global timer_enable
timer_enable:
	// preserve AX-DX
	mov bp, ax
	push bx
	push cx
	push dx

	push bx // store timer configuration
	push cx // store reload time

	// disable timer
	xor bx, bx
	call __timer_set_type_irq

	// set reload preset
	mov ax, bp // retrieve timer ID
	shl al, 1
	xor dh, dh
	mov dl, al
	add dl, 0xA4

	pop ax  // retrieve reload time
	out dx, ax

	// enable timer
	pop bx  // retrieve timer configuration
	and bx, 1
	shl bx, 1
	or bl, 1
	
	mov ax, bp // retrieve timer ID
	call __timer_set_type_irq

	// restore DX-AX
	pop dx
	pop cx
	pop bx
	mov ax, bp
	ret

/**
 * INT 16h AH=08h - timer_disable
 * Input:
 * - AL = Timer (0 = HBlank, 1 = VBlank).
 */
	.global timer_disable
timer_disable:
	push ax
	push bx
	push cx
	xor bx, bx
	call __timer_set_type_irq
	pop cx
	pop bx
	pop ax
	ret
