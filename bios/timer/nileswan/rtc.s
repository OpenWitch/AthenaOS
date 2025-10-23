/**
 * Copyright (c) 2023, 2024, 2025 Adrian "asie" Siekierka
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

#include "nileswan.inc"
#define RTC_CMD(n) (((n) << 7) | 0x14)

#include "common.inc"

// Prepare SRAM writing location for RTC transfer.
// Input:
// - AX: Command
// Output:
// - ES:DI points to the SRAM structure
// - BP stores the previous bank
__rtc_transaction_prepare:
	mov di, ax

	// Save bank
	in ax, IO_BANK_2003_RAM
	mov bp, ax
	mov ax, NILE_SEG_RAM_SPI_TX
	out IO_BANK_2003_RAM, ax

	// Write command to SPI TX buffer and set ES:DI
	cld
	mov ax, 0x1000
	mov es, ax
	mov ax, di
	xor di, di
	stosw

	ret

__rtc_transaction_commit:
	// Begin SPI transfer
	in ax, IO_NILE_SPI_CNT
	and ax, NILE_SPI_BUFFER_IDX
	xor ax, (NILE_SPI_CNT_MCU | NILE_SPI_BUFFER_IDX | NILE_SPI_MODE_WRITE | NILE_SPI_START)
	dec di
	or ax, di
	out IO_NILE_SPI_CNT, ax

	// Restore RAM bank
	mov ax, bp
	out IO_BANK_2003_RAM, ax

	// Save ROM0 bank
	in ax, IO_BANK_2003_ROM0
	mov bp, ax
	mov ax, NILE_SEG_ROM_SPI_RX
	out IO_BANK_2003_ROM0, ax

	// Wait for SPI transfer to finish
1:
	in ax, IO_NILE_SPI_CNT
	test ax, 0x8000
	jnz 1b

	// Don't flip buffer, wait for response (up to 9 bytes)
	and ax, NILE_SPI_BUFFER_IDX
	xor ax, (NILE_SPI_CNT_MCU | NILE_SPI_MODE_WAIT_READ | NILE_SPI_START | (9 - 1))
	out IO_NILE_SPI_CNT, ax

	// Prepare for SPI RX buffer
	mov ax, 0x2000
	mov es, ax
	xor di, di

	// Wait for SPI transfer to finish
1:
	in ax, IO_NILE_SPI_CNT
	test ax, 0x8000
	jnz 1b

	// Flip buffer
	xor ax, NILE_SPI_BUFFER_IDX
	out IO_NILE_SPI_CNT, ax

	ret

__rtc_transaction_finish:
	// Restore ROM0 bank
	mov ax, bp
	out IO_BANK_2003_ROM0, ax

	ret

/**
 * INT 16h AH=03h - rtc_set_datetime_struct
 * Input:
 * - DS:DX = Input data structure
 */
	.global rtc_set_datetime_struct
rtc_set_datetime_struct:
	push es
	push di
	push si
	push cx

	mov ax, RTC_CMD(0x04)
	call __rtc_transaction_prepare
	mov si, dx

	mov cx, 7
1:
	lodsb
    call __bin_to_bcd_al
	stosb
	loop 1b

	call __rtc_transaction_commit

	call __rtc_transaction_finish

	pop cx
	pop si
	pop di
	pop es
	ret

/**
 * INT 16h AH=04h - rtc_get_datetime_struct
 * Input:
 * - DS:DX = Output data structure
 */
	.global rtc_get_datetime_struct
rtc_get_datetime_struct:
	push es
	push di
	push si
	push cx

	mov ax, RTC_CMD(0x05)
	call __rtc_transaction_prepare

	call __rtc_transaction_commit

	add di, 2
	mov si, dx
	mov cx, 7
1:
	es mov al, [di]
    call __bcd_to_bin_al
	mov [si], al
	inc si
	inc di
	loop 1b

	call __rtc_transaction_finish

	pop cx
	pop si
	pop di
	pop es
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
	push es
	push di
	push si

	mov ax, RTC_CMD(0x08)
	call __rtc_transaction_prepare

	mov al, bl
    call __bin_to_bcd_al
	stosb
	mov al, bh
    call __bin_to_bcd_al
	stosb

	call __rtc_transaction_commit
	call __rtc_transaction_finish

	mov ax, RTC_CMD(0x02)
	call __rtc_transaction_prepare
    mov al, (WS_CART_RTC_STATUS_INT_ALARM | WS_CART_RTC_STATUS_24_HOUR)
	stosb

	call __rtc_transaction_commit
	call __rtc_transaction_finish

	pop si
	pop di
	pop es
	ret

/**
 * INT 16h AH=06h - rtc_disable_alarm
 * Input:
 * Output:
 */
	.global rtc_disable_alarm
rtc_disable_alarm:
	push es
	push di
	push si

	mov ax, RTC_CMD(0x02)
	call __rtc_transaction_prepare
    mov al, (WS_CART_RTC_STATUS_24_HOUR)
	stosb

	call __rtc_transaction_commit
	call __rtc_transaction_finish

	pop si
	pop di
	pop es
	ret

/**
 * INT 16h AH=00h - rtc_reset
 * Input:
 * Output:
 */
	.global rtc_reset
rtc_reset:
	push es
	push di

	mov ax, RTC_CMD(0x00)
	call __rtc_transaction_prepare
	call __rtc_transaction_commit
	call __rtc_transaction_finish

	pop di
	pop es

	.global rtc_init
rtc_init:
	ret