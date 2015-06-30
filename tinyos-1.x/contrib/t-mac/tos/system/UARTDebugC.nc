/*
 * Copyright (c) 2004 TU Delft/TNO
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement 
 * is hereby granted, provided that the above copyright notice and the
 * following two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * COPYRIGHT HOLDERS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE COPYRIGHT HOLDERS SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER
 * IS ON AN "AS IS" BASIS, AND THE COPYRIGHT HOLDERS HAVE NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Author:	Tom Parker
 * This module provides the basic UARTDebug functionality for sending out
 * debugging messages from a node to the serial port. Values for the debugging
 * events are defined in TMACEvents.h
 */
 
configuration UARTDebugC
{
	provides interface UARTDebug;
}

implementation
{
#ifdef TMAC_DEBUG
	components UARTDebugM as MyDebug;
#else
	components DummyDebugM as MyDebug;
#endif

#ifdef ENABLE_UART_DEBUG
	components UARTLL as MyUART;
#else
	components UART_TOSC as MyUART;
#endif
	
	UARTDebug = MyDebug;
#ifdef TMAC_DEBUG
	MyDebug.commControl -> MyUART;
#endif
	MyDebug.comm -> MyUART;
}
