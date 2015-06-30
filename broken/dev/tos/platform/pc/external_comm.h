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
 * Authors:		Philip Levis <pal@cs.berkeley.edu>
 *
 *
 */

/*
 *   FILE: external_comm.c
 * AUTHOR: pal
 *   DESC: Routines for communication with other processes.
 *
 * This file contains the functions and structures used by NIDO for
 * communicating to external programs over TCP. At boot, NIDO tries to
 * open a series of sockets to ports on the local machine, with each
 * port being a different source (or sink) of information. Sources are
 * read in competely, and the necesary events are enqueued for later
 * processing. Sinks (such as RADIO_OUT_PORT) are used in functions (such
 * as writeOutRadioPacket) that are called within the TinyOS source (AM.c).
 *
 * NIDO also opens a single listening server socket, which is handled by
 * a separate thread. Network packets can be injected into the network over
 * this connection. This allows a user to connect to the simulation after it
 * has started and introduce packets into the network. NidoInjector
 * (in the tools/ directory) is a utility for doing this.
 *
 */

#ifndef EXTERNAL_COMM_H_INCLUDED
#define EXTERNAL_COMM_H_INCLUDED

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <errno.h>
#include <pthread.h>

#define RADIO_IN_PORT 10576
#define RADIO_OUT_PORT 10577
#define RADIO_BIT_OUT_PORT 10578
#define RADIO_RT_IN_PORT 10579
#define UART_IN_PORT 10580
#define UART_OUT_PORT 10581
#define LOGGING_PORT 10583
#define RADIO_RAW_OUT_PORT 10582
#define RADIO_RT_OUT_PORT 10584

typedef struct {
  long long time;
  short moteID;
  char data;
} UartByteMsg;;

void initializeSockets();

int initializeIncomingUART();
int initializeOutgoingUART();
int initializeIncomingRadio(int radio_out_port);
int initializeIncomingRTRadio();
int initializeOutgoingRadio(int radio_out_port);
int initializeOutgoingRTRadio();
int initializeOutgoingBitRadio();
int initializeInvocationLogging();
int initializeOutgoingRawRadio();

void setLoggingPause(int fpause);

int readInUARTMessages();
int writeOutUartByte(long long ftime, short moteID, char value);


int notifyTaskPosted(char* task);
int notifyEventSignaled(char* event);
int notifyCommandCalled(char* command);

int printTime(char* buf, int len);
int printOtherTime(char* buf, int len, long long int ftime);

#endif







