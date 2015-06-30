/*
 * Copyright (C) 2005 the University of Southern California.
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * In addition to releasing this program under the LGPL, the authors are
 * willing to dual-license it under other terms. You may contact the authors
 * of this project by writing to Wei Ye, USC/ISI, 4676 Admirality Way, Suite 
 * 1001, Marina del Rey, CA 90292, USA.
 */
/*
 * Authors:	Wei Ye
 *
 * This file defines debugging functions through UART
 */
 
#ifndef TST_UART_DEBUG_INCLUDED
#define TST_UART_DEUBG_INCLUDED

#ifdef TST_UART_DEBUG
// Debug by sending a byte through UART

#include "uartDebug.h"

static inline void tstUartDebug_init()
{
   uartDebug_init();
}

static inline void tstUartDebug_byte(uint8_t byte)
{
   uartDebug_txByte(byte);
}

#else
// UART debug is not enabled

static inline void tstUartDebug_init()
{
}

static inline void tstUartDebug_byte(uint8_t byte)
{
}

#endif  // TST_UART_DEBUG

#endif  // TST_UART_DEBUG_INCLUDED
