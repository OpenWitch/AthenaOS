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
 * INT 16h AH=00h - rtc_reset
 */
    .global rtc_init
    .global rtc_reset
/**
 * INT 16h AH=01h - rtc_set_datetime
 * Input:
 * - BX = Field
 * - CX = Field value
 */
    .global rtc_set_datetime
rtc_set_datetime:
    cmp bx, 7
    jae 1f
    ss mov [rtc_data + bx], cl
1:
rtc_init:
rtc_reset:
    ret

/**
 * INT 16h AH=02h - rtc_get_datetime
 * Input:
 * - BX = Field
 * Output:
 * - AX = Field value
 */
    .global rtc_get_datetime
rtc_get_datetime:
    xor ax, ax
    cmp bx, 7
    jae 1f
    ss mov al, [rtc_data + bx]
1:
    ret

/**
 * INT 16h AH=03h - rtc_set_datetime_struct
 * Input:
 * - DS:DX = Input data structure
 */
    .global rtc_set_datetime_struct
rtc_set_datetime_struct:
    push si
    push di
    push es
    push ss
    pop es

    mov si, dx
    mov di, offset rtc_data

    movsw
    movsw
    movsw
    movsb

    pop es
    pop di
    pop si
    ret

/**
 * INT 16h AH=04h - rtc_get_datetime_struct
 * Input:
 * - DS:DX = Output data structure
 */
    .global rtc_get_datetime_struct
rtc_get_datetime_struct:
    push si
    push di
    push ds
    push es
    push ss
    push ds
    pop es
    pop ds

    mov si, offset rtc_data
    mov di, dx

    movsw
    movsw
    movsw
    movsb

    pop es
    pop ds
    pop di
    pop si

    // Fall through to RET

/**
 * INT 16h AH=05h - rtc_enable_alarm
 * Input:
 * - BL = Alarm hour
 * - BH = Alarm minute
 * Output:
 */
    .global rtc_enable_alarm
rtc_enable_alarm:
    // Fall through to RET

/**
 * INT 16h AH=06h - rtc_disable_alarm
 * Input:
 * Output:
 */
    .global rtc_disable_alarm
rtc_disable_alarm:
    // Fall through to RET

    ret

    .section ".data"
    .global rtc_data
rtc_data:
    .byte 0 // Year (0 => 2000)
    .byte 1 // Month
    .byte 1 // Day of month
    .byte 0 // Day of week
    .byte 0 // Hour
    .byte 0 // Minute
    .byte 0 // Second
