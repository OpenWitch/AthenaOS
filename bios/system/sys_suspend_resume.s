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

__sys_slot_to_address:
    inc al
    mov ah, 0x41
    mul ah
    xchg ah, al
    neg ax
    ret

/**
 * INT 17h AH=0Bh - sys_suspend
 * Input:
 * - AL = slot
 * - DS:BX = I/O resume table
 * Output:
 * - AX = 0/1?
 */
    .global sys_suspend
sys_suspend:
    call __sys_slot_to_address

    pusha
    push ss
    push sp
    push cx

    // ES:DI => suspend target
    mov di, ax
    mov ax, 0x1000
    mov es, ax

    cli

    // Store mono IRAM
    push ds
    push ss
    pop ds
    mov cx, (0x4000 >> 1)
    xor si, si
    rep movsw
    pop ds

    // Store I/O table pointer, check if table present
    mov al, [bx]
    inc bx

    mov ax, bx
    stosw
    mov ax, ds
    stosw

    xor dx, dx
    mov cx, (0xE0 >> 1)
    cmp al, 'I'
    jne __sys_suspend_no_io_table

    xor ax, ax
1:
    inc bx
    test byte ptr [bx], 0x01
    jnz 2f
    // if bit 0 clear, store zeroes
    stosw
    jmp 3f
2:
    // if bit 0 set, read I/O port
    insw
3:
    inc dx
    inc dx
    loop 1b
	
__sys_suspend_after_io:
    // Store CX, SP, SS
    pop ax
    stosw
    pop ax
    stosw
    pop ax
    stosw

    sti

    popa
    xor ax, ax
    ret

__sys_suspend_no_io_table:
1:
    insw
    inc dx
    inc dx
    loop 1b
    jmp __sys_suspend_after_io

/**
 * INT 17h AH=0Ch - sys_resume
 * Input:
 * - AL = slot
 * Output:
 * - AX = 0/1?
 */
    .global sys_resume
sys_resume:
    dec al // ???
    call __sys_slot_to_address

    // DS:SI => suspend target
    mov si, ax
    mov ax, 0x1000
    mov ds, ax

    cli

    // Load mono IRAM
    push ss
    pop es
    mov cx, (0x4000 >> 1)
    xor di, di
    rep movsw

    // Read I/O table pointer, check if table present
    lodsw
    mov bx, ax
    lodsw
    mov es, ax

    es mov al, [bx]
    xor dx, dx
    mov cx, (0xE0 >> 1)
    cmp al, 'O'
    jne __sys_resume_no_io_table

1:
    lodsw
    es test byte ptr [bx], 0x01
    jz 2f
    // if bit 0 set, write to I/O port
    out dx, ax
2:
    inc dx
    inc dx
    loop 1b

__sys_resume_after_io:
    // Read CX, SP, SS
    lodsw
    mov cx, ax
    lodsw
    mov sp, ax
    lodsw
    mov ss, ax

    sti
   
    // SP is now equal to the value after PUSH SP
    add sp, 4

    popa
    mov ax, 1
    ret

__sys_resume_no_io_table:
1:
    outsw
    inc dx
    inc dx
    loop 1b
    jmp __sys_resume_after_io
