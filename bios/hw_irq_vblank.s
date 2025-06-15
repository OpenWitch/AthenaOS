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

    .global hw_irq_vblank_handler
hw_irq_vblank_handler:
    push ax
    push bx
    push cx
    push ds
    push ss
    pop ds

    // === TICK COUNTER ===

    // Increment tick counter
    add word ptr [tick_count], 1
    adc word ptr [tick_count+2], 0

    // === KEY PRESS HANDLER ===

    // Scan key presses
    call __key_scan

    // Update key variables
    mov ax, word ptr [keys_held]
    not ax
    and ax, cx
    // AX = keys pressed
    // CX = keys held
    or word ptr [keys_pressed], ax
    mov word ptr [keys_held], cx
    // Process repeat:
    // - If new key pressed, reset timer to delay
    // - Otherwise:
    //   - Decrease timer by 1
    //   - If timer == 0, reset timer to rate and set pressed keys to held keys
    test ax, ax
    jz 1f

    // New key pressed
    mov bl, byte ptr [key_repeat_delay]
    mov byte ptr [key_repeat_timer], bl
    jmp 2f
1:
    // No new key pressed
    dec byte ptr [key_repeat_timer]
    // Timer still ticking?
    jnz 2f
    // Reset timer
    mov bl, byte ptr [key_repeat_rate]
    mov byte ptr [key_repeat_timer], bl
    // Set pressed keys to held keys
    mov ax, cx
2:
    or word ptr [keys_pressed_repeat], ax

    // === CURSOR HANDLER ===
    // AL = mode, AH = counter
    mov ax, [text_cursor_mode]
    test al, 0x1
    jz .vbl_cursor_not_enabled

    test ah, ah
    jz .vbl_cursor_action
    
    dec ah
    mov [text_cursor_counter], ah
    jmp 9f

.vbl_cursor_action:
    mov ah, [text_cursor_rate]
    test ah, ah
    jnz 1f // If not zero, count down

    // If zero, always fill
    or al, 0x2
    mov [text_cursor_mode], ax
    jmp .vbl_cursor_fill

1:
    dec ah
    xor al, 0x2
    mov [text_cursor_mode], ax

    test al, 0x2
    jz .vbl_cursor_clear // Cursor no longer filled => clear

.vbl_cursor_fill:
    push dx
    mov dl, [text_cursor_color]
    jmp 8f

.vbl_cursor_not_enabled:
    test al, 0x2
    jz 9f // Cursor not filled?

    and al, 0x1
    mov [text_cursor_mode], al

.vbl_cursor_clear:
    push dx
    mov dl, [text_color]
8:
    call __cursor_fill
    pop dx

9:
    // === USER IRQ ROUTINE ===

    pop ds
    pop cx
    
    mov al, WS_INT_ENABLE_VBLANK
    mov bx, offset (hw_irq_hook_table + (WS_INT_VBLANK * 8))
    call irq_wrap_routine

    pop bx
    pop ax
    iret

    .section ".data"
    .global key_repeat_rate
key_repeat_rate:  .byte 5  // ~65ms
    .global key_repeat_delay
key_repeat_delay: .byte 15 // ~200ms

    .section ".bss"
    .global tick_count
tick_count: .word 0, 0
    .global keys_held
keys_held: .word 0
    .global keys_pressed
keys_pressed: .word 0
    .global keys_pressed_repeat
keys_pressed_repeat: .word 0
    .global key_repeat_timer
key_repeat_timer:  .byte 0
