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
    // - CX = timeout
    // - DX = final tick count
    // Output:
    // - AL = 0 if success, 1 if timeout, 2 if overrun, 3 if cancel
    // Clobber: AX
    
    .global __comm_check_timeout
__comm_check_timeout:
    cmp cx, 0xFFFF
    je 2f // skip timeout?

    test cx, cx
    jz 7f // zero timeout?
    ss cmp dx, [tick_count]
    jle 7f // timeout?

2:
    // check for cancel key
    ss mov ax, [comm_cancel_key]
    test ax, ax
    jz 9f // cancel key not set?
    ss and ax, [keys_held]
    ss cmp ax, [comm_cancel_key]
    jne 9f // cancel key combo not matched?

    mov al, 3 // return cancel
    ret

7:
    mov al, 1 // return timeout
    ret

9:
    mov al, 0 // all clear
    ret

