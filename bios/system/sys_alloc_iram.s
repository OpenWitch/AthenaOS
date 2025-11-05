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

/**
 * INT 17h AH=0Fh - sys_alloc_iram
 * Input:
 * - BX = If non-zero, location in IRAM to store pointer to allocated memory in (TODO: validate behaviour)
 * - CX = Bytes to allocate
 * Output:
 * - AX = Near pointer to memory allocated, or 0 on failure
 */
    .global sys_alloc_iram
sys_alloc_iram:
    mov bp, sp
    push bx
    push cx
    push dx
    push si
    push di

#ifdef BIOS_WORKAROUND_DIV_ZERO_VECTOR_CORRUPTION
    // See config.mk for more details.
    ss mov word ptr [0x2], 0xF000
#endif

    // All allocations are 16-byte aligned.
    // TODO: This is wasteful, but good enough to run.
    add cx, 15

    // DX = handle to set
    mov dx, [bp + IRQ_TABLE_HANDLER_CS_OFFSET]
    // BP = current heap location
    mov bp, offset __heap_start
    // SI = position of found block
    // DI = size of found block
    xor si, si
    mov di, 0xFFFF

    // iterate through all blocks
1:
    cmp word ptr [bp], 0xFFFF
    jne 8f // block allocated

    // block not allocated
    push bp
    add bp, [bp + 2] // advance to next heap block
    add bp, 4
    cmp bp, offset __heap_end
    jae 2f // end of heap
    cmp word ptr [bp], 0xFFFF
    mov bx, [bp + 2] // BX = next block size
    jne 2f // next block not empty

    // merge blocks
    pop bp
    add bx, 4
    add [bp + 2], bx // block size = block size + next block size + block header size
    jmp 1b

2:
    pop bp

    mov bx, [bp + 2] // BX = current block size
    cmp bx, cx
    jb 8f // too small
    cmp bx, di
    jae 8f // larger than previous best find
    mov di, bx
    mov si, bp
    cmp bx, cx
    je 9f // equal to searched for block, stop here

8:
    add bp, [bp + 2] // advance to next heap block
    add bp, 4
    cmp bp, offset __heap_end
    jb 1b // did not find end of heap

9:
    // SI = position of found block
    // DI = size of found block
    xor ax, ax
    test si, si
    jz 9f // if SI == 0, we did not find block

    // initialize new block
    mov bp, si
    mov bx, [bp + 2] // BX = current block size
    add cx, 4
    cmp di, cx
    jbe 2f // reallocate block straight

    // add new block
    sub di, cx
    push bp
    add bp, cx
    mov word ptr [bp], 0xFFFF
    mov [bp + 2], di
    pop bp
    sub cx, 4
    mov [bp + 2], cx

2:
    // set handle on block
    mov [bp], dx

    // AX = pointer to memory allocated
    mov ax, bp
    add ax, 4

9:
    pop di
    pop si
    pop dx
    pop cx
    pop bx

    // Align pointer to 16 bytes
    add ax, 15
    and ax, 0xFFF0

    test bx, bx
    jz 9f

    // Store pointer in IRAM
    mov ss:[bx], ax
    mov word ptr ss:[bx+2], 0
9:
    ret
