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
#include "bank/bank_macros.inc"

	.align 2
irq_system_handlers:
	.word sys_interrupt_set_hook
	.word sys_interrupt_reset_hook
    .word sys_wait
    .word sys_get_tick_count
    .word sys_sleep
    .word sys_set_sleep_time
    .word sys_get_sleep_time
    .word sys_set_awake_key
    .word sys_get_awake_key
    .word sys_set_keepalive_int
    .word sys_get_ownerinfo
    .word sys_suspend
    .word sys_resume
    .word sys_set_remote
    .word sys_get_remote
    .word sys_alloc_iram
    .word sys_free_iram
    .word sys_get_my_iram
    .word sys_get_version
    .word sys_swap
    .word sys_set_resume
    .word sys_get_resume

	.global irq_system_handler
irq_system_handler:
	m_irq_table_handler irq_system_handlers, 22, 0, error_handle_irq23
	iret

    // BX = address
    // corrupts AX, BP
    // reads to AL
    .global __sys_read_sram_word
__sys_read_sram_word:
    // set DS
    push ds
    push 0x1000
    pop ds

    // set bank
    bank_map_read_ax_sram
    push ax
    mov ax, BIOS_SRAM_BANK
    bank_map_write_ax_sram

    mov bp, [bx]

    // reset bank
    pop ax
    bank_map_write_ax_sram

    // reset DS
    pop ds

    mov ax, bp
    ret

    // AL = byte
    // BX = address
    // corrupts AX, BP
    .global __sys_write_sram_byte
__sys_write_sram_byte:
    mov bp, ax

    // set DS
    push ds
    push 0x1000
    pop ds

    // set bank
    bank_map_read_ax_sram
    push ax
    mov ax, BIOS_SRAM_BANK
    bank_map_write_ax_sram

    mov ax, bp
    mov [bx], al

    // reset bank
    pop ax
    bank_map_write_ax_sram

    // reset DS
    pop ds
    ret

    .section ".data"
	.global sys_keepalive_int
sys_keepalive_int: .byte WS_INT_ENABLE_KEY_SCAN

	.section ".bss"
	.global sys_awake_key
sys_awake_key: .word 0
	.global sys_remote
sys_remote: .byte 0
