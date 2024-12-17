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

    // Input:
    // - BH = awaited mask (any bit)
    // - CX = timeout
    // Output:
    // - AH = 0 if success, 1 if timeout, 2 if overrun, 3 if cancel
    // - AL = (serial status & BH)
    // Clobber: AX
    //
    // TODO: Halt CPU while waiting for serial input.
    // Note that the serial send/receive interrupts will loop
    // indefinitely until the byte is sent/received.
    
    .global __comm_wait_timeout
__comm_wait_timeout:
    pushf
    push dx

    ss mov dx, [tick_count]
    add dx, cx // DX = final tick count

1:
    xor ax, ax
    in al, IO_SERIAL_STATUS
    and al, bh
    jnz 8f // received mask?

    cmp cx, 0xFFFF
    je 2f // skip timeout?

    test cx, cx
    jz 7f // zero timeout?
    ss cmp dx, [tick_count]
    jle 7f // timeout?

2:
    // Enable interrupts
    // As we could be calling a send/receive function from an IRQ, this has to
    // be done after the data being present is ruled out.
    sti

    // check for cancel key
    ss mov ax, [comm_cancel_key]
    test ax, ax
    jz 1b // cancel key not set?
    ss and ax, [keys_held]
    ss cmp ax, [comm_cancel_key]
    jne 1b // cancel key combo not matched?

    mov ah, 3 // return cancel
    jmp 9f

7:
    mov ah, 1 // return timeout
    jmp 9f

8:
    test al, SERIAL_OVERRUN
    jz 9f // not overrun? (only checked if overrun in mask)
    mov ah, 2 // return overrun

9:
    pop dx
    popf
    ret

