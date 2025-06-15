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

owner_name_to_ascii_table:
    .ascii " 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    .byte 3  // Heart
    .byte 13 // Music note
    .ascii "+-?."

    // transforms - AL/AH = data, BX/CX = temporary 
    // transform using ASCII table
transform_name_to_ascii_table:
    xor bx, bx
    mov bl, al
    cs mov al, [owner_name_to_ascii_table + bx]
    mov bl, ah
    cs mov ah, [owner_name_to_ascii_table + bx]
transform_none:
    ret

    // transform one 16-bit BCD number to int
transform_bcd16:
    push ax
    call __bcd_to_bin_al
    mov bx, ax
    pop ax
    mov al, ah
    call __bcd_to_bin_al
    // AX = lower 0-99, BX = upper 0-99
    imul bx, 100 // BX = BX * 100
    add ax, bx
    ret

    // transform two 8-bit BCD numbers to int
transform_bcd8:
    push ax
    call __bcd_to_bin_al
    mov bl, al
    pop ax
    mov al, ah
    call __bcd_to_bin_al
    mov ah, al
    mov al, bl
    ret

sys_get_ownerinfo_transforms:
    .word transform_name_to_ascii_table
    .word transform_name_to_ascii_table
    .word transform_name_to_ascii_table
    .word transform_name_to_ascii_table
    .word transform_name_to_ascii_table
    .word transform_name_to_ascii_table
    .word transform_name_to_ascii_table
    .word transform_name_to_ascii_table
    .word transform_bcd16
    .word transform_bcd8
    .word transform_none

/**
 * INT 17h AH=0Ah - sys_get_ownerinfo
 * Input:
 * - CX = Size of data to read, in bytes
 * - DS:DX = Output buffer
 * Output:
 * - AX = 0 if successful
 */
    .global sys_get_ownerinfo
sys_get_ownerinfo:
    push bx
    push cx
    push dx
    push di
    push es

    cmp cx, 22
    jbe 1f
    mov cx, 22 // 22 = maximum read length
1:
    // DS:DX => ES:DI
    push ds
    pop es
    mov di, dx
    
    // DX = command
    mov dx, 0x0180
    in al, WS_SYSTEM_CTRL_COLOR_PORT
    test al, WS_SYSTEM_CTRL_COLOR_FEAT_COLOR
    jz 1f
    shl dx, 4 // shift left by 4 for WSC
1:
    or dx, (0x60 >> 1) // add starting address to command

    mov bx, cx // BX = bytes to read
    xor bp, bp // BP = offset

2:
    test bx, bx
    jz 8f // out of bytes to read?
    mov ax, dx
    out WS_IEEP_COMMAND_PORT, ax
    mov ax, WS_IEEP_CTRL_READ
    out WS_IEEP_CTRL_PORT, ax
    mov cx, 3413 // CX = timeout - 10 ms / 9 cycles at 3 MHz
3:
    // query read status
    in ax, WS_IEEP_CTRL_PORT
    test al, WS_IEEP_CTRL_READY
    jnz 4f
    loop 3b
    // return timeout
    mov ax, 0x8101
    jmp 9f
4:
    // read successful
    in ax, WS_IEEP_DATA_PORT

    // transform data (name -> ASCII, BCD -> int)
    push bx
    cs call [sys_get_ownerinfo_transforms + bp]
    add bp, 2
    inc dx
    pop bx

    // write byte or word to buffer
    cmp bx, 1
    jnz 5f // more than one byte left?
    stosb // write final byte
    jmp 8f
5:
    stosw // write word
    sub bx, 2
    jmp 2b

8:
    xor ax, ax // return success
9:
    // finish
    pop es
    pop di
    pop dx
    pop cx
    pop bx
    ret
