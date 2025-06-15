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
#include <wonderful.h>
#include "common.h"
#include "sys/bios.h"
#include "fs/kern_fs.h"
#include "rom_fs.h"

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

static fent_t __far* find_fs_entry(FS fs, const char __seg_ss* filename) {
    int n = fs_n_entries(fs);
    fent_t __far* files = fs_entries(fs);
    for (int i = 0; i < n; i++) {
        if (!strncmp(filename, files[i].name, MAXFNAME)) {
            return &files[i];
        }
    }
    return NULL;
}

IL_FUNCTION
int fs_getent(FS fs, int index, fent_t __far* entry) {
    fent_t buffer;
    volatile uint16_t bank = ws_bank_ram_save(BANK_OSWORK);
    if (index < 0 || index >= fs_n_entries(fs)) {
        ws_bank_ram_restore(bank);
        return E_FS_OUT_OF_BOUNDS;
    }
    fent_t __far* files = fs_entries(fs);
    memcpy(&buffer, files + index, sizeof(fent_t));
    ws_bank_ram_restore(bank);
    memcpy(entry, &buffer, sizeof(fent_t));
    return 0;
}

IL_FUNCTION
__attribute__((optimize("-O0")))
int fs_findent(FS fs, const char __far* filename, fent_t __far* entry) {
    char filename_local[MAXFNAME];
    strncpy(filename_local, filename, MAXFNAME);

    fent_t buffer;
    volatile uint16_t bank = ws_bank_ram_save(BANK_OSWORK);
    fent_t __far* src_entry = find_fs_entry(fs, filename_local);
    if (src_entry == NULL) {
        ws_bank_ram_restore(bank);
        return E_FS_FILE_NOT_FOUND;
    }
    memcpy(&buffer, src_entry, sizeof(fent_t));
    ws_bank_ram_restore(bank);
    memcpy(entry, &buffer, sizeof(fent_t));
    return 0;
}

IL_FUNCTION
void __far * __far fs_mmap(FS fs, const char __far *filename) {
    char filename_local[MAXFNAME];
    strncpy(filename_local, filename, MAXFNAME);

    void __far *result = NULL;
    volatile uint16_t bank = ws_bank_ram_save(BANK_OSWORK);
    if (!(fs->mode & FMODE_MMAP)) {
        fent_t __far* src_entry = find_fs_entry(fs, filename_local);
        if (src_entry != NULL) {
            result = src_entry->loc;
        }
    }
    ws_bank_ram_restore(bank);
    return result;
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
    char filename_local[MAXFNAME];
    strncpy(filename_local, filename, MAXFNAME);

    volatile uint16_t bank = ws_bank_ram_save(BANK_OSWORK);
    if (!(fs->mode & FMODE_W)) {
        ws_bank_ram_restore(bank);
        return E_FS_PERMISSION_DENIED;
    }

    fent_t __far* src_entry = find_fs_entry(fs, filename_local);
    if (src_entry == NULL) {
        ws_bank_ram_restore(bank);
        return E_FS_FILE_NOT_FOUND;
    }

    src_entry->mode = mode;
    ws_bank_ram_restore(bank);
    return E_FS_SUCCESS;
}

IL_FUNCTION
int fs_creat(FS fs, fent_t __far *entry) {
    volatile uint16_t bank = ws_bank_ram_save(BANK_OSWORK);
    if (!(fs->mode & FMODE_W)) {
        ws_bank_ram_restore(bank);
        return E_FS_PERMISSION_DENIED;
    }

    int n = fs_n_entries(fs);
    fent_t __far* files = fs_entries(fs);

    for (int i = 0; i < n; i++) {
        if (files[i].count < 0) {
            memcpy(files + i, entry, sizeof(fent_t));
            ws_bank_ram_restore(bank);
            return E_FS_SUCCESS;
        }
    }

    ws_bank_ram_restore(bank);
    return E_FS_NO_SPACE_LEFT;
}

IL_FUNCTION
int fs_unlink(FS fs, const char __far *filename) {
    char filename_local[MAXFNAME];
    strncpy(filename_local, filename, MAXFNAME);

    volatile uint16_t bank = ws_bank_ram_save(BANK_OSWORK);
    if (!(fs->mode & FMODE_W)) {
        ws_bank_ram_restore(bank);
        return E_FS_PERMISSION_DENIED;
    }

    fent_t __far* src_entry = find_fs_entry(fs, filename_local);
    if (src_entry == NULL) {
        ws_bank_ram_restore(bank);
        return E_FS_FILE_NOT_FOUND;
    }

    src_entry->count = -1;
    src_entry->resource = -1;
    ws_bank_ram_restore(bank);
    return E_FS_SUCCESS;
}

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

    fs->il = il_fs_ptr();
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
    volatile uint16_t bank = ws_bank_ram_save(BANK_OSWORK);
    if (!(fs->mode & FMODE_W)) {
        ws_bank_ram_restore(bank);
        return 0;
    }

    int n = fs_n_entries(fs);
    fent_t __far* files = fs_entries(fs);

    uint32_t max_file_end = ws_ptr_to_linear(fs->loc);
    uint32_t space_end = max_file_end + fs->len;

    for (int i = 0; i < n; i++) {
        if (files[i].count >= 0) {
            uint32_t file_end = ws_ptr_to_linear(files[i].loc) + ((files[i].len + 15) & ~15);
            if (file_end > max_file_end) {
                max_file_end = file_end;
            }
        }
    }

    ws_bank_ram_restore(bank);
    return space_end - max_file_end;
}

// FIXME
__attribute__((optimize("-O0")))
const fent_t *fs_init(void) {
    if (rom_fs_footer->magic != ROM_FS_FOOTER_MAGIC) {
        text_screen_init();
        text_put_string(2, 8, "ROM filesystem not found");
        while(1) ia16_halt();
    }

    fs_newfs(root_fs);
    fs_newfs(rom0_fs);
    fs_newfs(ram0_fs);

    memcpy(rom0_fs_entries,
        MK_FP(rom_fs_footer->rom0_start_segment, 0x0000),
        rom_fs_footer->rom0_count * sizeof(fent_t));

    root_fs->mode = FMODE_DIR | FMODE_MMAP | FMODE_R;

    rom0_fs->loc = MK_FP(0x8000, 0x0000);
    rom0_fs->len = 0x60000;
    rom0_fs->mode = FMODE_DIR | FMODE_R | FMODE_W;

    ram0_fs->loc = MK_FP(0x1000, 0x0000);
    ram0_fs->len = 0x10000;
    ram0_fs->mode = FMODE_DIR | FMODE_MMAP | FMODE_R | FMODE_W;

    kern_fs->il = il_fs_ptr();
    kern_fs->loc = (void __far*) kern_fs_entries;
    kern_fs->len = kern_fs_num_entries * sizeof(fent_t);
    kern_fs->count = kern_fs_num_entries;
    kern_fs->mode = FMODE_DIR | FMODE_R;

    strcpy(ram0_fs->name, "ram0");
    strcpy(rom0_fs->name, "rom0");
    strcpy(kern_fs->name, "kern");

    return rom0_fs_entries + rom_fs_footer->rom0_executable_idx;
}
