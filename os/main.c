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
#include "common.h"
#include "fs/fs.h"
#include "il/ilib.h"
#include "il/proc.h"
#include "sys/bios.h"

__attribute__((section(".sramwork")))
SRAMWork sramwork;

int main(void) {
    sramwork._os_version = 0x1963; // version 1.9.99

    outportb(IO_BANK_RAM, BANK_OSWORK);

    const fent_t *executable = fs_init();
    uint16_t exec_segment = FP_SEG(executable->loc);

    sys_alloc_iram((void*) 0x204, 194);

    outportb(IO_BANK_RAM, BANK_USERDS0);

    proc_func_load_t start_func = MK_FP(exec_segment, 0);
    uint16_t main_func_ofs = start_func();

    _pc->_ilib = il_ilib_ptr();
    _pc->_proc = il_proc_ptr();
    _pc->_cwfs = rom0_fs;
    strcpy(_pc->_currentdir, "/rom0");
    uint32_t resource_bytes = *((uint32_t __far*) MK_FP(exec_segment - 4, 60));
    _pc->_resource = MK_FP(exec_segment + (resource_bytes >> 4), resource_bytes & 0xF);

    proc_run(MK_FP(exec_segment, main_func_ofs), 0, NULL);

    while(1);
}
