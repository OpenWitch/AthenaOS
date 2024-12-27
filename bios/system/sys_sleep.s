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
 * INT 17h AH=04h - sys_sleep
 * Input:
 * Output:
 */
	.global sys_sleep
sys_sleep:
    pusha

    push ds
    push ss
    pop ds

    // BL = old interrupt mask
    in al, IO_HWINT_ENABLE
    mov bl, al

    // Sleep until VBlank
    // TODO: Is this necessary?
    mov al, HWINT_VBLANK
    // out IO_HWINT_ACK, al
    out IO_HWINT_ENABLE, al
    hlt
    nop
    // out IO_HWINT_ACK, al

    // Turn off LCD panel
    in al, IO_LCD_CTRL
    // BH = old LCD control
    mov bh, al
    or al, LCD_SLEEP_MASK
    out IO_LCD_CTRL, al

    // Sleep given provided mask
    mov al, [sys_keepalive_int]

    // out IO_HWINT_ACK, al
    out IO_HWINT_ENABLE, al
1:
    hlt
    nop
    // out IO_HWINT_ACK, al

    call __key_scan
    mov ax, cx
    test ax, ax
    jz 1b
    and ax, [sys_awake_key]
    cmp ax, [sys_awake_key]
    jne 1b

    // Sleep until VBlank
    // TODO: Is this necessary?
    mov al, HWINT_VBLANK
    // out IO_HWINT_ACK, al
    out IO_HWINT_ENABLE, al
    hlt
    nop
    // out IO_HWINT_ACK, al

    // Restore LCD panel control
    mov al, bh
    out IO_LCD_CTRL, al
    // Restore interrupt mask
    mov al, bl
    out IO_HWINT_ENABLE, al

    pop ds

    popa
    ret
