/*
 * Copyright (c) 1993-1999 David Gay and Gustav Hållberg
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software for any
 * purpose, without fee, and without written agreement is hereby granted,
 * provided that the above copyright notice and the following two paragraphs
 * appear in all copies of this software.
 * 
 * IN NO EVENT SHALL DAVID GAY OR GUSTAV HALLBERG BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF DAVID GAY OR
 * GUSTAV HALLBERG HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * DAVID GAY AND GUSTAV HALLBERG SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS ON AN
 * "AS IS" BASIS, AND DAVID GAY AND GUSTAV HALLBERG HAVE NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */

#ifndef OPTIONS_H
#define OPTIONS_H

#define GCQDEBUG

/* Mudlle configuration */
/* This files contains only #define's, it is used for both C and assembly code */

#if defined(__GNUC__) || defined(AMIGA)
#define INLINE
#else
#define INLINE
#endif

/* Define NORETURN as a qualifier to indicate that a function never returns.
   With gcc, this is `volatile'. The empty definition is ok too. */
#ifdef __GNUC__
#define NORETURN __attribute__ ((noreturn))
#else
#define NORETURN
#endif

#ifndef UNUSED
#ifdef __GNUC__
#define UNUSED __attribute__((unused))
#else
#define UNUSED
#endif
#endif

#ifdef sparc
#define HAVE_ALLOCA_H
#ifdef __SVR4
#define __EXTENSIONS__
#define stricmp strcasecmp
#else
#define HAVE_TM_ZONE
#endif
#endif

typedef char bool;
typedef signed char i8;
typedef unsigned char u8;
typedef short i16;
typedef unsigned short u16;
typedef long i32;
typedef unsigned long u32;

#ifdef hpux
#define stricmp strcasecmp
#endif

#ifdef __sgi
#define stricmp strcasecmp
#define HAVE_ALLOCA_H
#endif

#ifdef linux
#define stricmp strcasecmp
#define HAVE_ALLOCA_H
#endif

/* GC configuration, basic parameters */
/* More parameters are found in alloc.h (and some logic in alloc.c). */
#ifdef AVR
#define MEMORY_SIZE (2048)
#else
#define MEMORY_SIZE (4096*1024)
#endif

#define GLOBAL_SIZE 512
#define INTERRUPT
#define PRINT_CODE

/* Execution limits */

#define MAX_CALLS 100000	/* Max # of calls executed / interpret */

#endif
