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

/**
 * INT 18h AH=05h - bank_write_word
 * Input:
 * - BX = Bank ID
 *   - 0000 ~ 7FFF = SRAM
 *   - 8000 ~ FFFF = ROM/Flash
 * - CX = Word to write
 * - DX = Address within bank
 * Output:
 */
    .global bank_write_word
bank_write_word:
    push ax
#ifndef BIOS_BANK_MAPPER_SIMPLE_RAM
    test bh, 0x80
    jnz error_handle_write_to_rom
#endif
    mov di, dx
    bank_rw_bx_to_segment_start ds
    mov [di], cx
    bank_rw_bx_to_segment_end_unsafe
    pop ax
    ret

