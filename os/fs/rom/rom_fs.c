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

#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <wonderful.h>
#include <ws/memory.h>
#include "common.h"
#include "sys/bios.h"
#include "fs/kern_fs.h"
#include "rom_fs.h"

#define fhandle(fd) (sramwork_p->_openfiles[(fd)])

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
    ws_bank_with_ram(BANK_OSWORK, {
        if (index < 0 || index >= fs_n_entries(fs)) {
            return E_FS_OUT_OF_BOUNDS;
        }
        fent_t __far* files = fs_entries(fs);
        memcpy(&buffer, files + index, sizeof(fent_t));
    });
    memcpy(entry, &buffer, sizeof(fent_t));
    return 0;
}

IL_FUNCTION
__attribute__((optimize("-O0")))
int fs_findent(FS fs, const char __far* filename, fent_t __far* entry) {
    char filename_local[MAXFNAME];
    strncpy(filename_local, filename, MAXFNAME);

    fent_t buffer;
    ws_bank_with_ram(BANK_OSWORK, {
        fent_t __far* src_entry = find_fs_entry(fs, filename_local);
        if (src_entry == NULL) {
            return E_FS_FILE_NOT_FOUND;
        }
        memcpy(&buffer, src_entry, sizeof(fent_t));
    });
    memcpy(entry, &buffer, sizeof(fent_t));
    return 0;
}

IL_FUNCTION
void __far * __far fs_mmap(FS fs, const char __far *filename) {
    char filename_local[MAXFNAME];
    strncpy(filename_local, filename, MAXFNAME);

    void __far *result = NULL;
    ws_bank_with_ram(BANK_OSWORK, {
        if (!(fs->mode & FMODE_MMAP)) {
            fent_t __far* src_entry = find_fs_entry(fs, filename_local);
            if (src_entry != NULL) {
                result = src_entry->loc;
            }
        }
    });
    return result;
}

IL_FUNCTION
int fs_open(FS fs, const char __far *filename, int mode, int perms) {
    char filename_local[MAXFNAME];
    strncpy(filename_local, filename, MAXFNAME);

    ws_bank_with_ram(BANK_OSWORK, {
        if (mode & ~fs->mode) 
            return E_FS_PERMISSION_DENIED;

        int free_fd;
        for (free_fd = 0; free_fd < MAXFILES; free_fd++)
            if (fhandle(free_fd).ent == NULL) break;
        if (free_fd == MAXFILES)
            return E_FS_OUT_OF_BOUNDS;
    
        fent_t __far* src_entry = find_fs_entry(fs, filename_local);
        if (src_entry == NULL)
            return E_FS_FILE_NOT_FOUND;

        fhandle_t *h = &fhandle(free_fd);
        h->fs = fs;
        h->ent = src_entry;
        h->mode = mode;
        h->loc.fp = src_entry->loc;
        h->len = src_entry->len;
        h->count = src_entry->count;
        h->pos = 0;
        
        return E_FS_SUCCESS;
    });
}

IL_FUNCTION
int fs_close(int fd) {
    if (fd < 0 || fd >= MAXFILES)
        return E_FS_OUT_OF_BOUNDS;

    ws_bank_with_ram(BANK_OSWORK, {
        if (fhandle(fd).ent == NULL)
            return E_FS_FILE_NOT_OPEN;
        fhandle(fd).ent = NULL;
        return E_FS_SUCCESS;
    });
}

#define PTR_IN_SRAM(ptr) ((FP_SEG((ptr)) & 0xF000) == 0x1000)

static void fs_safe_memcpy(char __far* dst, const char __far* src, int len, bool to_fs) {
    if (PTR_IN_SRAM(src) && PTR_IN_SRAM(dst)) {
        // data in PSRAM, slow copy path

        ws_bank_t orig_bank = ws_bank_ram_get(), src_bank, dst_bank;
        if (to_fs) {
            src_bank = orig_bank;
            dst_bank = BANK_SOFTFS;
        } else {
            src_bank = BANK_SOFTFS;
            dst_bank = orig_bank;
            ws_bank_ram_set(src_bank);
        }

        for (int i = 0; i < len; i++) {
            char tmp = src[i];
            ws_bank_ram_set(dst_bank);
            dst[i] = tmp;
            ws_bank_ram_set(src_bank);
        }
        ws_bank_ram_set(orig_bank);
    } else if (to_fs ? PTR_IN_SRAM(dst) : PTR_IN_SRAM(src)) {
        ws_bank_with_ram(BANK_SOFTFS, {
            memcpy(dst, src, len);
        });
    } else {
        memcpy(dst, src, len);
    }
}

