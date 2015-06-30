/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
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
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * Authors:		David Gay, Philip Levis (from work by Mike Castelle), Nelson Lee
 * Date last modified:  6/25/02
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
 * example usage: dbg(DBG_TIMER, "timer went off at %d\n", time);
 *
 */
#ifndef DBG_H
#define DBG_H

typedef long long TOS_dbg_mode;

#include "dbg_modes.h"
/* We're in FULLPC mode, and debugging is not turned off */
#if defined(PLATFORM_PC) && !defined(NDEBUG)

#include <stdio.h>
#include <stdarg.h>
#include "nido.h"
#include "GuiMsg.h"

typedef struct dbg_mode {
	char* d_name;
	unsigned long long d_mode;
} TOS_dbg_mode_names;

TOS_dbg_mode dbg_modes = 0;

static bool dbg_active(TOS_dbg_mode mode) 
{ 
  return (dbg_modes & mode) != 0;
}

static void dbg_add_mode(const char *mode);
static void dbg_add_modes(const char *modes);
static void dbg_init(void);
static void dbg_help(void);

static void dbg(TOS_dbg_mode mode, const char *format, ...) 
{ 

  char msg[MAX_DEBUG_MSG_LEN];
  
  //msg = (char *)malloc (sizeof(char) * 128);
  // if no DBG value is set, then every mode is active
  // not sure what the difference is between dbg and dbg_clear - can just add this code there anyways

  if (dbg_active(mode))
    {
      va_list args;

      printf("%i: ", NODE_NUM);
      va_start(args, format); 
      
      vsprintf (msg, format, args);
      sendGuiMsg (NODE_NUM, AM_DEBUGMSGEVENT, tos_state.tos_time, msg);

      vprintf(format, args);
      va_end(args);
    }    

  //free(msg);
}

static void dbg_clear(TOS_dbg_mode mode, const char *format, ...) 
{ 
  char msg[MAX_DEBUG_MSG_LEN];
  
  if (dbg_active(mode))
    {
      va_list args;

      va_start(args, format);

      vsprintf (msg, format, args);
      sendGuiMsg (NODE_NUM, AM_DEBUGMSGEVENT, tos_state.tos_time, msg);

      vprintf(format, args);
      va_end(args);
    }    
}

#else 
/* No debugging */

static inline void dbg(TOS_dbg_mode mode, const char *format, ...) { }
static inline void dbg_clear(TOS_dbg_mode mode, const char *format, ...) { }
static inline bool dbg_active(TOS_dbg_mode mode) { return FALSE; }
static inline void dbg_add_mode(const char *mode) { }
static inline void dbg_add_modes(const char *modes) { }
static inline void dbg_init(void) { }
static inline void dbg_help(void) { }
#endif 

#endif /* DBG_H */
