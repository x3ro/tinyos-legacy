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
 */

#ifndef EXTERNAL_COMM_H_INCLUDED
#define EXTERNAL_COMM_H_INCLUDED

#include "super.h"

#define UART_IN_PORT 22576
#define UART_OUT_PORT 22577
#define RADIO_IN_PORT 10576
#define RADIO_OUT_PORT 10577
#define RADIO_BIT_OUT_PORT 10578

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
  char data[38];
} OutRadioMsg;

typedef struct {
  short receiver;
  TOS_Msg msg;
} incoming_radio_data_t;

extern int initializeIncomingUART();
extern int initializeOutgoingUART();
extern int initializeIncomingRadio();
extern int initializeIncomingRTRadio();
extern int initializeOutgoingRadio();
extern int initializeOutgoingBitRadio();

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

#endif
