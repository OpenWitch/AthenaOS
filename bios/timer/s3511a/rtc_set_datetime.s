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
 * INT 16h AH=01h - rtc_set_datetime
 * Input:
 * - BX = Field
 * - CX = Field value
 */
    .global rtc_set_datetime
rtc_set_datetime:
    cmp bx, 7
    jae 9f

    push ax
    push bx
    push dx
    push ds

    // Allocate temporary buffer for date/time data
    sub sp, 8
    push ss
    pop ds
    mov dx, sp
    call rtc_get_datetime_struct
    
    // Replace value
    add bx, dx
    mov [bx], cl
    call rtc_set_datetime_struct

    // Deallocate buffer
    add sp, 8

    pop ds
    pop dx
    pop bx
    pop ax
9:
    ret