IL_FUNCTION
int fs_read(int fd, char __far *data, int length) {
    if (fd < 0 || fd >= MAXFILES)
        return E_FS_OUT_OF_BOUNDS;

    const void __far *src;
    int to_read;

    ws_bank_with_ram(BANK_OSWORK, {
        if (fhandle(fd).ent == NULL)
            return E_FS_FILE_NOT_OPEN;
        if (!(fhandle(fd).mode & FMODE_R))
            return E_FS_PERMISSION_DENIED;

        fpos_t pos = fhandle(fd).pos;
        src = MK_FP(fhandle(fd).loc.w.seg + (pos >> 4), pos & 0xF);
        to_read = length;
        if (to_read > (fhandle(fd).len - pos))
            to_read = fhandle(fd).len - pos;
        fhandle(fd).pos += to_read;
    });

    if (to_read)
        fs_safe_memcpy(data, src, to_read, false);
    return to_read;
}

IL_FUNCTION
int fs_write(int fd, const char __far *data, int length) {
    if (fd < 0 || fd >= MAXFILES)
        return E_FS_OUT_OF_BOUNDS;

    void __far *dest;
    int to_write;

    ws_bank_with_ram(BANK_OSWORK, {
        if (fhandle(fd).ent == NULL)
            return E_FS_FILE_NOT_OPEN;
        if (!(fhandle(fd).mode & FMODE_W))
            return E_FS_PERMISSION_DENIED;

        fpos_t pos = fhandle(fd).pos;
        dest = MK_FP(fhandle(fd).loc.w.seg + (pos >> 4), pos & 0xF);
        to_write = length;
        if (to_write > (fhandle(fd).len - pos))
            to_write = fhandle(fd).len - pos;
        fhandle(fd).pos += to_write;
    });

    if (to_write)
        fs_safe_memcpy(dest, data, to_write, true);
    return to_write;
}

IL_FUNCTION
long fs_lseek(int fd, long offset, int whence) {
    if (fd < 0 || fd >= MAXFILES)
        return E_FS_OUT_OF_BOUNDS;
    if (whence < 0 || whence > 2)
        return E_FS_OUT_OF_BOUNDS;
    
    ws_bank_with_ram(BANK_OSWORK, {
        if (fhandle(fd).ent == NULL)
            return E_FS_FILE_NOT_OPEN;

        fpos_t new_pos;
        if (whence == SEEK_SET)
            new_pos = offset;
        else if (whence == SEEK_CUR)
            new_pos = fhandle(fd).pos + offset;
        else if (whence == SEEK_END)
            new_pos = fhandle(fd).len + offset;

        if (new_pos < 0)
            new_pos = 0;
        else if (new_pos > fhandle(fd).len)
            new_pos = fhandle(fd).len;

        fhandle(fd).pos = new_pos;
        return new_pos;
    });
}

IL_FUNCTION
int fs_chmod(FS fs, const char __far *filename, int mode) {
    char filename_local[MAXFNAME];
    strncpy(filename_local, filename, MAXFNAME);

    ws_bank_with_ram(BANK_OSWORK, {
        if (!(fs->mode & FMODE_W)) {
            return E_FS_PERMISSION_DENIED;
        }

        fent_t __far* src_entry = find_fs_entry(fs, filename_local);
        if (src_entry == NULL) {
            return E_FS_FILE_NOT_FOUND;
        }

        src_entry->mode = mode;
        return E_FS_SUCCESS;
    });
}

IL_FUNCTION
int fs_creat(FS fs, fent_t __far *entry) {
    ws_bank_with_ram(BANK_OSWORK, {
        if (!(fs->mode & FMODE_W)) {
            return E_FS_PERMISSION_DENIED;
        }

        int n = fs_n_entries(fs);
        fent_t __far* files = fs_entries(fs);
        uint16_t max_seg = FP_SEG(fs->loc);
        uint16_t end_seg = max_seg + (fs->len >> 4);
        int free_count = 0;

        for (int i = 0; i < n; i++) {
            if (files[i].count > 0) {
                uint16_t seg = FP_SEG(files[i].loc) + (files[i].count << 3);
                if (seg > max_seg)
                    max_seg = seg;
            }
        }

        free_count = (end_seg - max_seg) >> 3;
        if (free_count < entry->count)
            return E_FS_NO_SPACE_LEFT;

        for (int i = 0; i < n; i++) {
            if (files[i].count < 0) {
                memcpy(files + i, entry, sizeof(fent_t));
                files[i].loc = MK_FP(max_seg, 0);
                // TODO: Is this dynamically allocated up to count?
                files[i].len = files[i].count << 7;
                return E_FS_SUCCESS;
            }
        }

        return E_FS_NO_SPACE_LEFT;
    });
}

