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

// Wrap around ROM indexes to support larger cartridges
.macro bank_adjust_wraparound_rom_end reg_bx
#if BIOS_BANK_ROM_FORCE_COUNT > 0
    or \reg_bx, (0xFFFF - BIOS_BANK_ROM_FORCE_COUNT)
1:
#endif
.endm

// Wrap around ROM indexes to support larger cartridges
.macro bank_adjust_wraparound_rom_start reg_bx
#if BIOS_BANK_ROM_FORCE_COUNT > 0
    and \reg_bx, (BIOS_BANK_ROM_FORCE_COUNT - 1)
1:
#endif
.endm

// Wrap around ROM indexes to support larger cartridges
// (bank_set_map variant)
.macro bank_adjust_wraparound_set_map reg_bl, reg_cx
#if BIOS_BANK_ROM_FORCE_COUNT > 0
    test \reg_bl, \reg_bl
    jz 1f // SRAM - skip

    bank_adjust_wraparound_rom_end \reg_cx
1:
#endif
.endm

// Wrap around ROM indexes to support larger cartridges
// (bank_get_map variant)
.macro bank_adjust_wraparound_get_map reg_bl, reg_cx
#if BIOS_BANK_ROM_FORCE_COUNT > 0
    test \reg_bl, \reg_bl
    jz 1f // SRAM - skip

    bank_adjust_wraparound_rom_start \reg_cx
1:
#endif
.endm

// bank_get_map/bank_set_map helpers
#ifdef BIOS_BANK_MAPPER_2003
.macro bank_map_dx_unsafe
    add dl, dl
    add dl, 0xD0
.endm
.macro bank_map_dx
    xor dh, dh
    add dl, dl
    add dl, 0xD0
    cmp dl, 0xD4
    ja 1f
.endm
.macro bank_map_read_ax_dx
    in ax, dx
.endm
.macro bank_map_write_ax_dx
    out dx, ax
.endm
.macro bank_map_read_ax_sram
    in ax, 0xD0
.endm
.macro bank_map_write_ax_sram
    out 0xD0, ax
.endm
#else
.macro bank_map_dx_unsafe
    add dl, 0xC1
.endm
.macro bank_map_dx
    xor dh, dh
    add dl, 0xC1
    cmp dl, 0xC3
    ja 1f
.endm
.macro bank_map_read_ax_dx
    in al, dx
.endm
.macro bank_map_write_ax_dx
    out dx, al
.endm
.macro bank_map_read_ax_sram
    in al, 0xC1
.endm
.macro bank_map_write_ax_sram
    out 0xC1, al
.endm
#endif

    // bank_read/bank_write wrappers
    // Clobber AX, BX, DX, BP.
    // DX must remain unchanged between start and end
#ifdef BIOS_BANK_MAPPER_NO_PORT_CE_SUPPORT
.macro bank_rw_bx_to_segment_start segment_reg
    // Set DX to target port
    mov dx, bx
    shr dx, 15
    mov bp, dx
    bank_map_dx_unsafe

    // Preserve old target bank
    bank_map_read_ax_dx
    push ax

#if BIOS_BANK_ROM_FORCE_COUNT > 0
    test bh, 0x80
    jz 1f // SRAM - skip

    bank_adjust_wraparound_rom_end bx
1:
#endif

    // Write new target bank
    mov ax, bx
    bank_map_write_ax_dx

    // Set segment register to target
    mov ax, bp
    shl ax, 12
    add ax, 0x1000
    mov \segment_reg, ax
.endm
.macro bank_rw_bx_to_segment_end_unsafe
    // Restore old target bank
    pop ax
    bank_map_write_ax_dx
.endm
#else
.macro bank_rw_bx_to_segment_start segment_reg
    // Preserve old SRAM bank
    bank_map_read_ax_sram
    push ax

#if BIOS_BANK_ROM_FORCE_COUNT > 0
    test bh, 0x80
    jz 1f // SRAM - skip

    bank_adjust_wraparound_rom_end bx
1:
#endif

    // Write new SRAM bank
    mov ax, bx
    bank_map_write_ax_sram

    shr ax, 15
    out 0xCE, al

    // Set segment register to 0x1000
    mov ax, 0x1000
    mov \segment_reg, ax
.endm
.macro bank_rw_bx_to_segment_end_unsafe
    xor ax, ax
    out 0xCE, al

    // Restore old SRAM bank
    pop ax
    bank_map_write_ax_sram
.endm
#endif
.macro bank_rw_bx_to_segment_end
    // Restore old SRAM bank
    mov bp, ax
    bank_rw_bx_to_segment_end_unsafe
    mov ax, bp
.endm

.macro bank_rw_bx_to_sram_segment_start segment_reg
    // Preserve old SRAM bank
    bank_map_read_ax_sram
    push ax

    // Write new SRAM bank
    mov ax, bx
    bank_map_write_ax_sram

    // Set segment register to 0x1000
    mov ax, 0x1000
    mov \segment_reg, ax
.endm
.macro bank_rw_bx_to_sram_segment_end
    // Restore old SRAM bank
    pop ax
    bank_map_write_ax_sram
.endm