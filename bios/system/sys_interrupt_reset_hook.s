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
 * INT 17h AH=01h - sys_interrupt_reset_hook
 * Input:
 * - AL = Interrupt index.
 * - DS:BX = Pointer to old vector (write)
 */
    .global sys_interrupt_reset_hook
sys_interrupt_reset_hook:
    // If pointer == 0, clear instead
    test bx, bx
    jz 1f

    // Set interrupt hook to DS:BX
    push bx
    push dx
    mov dx, bx
    xor bx, bx
    call sys_interrupt_set_hook
    pop dx
    pop bx
    ret

1:
    // Disable interrupt in mask
    push ax
    mov cl, al
    mov al, 1
    shl al, cl
    not al
    mov cl, al
#ifdef ATHENA_FLAVOR_nileswan
    test cl, 0x9
    jz 1f
    ss and [nile_serial_state], cl
1:
#endif
    in al, WS_INT_ENABLE_PORT
    and al, cl
    or al, BIOS_REQUIRED_IRQ_MASK
    out WS_INT_ENABLE_PORT, al
    pop ax

    // Clear interrupt hook
    push ax
    // BP = ((AX - 0x100) << 3) + hw_irq_hook_table
    shl ax, 3
    mov bp, offset (hw_irq_hook_table - 0x0800)
    add bp, ax
    xor ax, ax
    mov [bp], ax
    mov [bp+2], ax
    mov [bp+4], ax
    mov [bp+6], ax
    pop ax

    ret
