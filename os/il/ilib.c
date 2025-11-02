/**
 * Copyright (c) 2025 Adrian "asie" Siekierka
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

__attribute__((optimize("-O0")))
static int __ilib_open(FS fs, const char __far* name, void __far* il_buffer) {
    fent_t entry;

    if (fs_findent(fs, name, &entry) >= 0) {
        IL __far* il = (IL __far*) entry.loc;
        if (il == NULL) return E_FS_ERROR;

        size_t il_len = sizeof(IL) - 4 + il->n_methods * 4;
        memcpy(il_buffer, il, il_len);
        for (int i = 0; i < il->n_methods; i++) {
            // FIXME: This is a bit of a hack...
            uint16_t il_seg = ((uint16_t __far*) il_buffer)[4 + 2 * i];
            if (il_seg < OS_SEGMENT)
                il_seg += FP_SEG(il);
            ((uint16_t __far*) il_buffer)[4 + 2 * i] = il_seg;
        }
        return 0;
    }
    
    return E_FS_ERROR;
}

IL_FUNCTION
int ilib_open_system(const char __far* name, void __far* il_buffer) {
    return __ilib_open(kern_fs, name, il_buffer);
}

IL_FUNCTION
int ilib_open(const char __far* name, void __far* il_buffer) {
    int result = __ilib_open(rom0_fs, name, il_buffer);
    if (result >= 0)
        return result;
    return ilib_open_system(name, il_buffer);
}
