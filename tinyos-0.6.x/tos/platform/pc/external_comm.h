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
 * Authors:		Philip Levis <pal@cs.berkeley.edu>
 *
 *
 */

/*
 *   FILE: external_comm.c
 * AUTHOR: pal
 *   DESC: Routines for communication with other processes.
 *
 * This file contains the functions and structures used by TOSSIM for
 * communicating to external programs over TCP. At boot, TOSSIM tries to
 * open a series of sockets to ports on the local machine, with each
 * port being a different source (or sink) of information. Sources are
 * read in competely, and the necesary events are enqueued for later
 * processing. Sinks (such as RADIO_OUT_PORT) are used in functions (such
 * as writeOutRadioPacket) that are called within the TinyOS source (AM.c).
 *
 * TOSSIM also opens a single listening server socket, which is handled by
 * a separate thread. Network packets can be injected into the network over
 * this connection. This allows a user to connect to the simulation after it
 * has started and introduce packets into the network. TossimInjector
 * (in the tools/ directory) is a utility for doing this.
 *
 */

#ifndef EXTERNAL_COMM_H_INCLUDED
#define EXTERNAL_COMM_H_INCLUDED

#include "super.h"

#define RADIO_IN_PORT 10576
#define RADIO_OUT_PORT 10577
#define RADIO_BIT_OUT_PORT 10578
#define RADIO_RT_PORT 10579
#define UART_IN_PORT 10580
#define UART_OUT_PORT 10581
#define LOGGING_PORT 10583
#define RADIO_RAW_OUT_PORT 10582

typedef struct {
  long long time;
  short moteID;
  char data;
} UartByteMsg;;

typedef struct {
  long long time;
  short moteID;
  TOS_Msg msg;
} InRadioMsg;

typedef struct {
  long long time;
  short moteID;
  char bit;
} OutRadioBitMsg;

typedef struct {
  long long time;
  short moteID;
  char data[36] ;
} OutRadioMsg;

typedef struct {
  short receiver;
  TOS_Msg msg;
} incoming_radio_data_t;

extern void initializeSockets();

extern int initializeIncomingUART();
extern int initializeOutgoingUART();
extern int initializeIncomingRadio();
extern int initializeIncomingRTRadio();
extern int initializeOutgoingRadio();
extern int initializeOutgoingBitRadio();
extern int initializeInvocationLogging();
extern int initializeOutgoingRawRadio();

extern void setLoggingPause(int pause);

extern int readInUARTMessages();
extern int readInRadioMessages();
extern int writeOutUartByte(long long time, short moteID, char value);
extern int writeOutRadioBit(long long time, short moteID, char bit);
extern int writeOutRadioPacket(long long time, short moteID, char* data, int length);


extern void event_radio_in_create(event_t* event,
				  long long time,
				  short receiver,
				  TOS_MsgPtr msg);

extern void event_radio_in_handle(event_t* event,
				  struct TOS_state* state);

extern int notifyTaskPosted(char* task);
extern int notifyEventSignaled(char* event);
extern int notifyCommandCalled(char* command);

extern int printTime(char* buf, int len);
extern int printOtherTime(char* buf, int len, long long int time);

#endif
