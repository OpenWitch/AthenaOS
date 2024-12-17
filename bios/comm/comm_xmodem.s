/**
 * Copyright (c) 2024 Adrian "asie" Siekierka
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
 * OUT OF OR IN CONNECT1ION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

	.arch	i186
	.code16
	.intel_syntax noprefix

#include "common.inc"

// XMODEM protocol constants
#define SOH 1
#define EOT 4
#define ACK 6
#define NAK 21
#define CAN 24

// State structure offsets
#define OFS_STATE 0
#define OFS_MODE 2
#define OFS_RETRY_COUNT 3
#define OFS_CURR_BLOCK 4
#define OFS_BLOCK_COUNT 6
#define OFS_BLOCK_SIZE 8
#define OFS_BANK 10
#define OFS_OFFSET 12
#define OFS_UNK1 14

	.align 2
comm_xmodem_handlers:
	.word comm_xmodem_start
	.word comm_xmodem_negotiate
	.word comm_xmodem_block
	.word comm_xmodem_block
	.word comm_xmodem_close
	.word comm_xmodem_invalid_state // Abort
	.word comm_xmodem_invalid_state // Done
	.word comm_xmodem_erase_bank

/**
 * INT 14h AH=0Dh - comm_xmodem
 * Input:
 * - DS:BX - Pointer to XMODEM state structure
 * Output:
 * - AX = New state
 */
	.global comm_xmodem
comm_xmodem:
	push bx
	push cx
	push dx
	push si
	push di
	mov di, bx

	mov bp, [bx + OFS_STATE]
	test bp, bp
	jz comm_xmodem_invalid_state
	cmp bp, 8
	ja comm_xmodem_invalid_state
	add bp, bp
	cs jmp [comm_xmodem_handlers - 2 + bp]

comm_xmodem_finish_state:
	pop di
	pop si
	pop dx
	pop cx
	pop bx

	mov [bx], ax
	ret

comm_xmodem_invalid_state:
	mov ax, 0x8104
	jmp comm_xmodem_finish_state

/**
 * XMODEM communication protocol (in brief):
 * (-> sender to receiver, <- receiver to sender)
 * 
 * <- NAK (CAN)
 * -> SOH block block^0xFF data checksum
 * <- ACK (EOT, CAN, NAK)
 * -> SOH block block^0xFF data checksum
 * <- ACK (EOT, CAN, NAK)
 * -> EOT
 * <- NAK
 * -> EOT
 * <- ACK
 */

	// Utility functions

	// Receive character to AX.
	// Clears Z flag on error
comm_xmodem_receive_char:
	// Receive character
	call comm_receive_char
	// Check for cancel
	cmp ax, CAN
	je comm_xmodem_receive_char_cancel
	test ah, ah
	ret
comm_xmodem_receive_char_cancel:
	// Cancel
	mov ax, 0x8105
	test ah, ah
	ret

comm_xmodem_abort:
	// Send CAN
	mov bl, CAN
	call comm_send_char
	// -> Abort
	mov ax, 0x0006
	jmp comm_xmodem_finish_state

comm_xmodem_block_lost:
	// Send CAN
	mov bl, CAN
	call comm_send_char
	// -> Block lost
	mov ax, 0x8106
	jmp comm_xmodem_finish_state

	// $0001 - Start
comm_xmodem_start:
	// TODO: Support bit 2
	test byte ptr [di + OFS_MODE], 0x04
	jnz error_handle_generic

	// Write initial values
	xor ax, ax
	mov byte ptr [di + OFS_RETRY_COUNT], al
	mov word ptr [di + OFS_CURR_BLOCK], ax
	mov word ptr [di + OFS_BLOCK_SIZE], 128

	// Open serial communication
	call comm_open

	// -> Negotiate
	mov ax, 0x0002
	jmp comm_xmodem_finish_state

	// $0002 - Negotiate
comm_xmodem_negotiate:
	test byte ptr [di + OFS_MODE], 0x01
	jnz comm_xmodem_negotiate_receive

comm_xmodem_negotiate_send:
	// Receive NAK byte
	call comm_xmodem_receive_char
	jnz comm_xmodem_finish_state

	// If not NAK or CAN, stay in Negotiate
	// ASSUMPTION: AH == 0 (test ah, ah)
	cmp al, NAK
	jne comm_xmodem_negotiate_send

	// -> Block
	mov al, 0x03
	jmp comm_xmodem_finish_state

comm_xmodem_negotiate_receive:
	// Send NAK byte
	mov bl, NAK
	call comm_send_char
	// Check for error
	test ah, ah
	jnz comm_xmodem_finish_state
	// Fall through to receive first block

	// $0003 - Block
	// $0004 - Block retry
comm_xmodem_block_receive:
	cmp word ptr [di + OFS_CURR_BLOCK], 0
	je 1f

	// If not on first block, send ACK or NAK
	mov bl, NAK
	cmp word ptr [di + OFS_STATE], 0x0004
	je 2f
	mov bl, ACK
2:
	call comm_send_char
	test ah, ah
	jnz comm_xmodem_finish_state

