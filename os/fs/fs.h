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

#include "common.h"

IL_FUNCTION
fent_t __far* __far fs_entries(FS fs);

IL_FUNCTION
int fs_n_entries(FS fs);

IL_FUNCTION
int fs_getent(FS fs, int index, fent_t __far* entry);

IL_FUNCTION
int fs_findent(FS fs, const char __far* filename, fent_t __far* entry);

IL_FUNCTION
void __far * __far fs_mmap(FS fs, const char __far *filename);

IL_FUNCTION
int fs_open(FS fs, const char __far *filename, int mode, int perms);

IL_FUNCTION
int fs_close(int fd);

IL_FUNCTION
int fs_read(int fd, char __far *data, int length);

IL_FUNCTION
int fs_write(int fd, const char __far *data, int length);

IL_FUNCTION
int fs_lseek(int fd, long offset, int whence);

IL_FUNCTION
int fs_chmod(FS fs, const char __far *filename, int mode);

IL_FUNCTION
int fs_freeze(FS fs, const char __far *filename);

IL_FUNCTION
int fs_melt(FS fs, const char __far *filename);

IL_FUNCTION
int fs_creat(FS fs, fent_t __far *entry);

IL_FUNCTION
int fs_unlink(FS fs, const char __far *filename);

IL_FUNCTION
int fs_newfs(FS fs);

IL_FUNCTION
int fs_defrag(FS fs);

IL_FUNCTION
uint32_t fs_space(FS fs);

const fent_t *fs_init(void); 