IL_FUNCTION
int fs_unlink(FS fs, const char __far *filename) {
    char filename_local[MAXFNAME];
    strncpy(filename_local, filename, MAXFNAME);

    ws_bank_with_ram(BANK_OSWORK, {
        if (!(fs->mode & FMODE_W)) {
            return E_FS_PERMISSION_DENIED;
        }

        fent_t __far* src_entry = find_fs_entry(fs, filename_local);
        if (src_entry == NULL) {
            return E_FS_FILE_NOT_FOUND;
        }

        src_entry->count = -1;
        src_entry->resource = -1;
    });

    return E_FS_SUCCESS;
}

IL_FUNCTION
int fs_newfs(FS fs) {
    ws_bank_with_ram(BANK_OSWORK, {
        int n = fs_n_entries(fs);
        fent_t __far* files = fs_entries(fs);

        memset(files, 0, sizeof(fent_t) * n);
        for (int i = 0; i < n; i++) {
            files[i].count = -1;
            files[i].resource = -1;
        }

        fs->il = il_fs_ptr();
        fs->count = n;
    });

    return E_FS_SUCCESS;
}

IL_FUNCTION
int fs_defrag(FS fs) {
    // TODO
    return E_FS_SUCCESS;
}

IL_FUNCTION
uint32_t fs_space(FS fs) {
    ws_bank_with_ram(BANK_OSWORK, {
        if (!(fs->mode & FMODE_W)) {
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

        return space_end - max_file_end;
    });
}

// FIXME
__attribute__((optimize("-O0")))
const fent_t *fs_init(void) {
    // Initialize file systems
    fs_newfs(root_fs);
    fs_newfs(rom0_fs);
    fs_newfs(ram0_fs);

    root_fs->mode = FMODE_DIR | FMODE_MMAP | FMODE_R;

    rom0_fs->loc = MK_FP(0x8000, 0x0000);
    rom0_fs->len = 0x60000L;
#ifdef ATHENA_IN_ROM
    rom0_fs->mode = FMODE_DIR | FMODE_R;
#else
    rom0_fs->mode = FMODE_DIR | FMODE_R | FMODE_W;
#endif

#ifdef OS_ENABLE_128K_SRAM
    ram0_fs->loc = MK_FP(0x1000 + OS_RAM_SEGMENTS_RESERVED, 0x0000);
    ram0_fs->len = 0x10000L - (OS_RAM_SEGMENTS_RESERVED << 4);
#else
    ram0_fs->loc = MK_FP(0x1000, 0x0000);
    ram0_fs->len = 0x10000L;
#endif
    ram0_fs->mode = FMODE_DIR | FMODE_MMAP | FMODE_R | FMODE_W;

    kern_fs->il = il_fs_ptr();
    kern_fs->loc = (void __far*) kern_fs_entries;
    kern_fs->len = kern_fs_num_entries * sizeof(fent_t);
    kern_fs->count = kern_fs_num_entries;
    kern_fs->mode = FMODE_DIR | FMODE_R;

    strcpy(ram0_fs->name, "ram0");
    strcpy(rom0_fs->name, "rom0");
    strcpy(kern_fs->name, "kern");

    memset(sramwork_p->_openfiles, 0, sizeof(sramwork_p->_openfiles));

    // Copy files from ROM
    if (rom_fs_footer->magic != ROM_FS_FOOTER_MAGIC || rom_fs_footer->version != ROM_FS_FOOTER_VERSION) {
        text_screen_init();
        text_put_string(2, 8, "ROM filesystem not found");
        while(1) ia16_halt();
    }

    memcpy(rom0_fs_entries,
        MK_FP(rom_fs_footer->fs_start_segment, 0x0000),
        rom_fs_footer->rom0_count * sizeof(fent_t));

    uint8_t __far *ram_dst = ram0_fs->loc;
    for (int i = 0; i < rom_fs_footer->ram0_count; i++) {
        fent_t __far *entry_src = MK_FP(rom_fs_footer->fs_start_segment, (rom_fs_footer->rom0_count + i) * sizeof(fent_t));
        fent_t *entry_dst = ram0_fs_entries + i;
        memcpy(entry_dst, entry_src, sizeof(fent_t));
        if (entry_dst->count > 0) {
            ws_bank_with_ram(BANK_SOFTFS, {
                memcpy(ram_dst, entry_src->loc, entry_src->count << 7);
            });
            entry_dst->loc = ram_dst;
            ram_dst = MK_FP(FP_SEG(ram_dst) + (entry_dst->count << 3), FP_OFF(ram_dst));
        }
    }

    return rom0_fs_entries + rom_fs_footer->rom0_executable_idx;
}
