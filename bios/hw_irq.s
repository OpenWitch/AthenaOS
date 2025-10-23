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

    // BX = IRQ offset
    // clobbers AX, BX
    .global irq_wrap_routine
irq_wrap_routine:
    ss mov ax, [bx]
    ss or ax, [bx + 2]
    jz 1f

    push cx
    push dx
    push si
    push di
    push bp
    push ds
    push es

    ss mov ax, [bx + 4]
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
    ret

.macro irq_default_handler irq,idx
    push ax
    push bx
    mov bx, offset (hw_irq_hook_table + (\idx * 8))
    call irq_wrap_routine
    pop bx
    mov al, \irq
    out WS_INT_ACK_PORT, al
    pop ax
    iret
.endm

    .global hw_irq_serial_tx_handler
hw_irq_serial_tx_handler:
    irq_default_handler WS_INT_ENABLE_UART_TX,WS_INT_UART_TX

    .global hw_irq_key_handler
hw_irq_key_handler:
    irq_default_handler WS_INT_ENABLE_KEY_SCAN,WS_INT_KEY_SCAN

    .global hw_irq_cartridge_handler
hw_irq_cartridge_handler:
    irq_default_handler WS_INT_ENABLE_CARTRIDGE,WS_INT_CARTRIDGE

    .global hw_irq_serial_rx_handler
hw_irq_serial_rx_handler:
    irq_default_handler WS_INT_ENABLE_UART_RX,WS_INT_UART_RX

    .global hw_irq_line_handler
hw_irq_line_handler:
    irq_default_handler WS_INT_ENABLE_LINE_MATCH,WS_INT_LINE_MATCH

    .global hw_irq_vblank_timer_handler
hw_irq_vblank_timer_handler:
    irq_default_handler WS_INT_ENABLE_VBL_TIMER,WS_INT_VBL_TIMER

    .global hw_irq_hblank_timer_handler
hw_irq_hblank_timer_handler:
    irq_default_handler WS_INT_ENABLE_HBL_TIMER,WS_INT_HBL_TIMER

    .section ".bss"
    .global hw_irq_hook_table
hw_irq_hook_table:
.rept 64 /* 8 IRQs x 8 bytes */
    .byte 0
.endr
