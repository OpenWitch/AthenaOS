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

#include "../common.inc"

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
    .word error_handle_generic // TODO: text_set_ank_font
    .word error_handle_generic // TODO: text_set_sjis_font
    .word text_get_fontdata
    .word text_set_screen
    .word text_get_screen
    .word error_handle_generic // TODO: cursor_display
    .word error_handle_generic // TODO: cursor_status
    .word error_handle_generic // TODO: cursor_set_location
    .word error_handle_generic // TODO: cursor_get_location
    .word error_handle_generic // TODO: cursor_set_type
    .word error_handle_generic // TODO: cursor_get_type

	.global irq_text_handler
irq_text_handler:
	m_irq_table_handler irq_text_handlers, 16
	iret

    .section ".bss"
    .global text_screen
text_screen: .byte 0
    .global text_mode
text_mode: .byte 0
    .global text_palette
text_palette: .byte 0
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
