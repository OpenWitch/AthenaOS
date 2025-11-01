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

const char __far rom0_path[] = "/rom0";

static void init_proc_context(void) {
    _pc->_ilib = il_ilib_ptr();
    _pc->_proc = il_proc_ptr();
    _pc->_cwfs = rom0_fs;
    strcpy(_pc->_currentdir, rom0_path);
}

int main(void) {
    ws_bank_ram_set(BANK_OSWORK);
    init_proc_context();

    sramwork._os_version = 0x1963; // version 1.9.99

    // Post-FreyaOS memory initialization
    if (ws_system_is_color_model()) {
        ws_system_set_mode(WS_MODE_COLOR);
        // Software by Nagtoshop depends on the background color being set.
        WS_DISPLAY_COLOR_MEM(0)[0] = 0xFFF;
        // Software by Nagtoshop depends on tile 4 being clear.
        memset(WS_TILE_MEM(4), 0, 16);
        // Tiles 0 and 1 are also typically clear.
        memset(WS_TILE_MEM(0), 0, 32);
        ws_system_set_mode(WS_MODE_MONO);
    }

    const fent_t *executable = fs_init();
    uint16_t exec_segment = FP_SEG(executable->loc);

    sys_alloc_iram((void*) 0x204, 194);

    void __far *exec_resource = NULL;
    if (executable->resource != -1) {
        exec_resource = MK_FP(exec_segment + (executable->resource >> 4), executable->resource & 0xF);
    }

    ws_bank_ram_set(BANK_USERDS0);

    proc_func_load_t start_func = MK_FP(exec_segment, 0);
    uint16_t main_func_ofs = start_func();

    init_proc_context();
    _pc->_resource = exec_resource;

    proc_run(MK_FP(exec_segment, main_func_ofs), 0, NULL);

    while(1);
}
