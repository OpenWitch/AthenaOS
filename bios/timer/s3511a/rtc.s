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

__rtc_wait_ready:
1:
    in al, WS_CART_RTC_CTRL_PORT
    test al, (WS_CART_RTC_CTRL_READY | WS_CART_RTC_CTRL_ACTIVE)
    jz 2f
    test al, WS_CART_RTC_CTRL_READY
    jz 1b
2:
    ret

__rtc_read_byte:
    call __rtc_wait_ready
    in al, WS_CART_RTC_DATA_PORT
    ret

__rtc_write_byte:
    push ax
    call __rtc_wait_ready
    pop ax
    out WS_CART_RTC_DATA_PORT, al
    ret
    
__rtc_read_start:
    push ax
    call __rtc_wait_ready
    pop ax
    out WS_CART_RTC_CTRL_PORT, al
    ret

__rtc_write_start:
    push ax
    call __rtc_wait_ready
    pop ax
    out WS_CART_RTC_CTRL_PORT, ax
    ret
    
/**
 * INT 16h AH=03h - rtc_set_datetime_struct
 * Input:
 * - DS:DX = Input data structure
 */
    .global rtc_set_datetime_struct
rtc_set_datetime_struct:
    push cx
    push si

    // Write to RTC
    lodsb
    call __bin_to_bcd_al
    mov ah, al
    mov al, 0x14 // Write date/time
    call __rtc_write_start
    mov si, dx
    mov cx, 6
1:
    lodsb
    call __bin_to_bcd_al
    call __rtc_write_byte
    loop 1b

    pop si
    pop cx
    ret

/**
 * INT 16h AH=04h - rtc_get_datetime_struct
 * Input:
 * - DS:DX = Output data structure
 */
    .global rtc_get_datetime_struct
rtc_get_datetime_struct:
    push cx
    push di
    push es
    push ds
    pop es

    // Read from RTC
    mov al, 0x15 // Read date/time
    call __rtc_read_start
    mov di, dx
    mov cx, 7
1:
    call __rtc_read_byte
    call __bcd_to_bin_al
    stosb
    loop 1b

    pop es
    pop di
    pop cx
    ret
    

/**
 * INT 16h AH=05h - rtc_enable_alarm
 * Input:
 * - BL = Alarm hour
 * - BH = Alarm minute
 * Output:
 */
    .global rtc_enable_alarm
rtc_enable_alarm:
    push ax
    // Write alarm hour
    mov al, bl
    call __bin_to_bcd_al
    and al, 0x3F
    mov ah, al
    // Write alarm time
    mov al, 0x18
    call __rtc_write_start
    // Write alarm minute
    mov al, bh
    call __bin_to_bcd_al
    call __rtc_write_byte
    // Write status
    mov ax, ((WS_CART_RTC_STATUS_INT_ALARM | WS_CART_RTC_STATUS_24_HOUR) << 8) | 0x12
    call __rtc_write_start
    pop ax
    ret

    .global rtc_init
rtc_init:
    push ax
    // Read status
    mov al, 0x13
    call __rtc_read_start
    call __rtc_read_byte

    // Was power loss detected?
    test al, WS_CART_RTC_STATUS_POWER_LOST
    jnz 1f
    pop ax
    ret
/**
 * INT 16h AH=00h - rtc_reset
 * Input:
 * Output:
 */
    .global rtc_reset
rtc_reset:
    push ax
1:
    // Reset
    mov ax, 0xFF10
    call __rtc_write_start
    pop ax

/**
 * INT 16h AH=06h - rtc_disable_alarm
 * Input:
 * Output:
 */
    .global rtc_disable_alarm
rtc_disable_alarm:
    push ax
    // Write status
    mov ax, ((WS_CART_RTC_STATUS_24_HOUR) << 8) | 0x12
    call __rtc_write_start
    pop ax
    ret
