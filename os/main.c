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

#include "common.h"
#include "il/proc.h"

#define PROGRAM_SEGMENT 0x8008 /* 128 bytes after 0x80000 */

extern uint8_t il_ilib;
extern uint8_t il_proc;

int main(void) {
    outportb(IO_BANK_RAM, SRAM_BANK_PROG1);

    proc_func_load_t start_func = MK_FP(PROGRAM_SEGMENT, 0);
    uint16_t main_func_ofs = start_func();

    pcb_t *pcb = (pcb_t*) 0x0000;
    pcb->ilib = MK_FP(_CS, &il_ilib);
    pcb->proc = MK_FP(_CS, &il_proc);
    pcb->cwd[0] = 0;
    uint32_t resource_bytes = *((uint32_t __far*) MK_FP(PROGRAM_SEGMENT - 4, 60));
    pcb->resource = MK_FP(PROGRAM_SEGMENT + (resource_bytes >> 4), resource_bytes & 0xF);

    proc_run(MK_FP(PROGRAM_SEGMENT, main_func_ofs), 0, NULL);

    return 0;
}
