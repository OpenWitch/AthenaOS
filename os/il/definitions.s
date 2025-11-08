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
#define ILIB_SEGMENT OS_SEGMENT

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

.macro ILIB_DEFINE_END name
    .global il_\name\()_end
il_\name\()_end:
.endm

ILIB_DEFINE ilib, 2
ILIB_FUNCTION ilib_open
ILIB_FUNCTION ilib_open_system
ILIB_DEFINE_END ilib

ILIB_DEFINE proc, 8
ILIB_FUNCTION proc_load
ILIB_FUNCTION proc_run
ILIB_FUNCTION proc_exec
ILIB_FUNCTION proc_exit
ILIB_FUNCTION proc_yield
ILIB_FUNCTION proc_suspend
ILIB_FUNCTION proc_resume
ILIB_FUNCTION proc_swap
ILIB_DEFINE_END proc

ILIB_DEFINE fs, 18
ILIB_FUNCTION fs_entries
ILIB_FUNCTION fs_n_entries
ILIB_FUNCTION fs_getent
ILIB_FUNCTION fs_findent
ILIB_FUNCTION fs_mmap
ILIB_FUNCTION fs_open
ILIB_FUNCTION fs_close
ILIB_FUNCTION fs_read
ILIB_FUNCTION fs_write
ILIB_FUNCTION fs_lseek
ILIB_FUNCTION fs_chmod
ILIB_FUNCTION fs_freeze
ILIB_FUNCTION fs_melt
ILIB_FUNCTION fs_creat
ILIB_FUNCTION fs_unlink
ILIB_FUNCTION fs_newfs
ILIB_FUNCTION fs_defrag
ILIB_FUNCTION fs_space
ILIB_DEFINE_END fs

ILIB_DEFINE shell, 1
ILIB_FUNCTION shell_launch
ILIB_DEFINE_END shell

#ifdef OS_ENABLE_BUILTIN_BMPSAVER_STUB
// BMPSaver is a library for taking .BMP screenshots of the console display,
// primarily meant for aiding developers. Unfortunately, the public WWGP2002
// release of Dicing Knight mistakenly depends on it, whereas the library
// itself was never made available in .il format outside of the registered
// web portal. This provides a stub which should allow such programs to run
// on these platforms.
ILIB_DEFINE bmpsaver, 8
ILIB_FUNCTION bmpsaver_stub_func
ILIB_FUNCTION bmpsaver_stub_func
ILIB_FUNCTION bmpsaver_stub_func
ILIB_FUNCTION bmpsaver_stub_func
ILIB_FUNCTION bmpsaver_stub_func
ILIB_FUNCTION bmpsaver_stub_func
ILIB_FUNCTION bmpsaver_stub_func
ILIB_FUNCTION bmpsaver_stub_func
ILIB_DEFINE_END bmpsaver

    .global bmpsaver_stub_func
bmpsaver_stub_func:
    mov ax, 0xFFFF
    retf
#endif