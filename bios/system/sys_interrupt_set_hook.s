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
 * INT 17h AH=00h - sys_interrupt_set_hook
 * Input:
 * - AL = Interrupt index.
 * - DS:BX = Pointer to new vector (read)
 * - DS:DX = Pointer to old vector (write)
 */
    .global sys_interrupt_set_hook
sys_interrupt_set_hook:
    push ax
    push cx
    push si
    push di
    push ds
    push es

    // Enable interrupt in mask
    push ax
    mov cl, al
    mov al, 1
    shl al, cl
    mov cl, al
#ifdef ATHENA_FLAVOR_nileswan
    test cl, 0x9
    jz 1f
    ss or [nile_serial_state], cl
1:
#endif
    in al, WS_INT_ENABLE_PORT
    or al, cl
    out WS_INT_ENABLE_PORT, al
    pop ax

    // AH:AL = 00nn
    shl ax, 3
    add ax, offset hw_irq_hook_table

    // IRQ hook table -> old vector
    push ss
    push ds
    pop es
    pop ds
    // if old vector = 0, skip
    test dx, dx
    jz 1f
    // DS = BIOS, ES = caller
    mov si, ax
    mov di, dx
    mov cx, 4
    rep movsw
1:

    // new vector -> IRQ hook table
    push es
    push ds
    pop es
    pop ds
    // DS = caller, ES = BIOS
    mov si, bx
    mov di, ax
    mov cx, 4
    rep movsw

    pop es
    pop ds
    pop di
    pop si
    pop cx
    pop ax
    ret
