/*                                                                      tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *
 */
/*                                                                      tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.
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
/*                                                                      tab:4
 * Copyright (c) 2003 Intel Corporation
 * All rights reserved Contributions to the above software program by Intel
 * Corporation is program is licensed subject to the BSD License, available at
 * http://www.opensource.org/licenses/bsd-license.html
 *
 */
/*
 * Authors:	Mark Yarvis
 *
 */

#ifndef _CONSTANTS_H
#define _CONSTANTS_H

#define MAX_CONNECTIONS 128

#define DISCOVERY_PORT 5758
#define MULTICAST_ADDRESS "225.0.0.12"
#define DISCOVERY_SEND_INTERVAL 10
#define RECONNECT_INTERVAL 5
#define POLL_INTERVAL 5000

#define NODE_SERVER_PORT 5759
#define APP_SERVER_PORT  9001
#define UART_SERVER_PORT 9000

#define TOS_SIM_COMMAND_PORT 10584
#define TOS_SIM_EVENT_PORT 10585

#define TOS_SIM_HEADER_LENGTH 14
#define TOS_SIM_PACKET_LENGTH 55
#define RADIO_PACKET_LENGTH 36
#define TOS_MESSAGE_LENGTH 41

#define BUFFER_SIZE 1000






enum {
  /* Events */
  AM_DEBUGMSGEVENT,
  AM_RADIOMSGSENTEVENT,
  AM_UARTMSGSENTEVENT,
  AM_ADCDATAREADYEVENT,
  AM_TOSSIMINITEVENT,
  AM_VARIABLERESOLVEEVENT,
  AM_VARIABLEVALUEEVENT,
  AM_SIMULATIONPAUSEDEVENT,
  AM_LEDEVENT,
  
  /* Commands */
  AM_TURNONMOTECOMMAND,
  AM_TURNOFFMOTECOMMAND,
  AM_RADIOMSGSENDCOMMAND,
  AM_UARTMSGSENDCOMMAND,
  AM_SETLINKPROBCOMMAND,
  AM_SETADCPORTVALUECOMMAND,  
  AM_VARIABLERESOLVECOMMAND,
  AM_VARIABLEREQUESTCOMMAND,
  AM_SIMULATIONPAUSECOMMAND,
  AM_SETRATECOMMAND,
  AM_SETDBGCOMMAND
};


#endif