1:
	// Receive SOH or EOT byte
	call comm_xmodem_receive_char
	jnz comm_xmodem_finish_state
	cmp al, EOT
	je comm_xmodem_to_close
	cmp al, SOH
	jne comm_xmodem_abort

	// Check transfer size
	mov ax, [di + OFS_CURR_BLOCK]
	cmp ax, [di + OFS_BLOCK_COUNT]
	// -> Transfer too large?
	mov ax, 0x8107
	jae comm_xmodem_finish_state

	// Receive block ID
	call comm_receive_char
	test ah, ah
	jnz comm_xmodem_finish_state
	dec al
	cmp al, [di + OFS_CURR_BLOCK]
	jne comm_xmodem_block_lost

	call comm_receive_char
	test ah, ah
	jnz comm_xmodem_finish_state
	not al
	dec al
	cmp al, [di + OFS_CURR_BLOCK]
	jne comm_xmodem_abort

	mov cx, [di + OFS_BLOCK_SIZE]
	push ds
	push ss
	pop ds

	// Receive bank data
	mov dx, [bios_tmp_buffer]
	call comm_receive_block

	pop ds
	test ah, ah
	jnz comm_xmodem_finish_state

	// Receive checksum byte
	call comm_receive_char
	test ah, ah
	jnz comm_xmodem_finish_state
	mov ah, al

	mov si, dx
	mov bl, 0
1:
	ss lodsb
	add bl, al
	loop 1b

	// Compare checksum byte
	cmp bl, ah
	jne comm_xmodem_block_to_retry_block

	// Write block to bank
	// Preserve DI, DS, ES
	push di
	push ds
	push es

	mov bx, [di + OFS_BANK]
	mov cx, [di + OFS_BLOCK_SIZE]
	mov dx, [di + OFS_OFFSET]

	push ss
	pop ds
	mov si, [bios_tmp_buffer]

	call bank_write_block

	pop es
	pop ds
	pop di
	
	jmp comm_xmodem_block_to_block

comm_xmodem_to_close:
	// -> Close
	mov ax, 0x05
	jmp comm_xmodem_finish_state

comm_xmodem_block:
	test byte ptr [di + OFS_MODE], 0x01
	jnz comm_xmodem_block_receive

comm_xmodem_block_send:
	// Check transfer size
	mov ax, [di + OFS_CURR_BLOCK]
	cmp ax, [di + OFS_BLOCK_COUNT]
	jae comm_xmodem_to_close

	// Read block from bank
	// Preserve DI, DS, ES
	push ds
	push di
	push es

	mov bx, [di + OFS_BANK]
	mov cx, [di + OFS_BLOCK_SIZE]
	push cx
	mov dx, [di + OFS_OFFSET]

	push ss
	pop ds
	mov si, [bios_tmp_buffer]
	push si

	call bank_read_block

	pop si
	pop cx
	pop es
	pop di
	
	// Calculate checksum
	// Use CX from previous call
	push ss
	pop ds
	
	mov bl, 0
1:
	lodsb
	add bl, al
	loop 1b

	pop ds
	push bx

	// Send SOH
	mov bl, SOH
	call comm_send_char
	test ah, ah
	jnz comm_xmodem_finish_state

	// Send block ID
	mov bl, [di + OFS_CURR_BLOCK]
	inc bl
	call comm_send_char
	test ah, ah
	jnz comm_xmodem_finish_state

	// Send inverted block ID
	not bl
	call comm_send_char
	test ah, ah
	jnz comm_xmodem_finish_state

	// Send bank data
	push ds
	mov cx, [di + OFS_BLOCK_SIZE]
	push ss
	pop ds
	mov dx, [bios_tmp_buffer]
	call comm_send_block
	pop ds

	test ah, ah
	jnz comm_xmodem_finish_state

	// Send checksum
	pop bx
	call comm_send_char	
	test ah, ah
	jnz comm_xmodem_finish_state

	// Receive ACK
	call comm_xmodem_receive_char
	jnz comm_xmodem_finish_state
	cmp al, ACK
	je comm_xmodem_block_to_block
	cmp al, NAK
	jne comm_xmodem_abort
comm_xmodem_block_to_retry_block:
	// Increment number of retries
	inc byte ptr [di + OFS_RETRY_COUNT]

	// -> Retry Block
	mov al, 0x04
	jmp comm_xmodem_finish_state

comm_xmodem_block_to_block:
	// Go to next block
	inc word ptr [di + OFS_CURR_BLOCK]
	mov ax, [di + OFS_BLOCK_SIZE]
	add [di + OFS_OFFSET], ax
	adc word ptr [di + OFS_BANK], 0

	// -> Block
	mov ax, 0x03
	jmp comm_xmodem_finish_state

	// $0005 - Close
comm_xmodem_close:
	test byte ptr [di + OFS_MODE], 0x01
	jnz comm_xmodem_close_receive

comm_xmodem_close_send:
	// Send EOT, receive response
	mov bl, EOT
	call comm_send_char
	call comm_xmodem_receive_char
	jnz comm_xmodem_finish_state
	// If it's not ACK, stay in Close state
	cmp al, ACK
	jne comm_xmodem_to_close

comm_xmodem_close_to_done:
	// -> Done
	// ASSUMPTION: AH == 0 (test ah, ah)
	mov al, 0x07
	jmp comm_xmodem_finish_state

comm_xmodem_close_receive:
	// While some XMODEM implementations send NAK first to detect false EOTs,
	// TransMagic considers a NAK response to EOT an unrecoverable error.
	// As such, respond to EOT with ACK
	mov bl, ACK
	call comm_send_char
	test ah, ah
	jnz comm_xmodem_finish_state

	jmp comm_xmodem_close_to_done

	// $0008 - Erase bank
	// TODO: Proper support
comm_xmodem_erase_bank:
	mov ax, 0x0003
	jmp comm_xmodem_finish_state

