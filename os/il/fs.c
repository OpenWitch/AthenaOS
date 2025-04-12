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
#include "sys/bios.h"

static const fent_t kern_fs_entries[] = {
    {"@ilib", "ilib", __builtin_ia16_static_far_cast(&il_ilib), 0, 0, FMODE_ILIB | FMODE_R, 0, NULL, 0xFFFFFFFF},
    {"@proc", "proc", __builtin_ia16_static_far_cast(&il_proc), 0, 0, FMODE_ILIB | FMODE_R, 0, NULL, 0xFFFFFFFF},
    {"@pfs",  "pfs",  __builtin_ia16_static_far_cast(&il_fs),   0, 0, FMODE_ILIB | FMODE_R, 0, NULL, 0xFFFFFFFF},
};
#define kern_fs_num_entries (sizeof(kern_fs_entries) / sizeof(fent_t))

IL_FUNCTION
fent_t __far* __far fs_entries(FS fs) {
    if (fs == root_fs) {
        return root_fs_entries;
    }
    if (fs == ram0_fs) {
        return ram0_fs_entries;
    }
    if (fs == rom0_fs) {
        return rom0_fs_entries;
    }
    if (fs == kern_fs) {
        return (fent_t __far*) kern_fs_entries;
    }
    return NULL;
}

IL_FUNCTION
int fs_n_entries(FS fs) {
    if (fs == root_fs) {
        return ROOTFS_NUM_ENTRIES;
    }
    if (fs == ram0_fs) {
        return RAM0FS_NUM_ENTRIES;
    }
    if (fs == rom0_fs) {
        return ROM0FS_NUM_ENTRIES;
    }
    if (fs == kern_fs) {
        return kern_fs_num_entries;
    }
    return 0;
}

IL_FUNCTION
int fs_getent(FS fs, int index, fent_t __far* entry) {
    fent_t buffer;
    volatile uint16_t bank = ws_bank_ram_save(BANK_OSWORK);
    fent_t __far* files = fs_entries(fs);
    memcpy(&buffer, files + index, sizeof(fent_t));
    ws_bank_ram_restore(bank);
    memcpy(entry, &buffer, sizeof(fent_t));
    return 0;
}

IL_FUNCTION
int fs_findent(FS fs, const char __far* filename, fent_t __far* entry) {
    fent_t buffer;
    volatile uint16_t bank = ws_bank_ram_save(BANK_OSWORK);
    int n = fs_n_entries(fs);
    fent_t __far* files = fs_entries(fs);
    for (int i = 0; i < n; i++) {
        if (!strncmp(filename, files[i].name, MAXFNAME)) {
            memcpy(&buffer, files + i, sizeof(fent_t));
            ws_bank_ram_restore(bank);
            memcpy(entry, &buffer, sizeof(fent_t));
            return 0;
        }
    }
    ws_bank_ram_restore(bank);
    return E_FS_FILE_NOT_FOUND;
}

IL_FUNCTION
void __far * __far fs_mmap(FS fs, const char __far *filename) {
    fent_t buffer;
    if (fs_findent(fs, filename, &buffer) >= 0) {
        if (!(buffer.mode & FMODE_MMAP)) {
            return buffer.loc;
        }
    }
    return NULL;
}

IL_FUNCTION
int fs_open(FS fs, const char __far *filename, int mode, int perms) {
    // TODO
    return E_FS_ERROR;
}

IL_FUNCTION
int fs_close(int fd) {
    // TODO
    return E_FS_ERROR;
}

IL_FUNCTION
int fs_read(int fd, char __far *data, int length) {
    // TODO
    return E_FS_ERROR;
}

IL_FUNCTION
int fs_write(int fd, const char __far *data, int length) {
    // TODO
    return E_FS_ERROR;
}

IL_FUNCTION
int fs_lseek(int fd, long offset, int whence) {
    // TODO
    return E_FS_ERROR;
}

IL_FUNCTION
int fs_chmod(FS fs, const char __far *filename, int mode) {
    // TODO
    return E_FS_ERROR;
}

IL_FUNCTION
int fs_freeze(FS fs, const char __far *filename) {
    // stub?
    return E_FS_ERROR;
}

IL_FUNCTION
int fs_melt(FS fs, const char __far *filename) {
    // stub?
    return E_FS_ERROR;
}

IL_FUNCTION
int fs_creat(FS fs, fent_t __far *entry) {
    // TODO
    return E_FS_ERROR;
}

IL_FUNCTION
int fs_unlink(FS fs, const char __far *filename) {
    // TODO
    return E_FS_ERROR;
}

#define IL_FS_P MK_FP(OS_SEGMENT, FP_OFF(&il_fs))

IL_FUNCTION
int fs_newfs(FS fs) {
    volatile uint16_t bank = ws_bank_ram_save(BANK_OSWORK);

    int n = fs_n_entries(fs);
    fent_t __far* files = fs_entries(fs);

    memset(files, 0, sizeof(fent_t) * n);
    for (int i = 0; i < n; i++) {
        files[i].count = -1;
        files[i].resource = -1;
    }

    fs->il = IL_FS_P;
    fs->count = n;

    ws_bank_ram_restore(bank);
    return E_FS_SUCCESS;
}

IL_FUNCTION
int fs_defrag(FS fs) {
    // TODO
    return E_FS_SUCCESS;
}

IL_FUNCTION
uint32_t fs_space(FS fs) {
    // TODO
    return 999999;
}

void fs_init(void) {
    fs_newfs(root_fs);
    fs_newfs(rom0_fs);
    fs_newfs(ram0_fs);

    root_fs->mode = FMODE_DIR | FMODE_MMAP | FMODE_R;

    rom0_fs->loc = MK_FP(0x8000, 0x0000);
    rom0_fs->len = 0x60000;
    rom0_fs->mode = FMODE_DIR | FMODE_R;

    ram0_fs->loc = MK_FP(0x1000, 0x0000);
    ram0_fs->len = 0x10000;
    ram0_fs->mode = FMODE_DIR | FMODE_MMAP | FMODE_R | FMODE_W;

    kern_fs->il = IL_FS_P;
    kern_fs->loc = MK_FP(OS_SEGMENT, FP_OFF(&kern_fs_entries));
    kern_fs->len = sizeof(kern_fs_entries);
    kern_fs->count = kern_fs_num_entries;
    kern_fs->mode = FMODE_DIR | FMODE_R;

    strcpy(ram0_fs->name, "ram0");
    strcpy(rom0_fs->name, "rom0");
    strcpy(kern_fs->name, "kern");
}
