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
 * INT 14h AH=02h - comm_send_char
 * Input:
 * - BL = Character
 * Output:
 * - AX = Status
 */
    .global comm_send_char
comm_send_char:
    push bx
    push cx

    mov bh, (WS_UART_CTRL_TX_READY)
    ss mov cx, [comm_send_timeout]
    call __comm_wait_timeout
    test ah, ah
    jnz 8f

    // send character
    mov al, bl
    out WS_UART_DATA_PORT, al

    // return success code
    xor ax, ax
    jmp 9f

8:
    // convert __comm_wait_timeout result to error code
    mov al, ah
    mov ah, 0x81

9:
    pop cx
    pop bx
    ret

