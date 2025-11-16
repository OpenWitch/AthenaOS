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
void __far* __far proc_load(const char __far* cmdline) {
    // TODO
    return NULL;
}

IL_FUNCTION
int proc_run(void __far* entrypoint, int argc, const char __far* __far* argv) {
    // Copy argv
    char **local_argv = _pc->_argv;
    char *local_arg = (char*) (local_argv + argc);
    for (int i = 0; i < argc; i++) {
        *(local_argv++) = local_arg;
        if (argv != NULL && argv[i] != NULL) {
            const char __far* arg = argv[i];
            while (*arg) {
                *(local_arg++) = *(arg++);
            }
        }
        *(local_arg++) = 0;
    }
    _pc->_heap = local_arg;

    // Run entrypoint
    ((proc_func_entrypoint_t) entrypoint)(argc, _pc->_argv);
    return 0;
}

IL_FUNCTION
int proc_exec(const char __far* cmdline, int argc, const char __far* __far* argv) {
    void __far* entrypoint = proc_load(cmdline);
    if (entrypoint == NULL) {
        return E_FS_ERROR;
    }
    return proc_run(entrypoint, argc, argv);
}

IL_FUNCTION
void proc_exit(int code) {
    bios_exit();
}

IL_FUNCTION
void proc_yield(void) {

}

IL_FUNCTION
int proc_suspend(int i) {
    return E_FS_ERROR;
}

IL_FUNCTION
void proc_resume(int i) {

}

IL_FUNCTION
int proc_swap(int i) {
    return E_FS_ERROR;
}
