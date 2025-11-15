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

	.align 2
irq_text_handlers:
	.word text_screen_init
    .word text_window_init
    .word text_set_mode
    .word text_get_mode
    .word text_put_char
    .word text_put_string
    .word text_put_substring
    .word text_put_numeric
    .word text_fill_char
    .word text_set_palette
    .word text_get_palette
    .word error_handle_irq19 // TODO: text_set_ank_font
    .word text_set_sjis_font
    .word text_get_fontdata
    .word text_set_screen
    .word text_get_screen
    .word cursor_display
    .word cursor_status
    .word cursor_set_location
    .word cursor_get_location
    .word cursor_set_type
    .word cursor_get_type

	.global irq_text_handler
irq_text_handler:
	m_irq_table_handler irq_text_handlers, 22, 0, error_handle_irq19
	iret

    .section ".data"
    .global text_cursor_color
text_cursor_color: .byte 1
    .global text_cursor_rate
text_cursor_rate:  .byte 30
    .global text_screen
text_screen: .byte 1

    .section ".bss"
    .global text_sjis_handler
text_sjis_handler:
    .word 0, 0
    .global text_mode
text_mode: .byte 0
    .global text_color
text_color: .byte 0
    .global text_wx
text_wx: .byte 0
    .global text_wy
text_wy: .byte 0
    .global text_ww
text_ww: .byte 0
    .global text_wh
text_wh: .byte 0
    .global text_base
text_base: .word 0
    .global text_cursor_x
text_cursor_x: .byte 0
    .global text_cursor_y
text_cursor_y: .byte 0
    .global text_cursor_w
text_cursor_w: .byte 0
    .global text_cursor_h
text_cursor_h: .byte 0
    // Bit 0 - is cursor blinking enabled?
    // Bit 1 - is cursor blinking active?
    .global text_cursor_mode
text_cursor_mode: .byte 0
    .global text_cursor_counter
text_cursor_counter: .byte 0