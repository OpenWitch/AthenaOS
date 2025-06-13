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

#include "nileswan.inc"
#define MCU_MAX_BLOCK_SIZE 256

#include "common.inc"

    // Input:
    // - CX = timeout
    // Output:
    // - AL = 0 if success, 1 if timeout, 2 if overrun, 3 if cancel
    // Clobber: AX
__nile_spi_wait_ready:
1:
	in al, 0xE1
	test al, 0x80
	jnz 1b
	mov ax, 0x0000
	test al, al
	ret


/**
 * INT 14h AH=00h - comm_open
 * Input:
 * Output:
 */
    .global comm_open
comm_open:
	mov bp, NILE_SPI_CNT_MCU
__nile_set_spi_cnt:
	push ax
	push cx
	mov cx, 0xFFFF
	call __nile_spi_wait_ready
	pop cx
	mov ax, bp
	out 0xE0, ax
	pop ax
    ret

/**
 * INT 14h AH=01h - comm_close
 * Input:
 * Output:
 */
    .global comm_close
comm_close:
	mov bp, NILE_SPI_CNT_NONE
	jmp __nile_set_spi_cnt

/**
 * INT 14h AH=06h - comm_send_block
 * Input:
 * - CX = Length, in bytes
 * - DS:DX = Input buffer
 * Output:
 * - AX = Status
 */
    .global comm_send_block
comm_send_block:
	cmp cx, MCU_MAX_BLOCK_SIZE
	ja comm_send_block_partial

	push cx
	push dx
	push si
	push di

	cld

	mov si, dx
	ss mov dx, [tick_count]
	ss add dx, [comm_send_timeout] // DX = final tick count

	// Write send command
	in ax, IO_BANK_2003_RAM
	push ax
	mov ax, NILE_SEG_RAM_SPI_TX
	out IO_BANK_2003_RAM, ax

	push es
	push 0x1000
	pop es
	xor di, di

	// Command, length
	mov ax, cx
	shl ax, 7
	or ax, 0x41
	stosw

	// Data
	push cx
	inc cx
	shr cx, 1
	rep movsw
	pop cx

	pop es

	pop ax
	out IO_BANK_2003_RAM, ax

	// Wait for SPI ready
	call __nile_spi_wait_ready
	jnz 9f

	// SPI control
	in ax, IO_NILE_SPI_CNT
	and ax, NILE_SPI_CFG_MASK
	xor ax, (NILE_SPI_CNT_MCU | NILE_SPI_BUFFER_IDX | NILE_SPI_MODE_WRITE | NILE_SPI_START)
	// CX = data length, packet length = CX + 2, SPI length = packet length - 1
	inc cx
	or ax, cx
	out IO_NILE_SPI_CNT, ax

	// Wait for SPI ready
	call __nile_spi_wait_ready
	jnz 9f

	// SPI acknowledge response asynchronously
	// TODO: Actually handle response
	in ax, IO_NILE_SPI_CNT
	and ax, NILE_SPI_CFG_MASK
	xor ax, (NILE_SPI_CNT_MCU | NILE_SPI_BUFFER_IDX | NILE_SPI_MODE_WAIT_READ | NILE_SPI_START | (4 - 1))
	out IO_NILE_SPI_CNT, ax

	// Wait for SPI ready
	call __nile_spi_wait_ready
	jnz 9f

	// Done
	xor ax, ax
9:
	pop di
	pop si
	pop dx
	pop cx
    ret

comm_send_block_partial:
	push cx
	mov cx, MCU_MAX_BLOCK_SIZE
	call comm_send_block
	test ax, ax
	jz 1f
	ret
1:
	pop cx
	sub cx, MCU_MAX_BLOCK_SIZE
	add dx, MCU_MAX_BLOCK_SIZE
	jmp comm_send_block

/**
 * INT 14h AH=07h - comm_receive_block
 * Input:
 * - CX = Length, in bytes
 * - DS:DX = Input buffer
 * Output:
 * - AX = Status
 * - DX = Number of bytes received
 */
    .global comm_receive_block
