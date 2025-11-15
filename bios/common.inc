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

#include <wonderful.h>
#include <ws.h>
#include "macros.inc"

// Memory map
/// Wavetable memory location (64 bytes, aligned).
#define MEM_WAVETABLE 0x180
/// FreyaBIOS Screen 1 memory pointer (Junkbox's FEDORA depends on it).
#define MEM_PTR_SCR1  0x232
/// FreyaBIOS Screen 2 memory pointer (Junkbox's FEDORA depends on it).
#define MEM_PTR_SCR2  0x234
/// Default top of stack - the smallest top of stack of all memory modes (ASC1/ASC2/JPN1/JPN2).
#define MEM_STACK_TOP 0xE00

#define ANK_SCREEN_TILES  128
#define SJIS_SCREEN_TILES (28 * 18)
#define TEXT_MODE_ANK 0
#define TEXT_MODE_ANK_SJIS 1
#define TEXT_MODE_SJIS 2

#define BIOS_VERSION_MAJOR 1
#define BIOS_VERSION_MINOR 9
#define BIOS_VERSION_PATCH 99
#define BIOS_VERSION (((BIOS_VERSION_MAJOR) << 12) | ((BIOS_VERSION_MINOR) << 8) | (BIOS_VERSION_PATCH))
#define BIOS_REQUIRED_IRQ_MASK (WS_INT_ENABLE_VBLANK)

#define BIOS_SEGMENT 0xF000

#ifdef OS_ENABLE_128K_SRAM
#define BIOS_SRAM_BANK 1
#else
#define BIOS_SRAM_BANK 3
#endif

#define BIOS_SRAM_CONFIG1 0xFFEE
#define BIOS_SRAM_CONFIG2 0xFFEF
