// $Id: GuiMsg.h,v 1.1.1.1 2007/11/05 19:10:18 jpolastre Exp $

/*									tab:4
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/* This file defines the message format for communication between TOSSIM
 * and TinyViz (the TOSSIM GUI). Communication is bidirectional using
 * two sockets: EVENT_PORT is used to send events from TOSSIM to 
 * TinyViz; COMMAND_PORT is used to inject commands from TinyViz
 * into TOSSIM. Every event sent by TOSSIM on EVENT_PORT is 
 * acknowledged by a single-byte ACK before the simulator proceeds. This 
 * allows the GUI to throttle the execution speed of the simulator by 
 * delaying the ACK. Commands sent into TOSSIM by the GUI are not 
 * acknowledged.
 *
 * * NOTE NOTE NOTE NOTE NOTE NOTE NOTE *
 * If you wish to add new command or event types here, there are several 
 * other things you must do. For details, see the README file in 
 * tools/java/net/tinyos/sim.
 * * NOTE NOTE NOTE NOTE NOTE NOTE NOTE *
 */

#ifndef GUIMSG_H_INCLUDED
#define GUIMSG_H_INCLUDED
#include <AM.h>

/* Every event/command type has an associated type field.
 * We use the symbols "AM_" to allow MIG to generate Java types
 * for each of these structures -- these are not actually 
 * Active Messages!
 */
enum {
  /* Events must be unique bit values to be maskable. */
  AM_DEBUGMSGEVENT       = 1,
  AM_RADIOMSGSENTEVENT   = 1 << 1,
  AM_UARTMSGSENTEVENT    = 1 << 2,
  AM_ADCDATAREADYEVENT   = 1 << 3,
  AM_TOSSIMINITEVENT     = 1 << 4,
  AM_INTERRUPTEVENT      = 1 << 5,
  AM_LEDEVENT            = 1 << 6,
  
  /*
   * Commands and responses just neeed arbitrary unique values. Leave
   * some free slots for new events to be added without requiring all
   * the others to change
   */
  AM_TURNONMOTECOMMAND   = 1 << 12,
  AM_TURNOFFMOTECOMMAND,
  AM_RADIOMSGSENDCOMMAND,
  AM_UARTMSGSENDCOMMAND,
  AM_SETLINKPROBCOMMAND,
  AM_SETADCPORTVALUECOMMAND,
  AM_INTERRUPTCOMMAND,
  AM_SETRATECOMMAND,
  AM_SETDBGCOMMAND,
  AM_VARIABLERESOLVECOMMAND,
  AM_VARIABLERESOLVERESPONSE,
  AM_VARIABLEREQUESTCOMMAND,
  AM_VARIABLEREQUESTRESPONSE,
  AM_GETMOTECOUNTCOMMAND,
  AM_GETMOTECOUNTRESPONSE,
  AM_SETEVENTMASKCOMMAND,
  AM_BEGINBATCHCOMMAND,
  AM_ENDBATCHCOMMAND,
  
  /* Put further types later in the enum, so you don't break
     older code (e.g., don't have to regen mig messages). -pal */
};

/* The header structure for commands and events. Following this header
 * is the message payload, which is 'payLoadLen' bytes in size.
 */
typedef struct GuiMsg {
  uint16_t msgType;
  uint16_t moteID;
  long long time;
  uint16_t payLoadLen;
} GuiMsg;
// This is *NOT* sizeof(GuiMsg) - since alignment constraints 
// might require additional padding in the structure
#define GUI_MSG_HEADER_LENGTH 14  

/* Contains a debug message (from the 'dbg()' macro) sent by a mote. */
#define MAX_DEBUG_MSG_LEN 512
typedef struct DebugMsgEvent {
  char debugMessage[MAX_DEBUG_MSG_LEN];
} DebugMsgEvent;

/* Indicates that a radio message was sent by a mote. */
typedef struct RadioMsgSentEvent {
  TOS_Msg message;
} RadioMsgSentEvent;

/* Indicates that a UART message was sent by a mote. */
typedef struct UARTMsgSentEvent {
  TOS_Msg message;
} UARTMsgSentEvent;

/* Indicates that a UART message was sent by a mote. */
typedef struct ADCDataReadyEvent {
  uint8_t port;
  uint16_t data;
} ADCDataReadyEvent;

/* Provides the address of a variable. */
typedef struct VariableResolveResponse {
  uint32_t addr;
  uint32_t length;
} VariableResolveResponse;

/* Provides the value of a variable. */
typedef struct VariableRequestResponse {
  uint32_t length;
  char value[256];
} VariableRequestResponse;

/* Sends sim initialization info to TinyViz */
typedef struct TossimInitEvent {
  int numMotes;
  uint8_t radioModel;
  uint32_t rate;
} __attribute__((packed)) TossimInitEvent;

/* Event used for scheduled simulation interrupts */
typedef struct InterruptEvent {
  uint32_t id;
} InterruptEvent;

/* Command to turn a mote on. */
typedef struct TurnOnMoteCommand {
} TurnOnMoteCommand;

/* Command to turn a mote off. */
typedef struct TurnOffMoteCommand {
} TurnOffMoteCommand;

/* Command to send a radio message to a mote. */
typedef struct RadioMsgSendCommand {
  TOS_Msg message;
} RadioMsgSendCommand;

/* Command to send a UART message to a mote. */
typedef struct UARTMsgSendCommand {
  TOS_Msg message;
} UARTMsgSendCommand;

/* Command to set the probability of loss over the radio between to motes */
typedef struct SetLinkProbCommand {
  uint16_t moteReceiver;
  uint32_t scaledProb;
} SetLinkProbCommand;

/* Command to set a mote's adc's port value */
typedef struct SetADCPortValueCommand {
  uint8_t port;
  uint16_t value;
} SetADCPortValueCommand;

/* Command representing a variable (memory region) to resolve. */
typedef struct VariableResolveCommand {
  char name[256];
} VariableResolveCommand;

/* Command representing a variable (memory region) to read. */
typedef struct VariableRequestCommand {
  uint32_t addr;
  uint8_t length;
} VariableRequestCommand;

typedef struct InterruptCommand {
  uint32_t id;
} InterruptCommand;

typedef struct SetRateCommand {
  uint32_t rate; // Divided by 1000 is the rate
} SetRateCommand;

typedef struct LedEvent {
  uint8_t red: 1;
  uint8_t green: 1;
  uint8_t yellow: 1;
} LedEvent;

typedef struct SetDBGCommand {
  long long dbg;
} SetDBGCommand;

typedef struct GetMoteCountCommand {
  uint8_t placeholder;
} GetMoteCountCommand;

typedef struct GetMoteCountResponse {
  uint16_t totalMotes;
  uint8_t bitmask[(TOSNODES+7)/8];
} GetMoteCountResponse;

typedef struct SetEventMaskCommand {
    uint16_t mask;
} SetEventMaskCommand;

typedef struct BeginBatchCommand {
} BeginBatchCommand;

typedef struct EndBatchCommand {
} EndBatchCommand;

#endif