comm_receive_block:
	xor bp, bp
	push cx
	push si
	push di
	push ds
	push es

	// Done?
	test cx, cx
	mov ax, 0
	jz 9f

	push ds
	pop es
	mov di, dx

	cld

    ss mov dx, [tick_count]
    ss add dx, [comm_recv_timeout] // DX = final tick count

5:
	// Write receive command
	in ax, IO_BANK_2003_RAM
	push ax
	mov ax, NILE_SEG_RAM_SPI_TX
	out IO_BANK_2003_RAM, ax

	push 0x1000
	pop ds
	xor si, si

	// Command, length
	mov ax, MCU_MAX_BLOCK_SIZE
	cmp cx, ax
	ja 1f
	mov ax, cx
1:
	shl ax, 7
	or ax, 0x40
	mov [si], ax

	pop ax
	out IO_BANK_2003_RAM, ax

	// Wait for SPI ready
	call __nile_spi_wait_ready
	jnz 9f

	// SPI control
	in ax, IO_NILE_SPI_CNT
	and ax, NILE_SPI_CFG_MASK
	xor ax, (NILE_SPI_CNT_MCU | NILE_SPI_BUFFER_IDX | NILE_SPI_MODE_WRITE | NILE_SPI_START | (2 - 1))
	out IO_NILE_SPI_CNT, ax

	// Wait for SPI ready
	call __nile_spi_wait_ready
	jnz 9f

	// SPI read response length
	// TODO: Read length first
	in ax, IO_NILE_SPI_CNT
	and ax, NILE_SPI_CFG_MASK
	xor ax, (NILE_SPI_CNT_MCU | NILE_SPI_BUFFER_IDX | NILE_SPI_MODE_WAIT_READ | NILE_SPI_START)
	// CX = data length, packet length = CX + 2, SPI length = packet length - 1
	or ax, cx
	inc ax
	out IO_NILE_SPI_CNT, ax

	// Wait for SPI ready
	call __nile_spi_wait_ready
	jnz 9f

	in al, (IO_NILE_SPI_CNT + 1)
	xor al, (NILE_SPI_BUFFER_IDX >> 8)
	out (IO_NILE_SPI_CNT + 1), al

	in ax, IO_NILE_SEG_MASK
	push ax
	and ax, ~NILE_SEG_MASK_ROM0_ENABLE
	out IO_NILE_SEG_MASK, ax

	in ax, IO_BANK_2003_ROM0
	push ax
	mov ax, NILE_SEG_ROM_SPI_RX
	out IO_BANK_2003_ROM0, ax

	push 0x2000
	pop ds

	// AX = number of bytes read
	lodsw
	test ax, (~0x3FE)
	jnz 8f
	shr ax, 1
	// If empty, skip copy
	jz 4f

	// CX = number of bytes to read
	// AX = number of bytes read
	// BP = total number of bytes read
	// TODO: this loop can be optimized...
	sub cx, ax
	add bp, ax
	xchg ax, cx
	rep movsb
	xchg ax, cx

4:
	pop ax
	out IO_BANK_2003_ROM0, ax
	pop ax
	out IO_NILE_SEG_MASK, ax

	// Done?
	test cx, cx
	mov ax, 0
	jz 9f

	// Wait ~2ms
	push cx
	pushf
	sti
	mov cx, 1200
1:
	loop 1b

	// popf
	// pop cx

	// Timeout?
	// push cx
	// pushf
	// sti
	ss mov cx, [comm_recv_timeout]
	call __comm_check_timeout
	popf
	pop cx
	test al, al
	jz 5b

	mov ah, 0x81
9:
	pop es
	pop ds
	pop di
	pop si
	pop cx
	mov dx, bp
	ret
8:
	pop ax
	out IO_BANK_2003_ROM0, ax
	pop ax
	out IO_NILE_SEG_MASK, ax
	mov ax, 0x8102
	jmp 9b
