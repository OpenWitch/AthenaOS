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

    // AL = IRQ to acknowledge
    // BX = IRQ offset
    // assumes AX, BX preserved
    .global irq_wrap_routine
irq_wrap_routine:
    push ax
    mov ax, ss:[bx]
    or ax, ss:[bx + 2]
    jz 1f

    push cx
    push dx
    push si
    push di
    push bp
    push ds
    push es

    mov ax, ss:[bx + 4]
    mov ds, ax
    ss lcall [bx]

    pop es
    pop ds
    pop bp
    pop di
    pop si
    pop dx
    pop cx
1:
    // Acknowledge interrupt
    pop ax
    out IO_HWINT_ACK, al
    ret

.macro irq_default_handler irq,idx
    push ax
    push bx
    mov al, \irq
    mov bx, offset (hw_irq_hook_table + (\idx * 8))
    call irq_wrap_routine
    pop bx
    pop ax
    iret
.endm

    .global hw_irq_serial_tx_handler
hw_irq_serial_tx_handler:
    irq_default_handler HWINT_SERIAL_TX,HWINT_IDX_SERIAL_TX

    .global hw_irq_key_handler
hw_irq_key_handler:
    irq_default_handler HWINT_KEY,HWINT_IDX_KEY

    .global hw_irq_cartridge_handler
hw_irq_cartridge_handler:
    irq_default_handler HWINT_CARTRIDGE,HWINT_IDX_CARTRIDGE

    .global hw_irq_serial_rx_handler
hw_irq_serial_rx_handler:
    irq_default_handler HWINT_SERIAL_RX,HWINT_IDX_SERIAL_RX

    .global hw_irq_line_handler
hw_irq_line_handler:
    irq_default_handler HWINT_LINE,HWINT_IDX_LINE

    .global hw_irq_vblank_timer_handler
hw_irq_vblank_timer_handler:
    irq_default_handler HWINT_VBLANK_TIMER,HWINT_IDX_VBLANK_TIMER

    .global hw_irq_hblank_timer_handler
hw_irq_hblank_timer_handler:
    irq_default_handler HWINT_HBLANK_TIMER,HWINT_IDX_HBLANK_TIMER

    .section ".bss"
    .global hw_irq_hook_table
hw_irq_hook_table:
.rept 64 /* 8 IRQs x 8 bytes */
    .byte 0
.endr
