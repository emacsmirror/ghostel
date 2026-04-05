/*
 * Wrapper for emacs-module.h that works around musl libc's struct timespec
 * definition using bit-field padding expressions that Zig's translate-c
 * cannot parse (producing an opaque type instead of a concrete struct).
 *
 * On musl, we provide a plain struct timespec definition and set the guard
 * macro so musl's <bits/alltypes.h> skips its version.
 *
 * GHOSTEL_MUSL is defined by emacs.zig when the Zig target ABI is musl.
 */

/* Ensure struct timespec is visible (glibc gates it behind this). */
#define _POSIX_C_SOURCE 199309L

#ifdef GHOSTEL_MUSL
/* musl libc — pre-define struct timespec with a layout Zig can translate.
   ABI-compatible: tv_sec is time_t, tv_nsec is long, with padding to keep
   sizeof(struct timespec) == 2 * sizeof(time_t). */
#define __NEED_time_t
#include <bits/alltypes.h>          /* get time_t */
#ifndef __DEFINED_struct_timespec
#define __DEFINED_struct_timespec
struct timespec {
    time_t tv_sec;
    long   tv_nsec;
    char   __padding[sizeof(time_t) - sizeof(long)];
};
#endif
#endif

#include <emacs-module.h>
