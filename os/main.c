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

#include <string.h>
#include <ws.h>
#include "common.h"
#include "fs/fs.h"
#include "il/ilib.h"
#include "il/proc.h"

__attribute__((section(".sramwork")))
SRAMWork sramwork;

static const char __far shell_name[] = "@shell";

extern const uint8_t __bss_end;

void main(void) {
    _pc->_ilib = il_ilib_ptr();
    _pc->_proc = il_proc_ptr();
    _pc->_cwfs = rom0_fs;
    _pc->_argv = &__bss_end;
    sramwork._os_version = 0x1963; // OS version 1.9.99

    ShellIL il;
    ilib_open(shell_name, &il);
    proc_run(il._launch, 0, NULL);
}
