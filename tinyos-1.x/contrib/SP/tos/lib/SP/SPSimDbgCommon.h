/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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

/**
 * @modified 3/8/06
 *
 * @author Joe Polastre
 * @author Jonathan Hui
 */
#ifndef __SPSIMDBGCOMMON_H
#define __SPSIMDBGCOMMON_H

#define MAX_BUF 255
#define TIME_BUF 32
#define NODE_COLOR_COUNT 9

//char* DbgNormal        = "\E[0;39m";
//char* DbgDarkBlue      = "\E[0;34m";
//char* DbgDarkGreen     = "\E[0;32m";
//char* DbgDarkCyan      = "\E[0;36m";
//char* DbgDarkRed       = "\E[0;31m";
//char* DbgDarkMagenta   = "\E[0;35m";
//char* DbgBrown         = "\E[0;33m";
//char* DbgBlack         = "\E[0;30m";
//char* DbgBold_White    = "\E[1;37m";
//char* DbgBrightBlue    = "\E[1;34m";
//char* DbgBrightGreen   = "\E[1;32m";
//char* DbgBrightCyan    = "\E[1;36m";
//char* DbgBrightRed     = "\E[1;31m";
//char* DbgBrightMagenta = "\E[1;35m";
//char* DbgYellow        = "\E[1;33m";
//char* DbgDarkGray      = "\E[1;30m";
//char* DbgWhite         = "\E[0;37m";
//char* DbgBrightWhite   = "\E[1;37m";

#define DbgNormal          "\E[0;39m"
#define DbgDarkBlue        "\E[0;34m"
#define DbgDarkGreen       "\E[0;32m"
#define DbgDarkCyan        "\E[0;36m"
#define DbgDarkRed         "\E[0;31m"
#define DbgDarkMagenta     "\E[0;35m"
#define DbgBrown           "\E[0;33m"
#define DbgBlack           "\E[0;30m"
#define DbgBold_White      "\E[1;37m"
#define DbgBrightBlue      "\E[1;34m"
#define DbgBrightGreen     "\E[1;32m"
#define DbgBrightCyan      "\E[1;36m"
#define DbgBrightRed       "\E[1;31m"
#define DbgBrightMagenta   "\E[1;35m"
#define DbgYellow          "\E[1;33m"
#define DbgDarkGray        "\E[1;30m"
#define DbgWhite           "\E[0;37m"
#define DbgBrightWhite     "\E[1;37m"

// Aliases
//char* DbgBlue          = DbgBrightBlue;
//char* DbgGreen         = DbgBrightGreen;
//char* DbgCyan          = DbgBrightCyan;
//char* DbgRed           = DbgBrightRed;
//char* DbgMagenta       = DbgBrightMagenta;

#define DbgBlue            DbgDarkBlue
#define DbgGreen           DbgDarkGreen
#define DbgCyan            DbgDarkCyan
#define DbgRed             DbgDarkRed
#define DbgMagenta         DbgDarkMagenta

// 100 ms
#define PRINT_TIME_MARKERS       FALSE
#define PRINT_MAJOR_TIME_MARKERS TRUE
#define MARKER_INTERVAL          (0.1 * 4000000.0)

#ifdef DEBUG
char* NODE_COLORS[NODE_COLOR_COUNT] = {
	DbgBrightBlue,
	DbgBrightMagenta,
	DbgBrightGreen,
	DbgBrightCyan,
	DbgBrightRed,
	DbgYellow,
	DbgDarkGray,
	DbgNormal,
	DbgWhite
};

typedef struct DebugMode {
	bool isOn;
	TOS_dbg_mode mode;
	char* color;
	char* label;
} DebugMode;

void ppp(TOS_dbg_mode mode, const char * fmt, ...);
void pppp(DebugMode mode, const char * fmt, ...);
#endif // DEBUG

#ifdef DEBUG
#define ifdbg(x) x
#else
#define ifdbg(x)
#endif // DEBUG

#endif // __SPSIMDBGCOMMON_H
