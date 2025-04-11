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
#include "common.h"

#define ILIB_SEGMENT 0xE000


.macro ILIB_FUNCTION fun
    .word \fun
    .word ILIB_SEGMENT
.endm

.macro ILIB_DEFINE name, functions
il_\name\()_name: .asciz "\name"
il_\name\()_version: .asciz "0"
il_\name\()_info:
    .word il_\name\()_name, ILIB_SEGMENT
    .word il_\name\()_name, ILIB_SEGMENT
    .word il_\name\()_version, ILIB_SEGMENT
    .word il_\name\()_name, ILIB_SEGMENT
    .word 0, 0

    .global il_\name\()_get_info
il_\name\()_get_info:
    mov dx, cs
    mov ax, il_\name\()_info
    retf

    .global il_\name
il_\name\():
    .word 0, ILIB_SEGMENT
    .word (\functions + 1)
ILIB_FUNCTION il_\name\()_get_info
.endm

ILIB_DEFINE ilib, 2
ILIB_FUNCTION ilib_open
ILIB_FUNCTION ilib_open_system

ILIB_DEFINE proc, 8
ILIB_FUNCTION proc_load
ILIB_FUNCTION proc_run
ILIB_FUNCTION proc_exec
ILIB_FUNCTION proc_exit
ILIB_FUNCTION proc_yield
ILIB_FUNCTION proc_suspend
ILIB_FUNCTION proc_resume
ILIB_FUNCTION proc_swap
