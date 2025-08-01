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
 * INT 14h AH=04h - comm_receive_with_timeout
 * Input:
 * - CX = Timeout, in frames
 * Output:
 * - AX = Character or status
 */
    .global comm_receive_with_timeout
comm_receive_with_timeout:
    push bx

    // Clear overrun, in case it occured before.
    in al, WS_UART_CTRL_PORT
    or al, WS_UART_CTRL_RX_OVERRUN_RESET
    out WS_UART_CTRL_PORT, al

    mov bh, (WS_UART_CTRL_RX_OVERRUN | WS_UART_CTRL_RX_READY)
    call __comm_wait_timeout
    test ah, ah
    jnz 8f

    // receive character
    xor ax, ax
    in al, WS_UART_DATA_PORT
    jmp 9f

8:
    // convert __comm_wait_timeout result to error code
    mov al, ah
    mov ah, 0x81

9:
    pop bx
    ret

