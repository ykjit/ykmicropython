/*
 * This file is part of the MicroPython project, http://micropython.org/
 *
 * The MIT License (MIT)
 *
 * Copyright (c) 2014 Paul Sokolovsky
 * Copryight (c) 2024 Angus Gratton
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include "py/runtime.h"
#include "py/cstack.h"


#ifdef USE_YK
// This function finds the top of the C stack before the interpreter has
// allocated on it.
//
// It's important that this function doesn't have a yk shadow stack frame or
// get inlined into something which has one, otherwise `stack_dummy` could be
// allocated onto the shadow stack. If we allowed this, then we haven't found
// the top of the C stack at all!
//
// Annotating `yk_outline` is sufficient because:
//  - the shadow stack pass skips `yk_outline` functions.
//  - `yk_outline` implies `nolinline`, so it can't get inlined.
__attribute__((yk_outline))
#endif
void mp_cstack_init_with_sp_here(size_t stack_size) {
    #if __GNUC__ >= 13
    #pragma GCC diagnostic push
    #pragma GCC diagnostic ignored "-Wdangling-pointer"
    #endif
    volatile int stack_dummy;
    mp_cstack_init_with_top((void *)&stack_dummy, stack_size);
    #if __GNUC__ >= 13
    #pragma GCC diagnostic pop
    #endif
}

#ifdef USE_YK
// For this function to work properly, it must not have a shadow stack.
__attribute__((yk_outline))
#endif
mp_uint_t mp_cstack_usage(void) {
    // Assumes descending stack
    volatile int stack_dummy;
    return MP_STATE_THREAD(stack_top) - (char *)&stack_dummy;
}

#if MICROPY_STACK_CHECK

void mp_cstack_check(void) {
    if (mp_cstack_usage() >= MP_STATE_THREAD(stack_limit)) {
        mp_raise_recursion_depth();
    }
}

#endif // MICROPY_STACK_CHECK
