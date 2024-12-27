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
irq_bank_handlers:
	.word bank_set_map
	.word bank_get_map
	.word bank_read_byte
	.word bank_write_byte
	.word bank_read_word
	.word bank_write_word
	.word bank_read_block
	.word bank_write_block
	.word bank_fill_block
	.word bank_erase_flash

	.global irq_bank_handler
irq_bank_handler:
	m_irq_table_handler irq_bank_handlers, 10, (M_IRQ_PUSH_BX | M_IRQ_PUSH_CX | M_IRQ_PUSH_DX | M_IRQ_PUSH_SI | M_IRQ_PUSH_DI | M_IRQ_PUSH_DS | M_IRQ_PUSH_ES), error_handle_irq24
	iret

	.section ".bss"
#if BIOS_BANK_ROM_FORCE_DYNAMIC
	.global bank_rom_offset
bank_rom_offset: .word 0
#endif
