/*									tab:4
 *
 *
 * "Copyright (c) 2001 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:		Phil Levis (from work by Mike Castelle)
 *
 *
 */

/*
 *   FILE: dbg.h
 * AUTHOR: pal
 *  DESCR: Run-time configuration of debug output in FULLPC mode. 
 *
 * Debug output determined by DBG environment variable. dbg_modes.h has
 * definitions of the settings possible. One can specify multiple debugging
 * outputs by comma-delimiting (e.g. DBG=sched,timer). Compiling with
 * NDEBUG defined (e.g. -DNDEBUG) will stop all of the debugging
 * output, will remove the debugging commands from the object file.
 *
 * example usage: dbg(DBG_TIMER, ("timer went off at %d\n",time));
 *
 */

#ifndef DBG_H
#define DBG_H

#ifdef TOSSIM

#include <stdio.h>

#include "dbg_modes.h"

typedef struct dbg_mode {
	char* d_name;
	unsigned long long d_mode;
} dbg_mode_t;

/* We're in FULLPC mode, and debugging is not turned off */
#ifndef NDEBUG

#include "tossim.h"

#define dbg(mode, arg) do { if (dbg_modes & (mode)) {printf("%i: ", NODE_NUM); printf arg; }} while(0)
#define dbg_clear(mode, arg) do { if (dbg_modes & (mode)) {printf arg; }} while(0)
#define dbg_active(mode) (dbg_modes & (mode))
void dbg_add_mode(const char *mode);
void dbg_add_modes(const char *modes);
extern long long dbg_modes;
void dbg_init(void);
void dbg_help(void);

/* We're in TOSSIM mode, and debugging is turned off */
#else
#define dbg(mode, arg) do {} while(0)
#define dbg_clear(mode, arg) do {} while(0)
#define dbg_active(mode) 0
#define dbg_add_mode(mode) do {} while(0)
#define dbg_add_modes(modes) do {} while(0)
#define dbg_init() do {} while(0)
#define dbg_help() do {} while(0)
#endif  /* NDEBUG */

/* We're not in TOSSIM mode */
#else 
#define dbg(mode, arg) do {} while(0)
#define dbg_clear(mode, arg) do {} while(0)
#define dbg_active(mode) 0
#define dbg_add_mode(mode) do {} while(0)
#define dbg_add_modes(modes) do {} while(0)
#define dbg_init() do {} while(0)
#define dbg_help() do {} while(0)
#endif /* TOSSIM */

/* Part 2: some types/constants for the DEBUG component */
enum {
  led_y_toggle, led_y_on, led_y_off, 
  led_r_toggle, led_r_on, led_r_off, 
  led_g_toggle, led_g_on, led_g_off };

#endif /* DBG_H */
