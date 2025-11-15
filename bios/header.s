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

	.section .header, "a"
header:
#ifndef BIOS_NO_PSRAM_RETENTION_HEADER
	// This header is a credit notation for the ELISA font in the official
	// FreyaBIOS program, stored at the beginning of its 64 KB segment.
	// While we don't use ELISA, we preserve this header as it is used for
	// WonderWitch ROM detection (=> enabling flash memory) by emulators.
	.byte 'E', 'L', 'I', 'S', 'A'
#endif

	.section .footer_athena, "a"
footer_athena:
	.byte 'A'
	.byte 'T'
	.byte 'H'
	.byte 'B'
	.byte ATHENA_VERSION_MAJOR
	.byte ATHENA_VERSION_MINOR
	.byte ATHENA_VERSION_PATCH

	.section .footer, "a"
footer:
	.byte 0xEA
	.word _start
	.word BIOS_SEGMENT
	.byte 0 // Maintenance
	.byte 0 // Publisher ID
	.byte 1 // Color
	.byte 0 // Game ID
	.byte 0x80 // Game version

	// ROM size (derived from BIOS_BANK_ROM_FORCE_COUNT)
#if BIOS_BANK_ROM_FORCE_COUNT == 1024
	.byte 11
#elif BIOS_BANK_ROM_FORCE_COUNT == 512
	.byte 10
#elif BIOS_BANK_ROM_FORCE_COUNT == 256
	.byte 9
#elif BIOS_BANK_ROM_FORCE_COUNT == 128
	.byte 8
#elif BIOS_BANK_ROM_FORCE_COUNT == 64
	.byte 6
#elif BIOS_BANK_ROM_FORCE_COUNT == 32
	.byte 4
#elif BIOS_BANK_ROM_FORCE_COUNT == 16
	.byte 3
#elif BIOS_BANK_ROM_FORCE_COUNT == 8
	.byte 2
#elif BIOS_BANK_ROM_FORCE_COUNT == 4
	.byte 1
#elif BIOS_BANK_ROM_FORCE_COUNT == 1
	.byte 0
#elif BIOS_BANK_ROM_FORCE_COUNT == 0
	.byte 2 // Default - 512 KiB
#else
# error Unsupported ROM bank count!
#endif

#ifdef OS_ENABLE_128K_SRAM
	.byte 3 // RAM size - 128 KiB
#else
	.byte 4 // RAM size - 256 KiB
#endif
	.byte 4 // Flags
	.byte 1 // Mapper
	.word 0xFFFF // Checksum
