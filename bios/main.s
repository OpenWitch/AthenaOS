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

	.section .start, "ax"
	.global _start
_start:
	cli
	cld

	// configure stack pointer, prepare ES for data/BSS
	xor ax, ax
	mov es, ax
	mov ss, ax
	mov ax, MEM_STACK_TOP
	mov sp, ax

#ifdef ATHENA_FLAVOR_nileswan
	// Unlock all cartridge I/O
	mov al, 0xDD
	out 0xE2, al

	// Start MCU reset, disable unused features, unlock RAM/ROM banks
	mov ax, 0x5D
	out 0xE2, ax
	in ax, 0xE4
	and ax, 0xF1FF
	out 0xE4, ax
	mov al, 0xD4
	out 0xE2, al

	// Sleep for a few milliseconds
	mov cx, 5000
1:
	loop 1b
#endif

	// initialize data/BSS
	push cs
	pop ds
	mov si, offset "__text_end"
	mov di, offset "__data_start"
	mov cx, offset "__data_length_words"
	rep movsw
	mov cx, offset "__bss_length_words"
	xor ax, ax
	rep stosw

#if BIOS_BANK_ROM_FORCE_DYNAMIC
	// Intiialize bank_rom_offset
	mov ah, 0xFF
	in al, WS_CART_BANK_ROML_PORT
	shl ax, 4
	or al, 0x08
	ss mov bank_rom_offset, ax
#endif

	// Clear interrupt vectors
	mov di, ax
	mov cx, 0x40
1:
	mov ax, offset "error_handle_generic"
	stosw // offset
	mov ax, cs
	stosw // segment
	loop 1b

	// Write interrupt vectors
	mov di, (0x28 * 4)
	mov si, offset "irq_handlers_28"
	mov cx, offset ((irq_handlers_28_end - irq_handlers_28) >> 1)
	// already set above
	// mov ax, cs
1:
	movsw // offset
	stosw // segment
	loop 1b

	mov di, (0x10 * 4)
	mov si, offset "irq_handlers_10"
	mov cx, offset ((irq_handlers_10_end - irq_handlers_10) >> 1)
1:
	movsw // offset
	stosw // segment
	loop 1b

	// Use IRQ vector 0x28 (required by sound.il)
	mov al, 0x28
	out WS_INT_VECTOR_PORT, al
	// Enable VBlank interrupt by default
	mov al, BIOS_REQUIRED_IRQ_MASK
	out WS_INT_ENABLE_PORT, al
	sti

	// initialize heap
	mov bp, offset __heap_start
	mov word ptr [bp], 0xFFFF // empty space
	mov word ptr [bp + 2], offset __heap_length

	// initialize LCD shade LUT
	mov ax, 0x6420
	out WS_LCD_SHADE_01_PORT, ax
	mov ax, 0xFCA8
	out WS_LCD_SHADE_45_PORT, ax

	// initialize default palette
	mov ax, 0x7530
	out WS_SCR_PAL_0_PORT, ax
	mov ax, 0x0357
	out WS_SCR_PAL_1_PORT, ax

	// boot in JPN2 mode by default
	mov al, 0x07
	out WS_SPR_BASE_PORT, al
	mov al, 0x32
	out WS_SCR_BASE_PORT, al
	mov ah, 0x02
	mov bl, 1
	int 0x13
	xor ax, ax
	int 0x13
	mov al, WS_DISPLAY_CTRL_SCR2_ENABLE
	out WS_DISPLAY_CTRL_PORT, al

	// initialize sound system
	call sound_init

	// initialize timer
	call rtc_init

	// jump to OS
	jmp 0xE000:0x0000

irq_handlers_10:
	.word irq_exit_handler				// 0x10 (BIOS - Exit)
	.word irq_key_handler				// 0x11 (BIOS - Key)
	.word irq_disp_handler				// 0x12 (BIOS - Display)
	.word irq_text_handler				// 0x13 (BIOS - Text)
	.word irq_comm_handler				// 0x14 (BIOS - Comm)
	.word irq_sound_handler				// 0x15 (BIOS - Sound)
	.word irq_timer_handler 			// 0x16 (BIOS - Timer)
	.word irq_system_handler			// 0x17 (BIOS - System)
	.word irq_bank_handler  			// 0x18 (BIOS - Bank)
irq_handlers_10_end:

irq_handlers_28:
	.word hw_irq_serial_tx_handler		// 0x28 (HW - serial TX)
	.word hw_irq_key_handler			// 0x29 (HW - key)
	.word hw_irq_cartridge_handler		// 0x2A (HW - cartridge)
	.word hw_irq_serial_rx_handler		// 0x2B (HW - serial RX)
	.word hw_irq_line_handler			// 0x2C (HW - line)
	.word hw_irq_vblank_timer_handler	// 0x2D (HW - VBlank timer)
	.word hw_irq_vblank_handler			// 0x2E (HW - VBlank)
	.word hw_irq_hblank_timer_handler	// 0x2F (HW - HBlank timer)
irq_handlers_28_end:
