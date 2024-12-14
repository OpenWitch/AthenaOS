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

	.align 2
irq_comm_handlers:
	.word comm_open
	.word comm_close
	.word comm_send_char
	.word comm_receive_char
	.word comm_receive_with_timeout
	.word comm_send_string
	.word comm_send_block
	.word comm_receive_block
	.word comm_set_timeout
	.word comm_set_baudrate
	.word comm_get_baudrate
	.word comm_set_cancel_key
	.word comm_get_cancel_key
	.word comm_xmodem

	.global irq_comm_handler
irq_comm_handler:
	m_irq_table_handler irq_comm_handlers, 14, 0, error_handle_irq20
	iret

	.section ".data"
	.global comm_baudrate
comm_baudrate: .byte 1 // 38400 bps
	.global comm_recv_timeout
comm_recv_timeout: .word 0xFFFF
	.global comm_send_timeout
comm_send_timeout: .word 0xFFFF

	.section ".bss"
	.global comm_cancel_key
comm_cancel_key: .word 0
