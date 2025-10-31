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

#ifndef _COMMON_H
#define _COMMON_H

#ifndef __ASSEMBLER__
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <sys/bios.h>
#include <sys/filesys.h>
#include <sys/indirect.h>
#include <sys/oswork.h>
#include <sys/process.h>
#endif

#include <wonderful.h>
#include <ws.h>

#define OS_SEGMENT 0xE000

#ifndef __ASSEMBLER__

__attribute__((cdecl))
typedef uint16_t __far (*proc_func_load_t)(void);
__attribute__((cdecl))
typedef void __far (*proc_func_entrypoint_t)(int argc, char **argv);

#define OS_DEFINE_IL(name, type) \
    extern type name; \
    extern uint8_t name ## _end; \
    static inline type __far* name ## _ptr(void) { return MK_FP(OS_SEGMENT, FP_OFF(&name)); };

OS_DEFINE_IL(il_fs, FsIL);
OS_DEFINE_IL(il_ilib, IlibIL);
OS_DEFINE_IL(il_proc, ProcIL);
extern char il_bmpsaver;

#endif

#endif /* _COMMON_H_ */
