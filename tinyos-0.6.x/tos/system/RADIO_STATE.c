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
 * Authors:		Philip Levis
 * Desc:                State machine for the radio.
 */

#include "tos.h"
#include "RADIO_STATE.h"
#include "dbg.h"

#define RX_IDLE   0           // 0000
#define RX_START  1           // 0010
#define RX_SYNC   2           // 0001
#define RX_DATA   3           // 0011
#define TX_MAC    4           // 0100


#define TX_START  8            // 1000
#define TX_SYNC   9            // 1001
#define TX_DATA   10           // 1010

#define CAN_TX    (VAR(state) & 0x8)

#define TOS_FRAME_TYPE RadioStateFrame
TOS_FRAME_BEGIN(RadioStateFrame) {
  char state;
  char stateChanged;
}
TOS_FRAME_END(RadioStateFrame);


/* This is the initialization of the component */
char TOS_COMMAND(RADIO_STATE_INIT)(){
  VAR(state) = RX_IDLE;
  VAR(stateChanged) = 1;
  
  TOS_CALL_COMMAND(RADIO_STATE_SUB_INIT)();
  
  dbg(DBG_BOOT, ("RADIO_STATE multiplexer initialized.\n"));
  
  return 1;
}

char TOS_COMMAND(RADIO_STATE_TX_BIT)(char bit) {
  if (CAN_TX) {
    return TOS_CALL_COMMAND(RADIO_STATE_SUB_TX_BIT)(bit);
  }
  else {
    dbg(DBG_ERROR, ("ERROR: Tried to transmit a bit in a non-transmit state.\n"));
    return 0;
  }
}

char TOS_COMMAND(RADIO_STATE_PWR_OFF)(short timer) {
  return TOS_CALL_COMMAND(RADIO_STATE_SUB_PWR_OFF)(timer);
}

char TOS_COMMAND(RADIO_STATE_PWR_ON)(short rate) {
  return TOS_CALL_COMMAND(RADIO_STATE_SUB_PWR_ON)(rate);
}

char TOS_COMMAND(RADIO_STATE_SET_BIT_RATE)(short rate) {
  return TOS_CALL_COMMAND(RADIO_STATE_SUB_SET_BIT_RATE)(rate);
}

char TOS_COMMAND(RADIO_STATE_RX_IDLE_ACTIVATE)() {
  VAR(state) = RX_IDLE;
  VAR(stateChanged) = 1;
  TOS_CALL_COMMAND(RADIO_STATE_SUB_RX_MODE)();
  dbg(DBG_RADIO, ("RX_IDLE activated.\n"));
  
  return 1;
}

char TOS_COMMAND(RADIO_STATE_RX_START_ACTIVATE)() {
  if (VAR(state) != RX_IDLE) {
    dbg(DBG_ERROR, ("ERROR: Tried to perform an illegal transition to RX_START state in radio.\n"));
    return 0;
  }
  else {
    VAR(state) = RX_START;
    VAR(stateChanged) = 1;
    dbg(DBG_RADIO, ("RX_START activated.\n"));
    return 1;
  }
}

char TOS_COMMAND(RADIO_STATE_RX_SYNC_ACTIVATE)() {
  if (VAR(state) != RX_START) {
    dbg(DBG_ERROR, ("ERROR: Tried to perform an illegal transition to RX_SYNC state in radio.\n"));
    return 0;
  }
  else {
    VAR(state) = RX_SYNC;
    VAR(stateChanged) = 1;
    return 1;
  }
}

char TOS_COMMAND(RADIO_STATE_RX_DATA_ACTIVATE)() {
  if (VAR(state) != RX_SYNC) {
    dbg(DBG_ERROR, ("ERROR: Tried to perform an illegal transition to RX_DATA state in radio.\n"));
    return 0;
  }
  else {
    VAR(state) = RX_DATA;
    VAR(stateChanged) = 1;
    dbg(DBG_RADIO, ("RX_DATA activated.\n"));

    return 1;
  }
}


char TOS_COMMAND(RADIO_STATE_TX_MAC_ACTIVATE)() {
  if (VAR(state) != RX_IDLE && VAR(state) != RX_START) {
    dbg(DBG_ERROR, ("ERROR: Tried to perform an illegal transition to TX_MAC state in radio.\n"));
    return 0;
  }
  else {
    VAR(state) = TX_MAC;
    VAR(stateChanged) = 1;
    return 1;
  }
}

char TOS_COMMAND(RADIO_STATE_TX_START_ACTIVATE)() {
  if (VAR(state) != TX_MAC) {
    dbg(DBG_ERROR, ("ERROR: Tried to perform an illegal transition to TX_SYNC state in radio.\n"));
    return 0;
  }
  else {
    TOS_CALL_COMMAND(RADIO_STATE_SUB_TX_MODE)();
    VAR(state) = TX_START;
    VAR(stateChanged) = 1;
    return 1;
  }
}

char TOS_COMMAND(RADIO_STATE_TX_SYNC_ACTIVATE)() {
  if (VAR(state) != TX_START) {
    dbg(DBG_ERROR, ("ERROR: Tried to perform an illegal transition to TX_SYNC state in radio.\n"));
    return 0;
  }
  else {
    VAR(state) = TX_SYNC;
    VAR(stateChanged) = 1;
    return 1;
  }
}



char TOS_COMMAND(RADIO_STATE_TX_DATA_ACTIVATE)() {
  if (VAR(state) != TX_SYNC) {
    dbg(DBG_ERROR, ("ERROR: Tried to perform an illegal transition to TX_DATA state in radio.\n"));
    return 0;
  }
  else {
    VAR(state) = TX_DATA;
    VAR(stateChanged) = 1;
    return 1;
  }
}

//char RADIO_STATE_NULL_FUNC_EVENT(char bit) {return 1;}

char TOS_EVENT(RADIO_STATE_RX_BIT_EVENT)(char bit) {
  while (VAR(stateChanged)) {
    VAR(stateChanged) = 0;

    switch(VAR(state)) {

    case RX_IDLE:
      TOS_SIGNAL_EVENT(RADIO_STATE_RX_IDLE_START)();
      break;

    case RX_START:
      TOS_SIGNAL_EVENT(RADIO_STATE_RX_START_START)();
      break;
      
    case RX_SYNC:
      TOS_SIGNAL_EVENT(RADIO_STATE_RX_SYNC_START)();
      break;

    case RX_DATA:
      TOS_SIGNAL_EVENT(RADIO_STATE_RX_DATA_START)();
      break;

    case TX_MAC:
      TOS_SIGNAL_EVENT(RADIO_STATE_TX_MAC_START)();
      break;
      
    default:
      dbg(DBG_ERROR, ("Handling an RX bit event when not in a bit read state.\n"));
      // do nothing
    }
  }
  
  switch(VAR(state)) {
  case RX_IDLE:
    return TOS_SIGNAL_EVENT(RADIO_STATE_RX_IDLE_EVENT)(bit);

  case RX_START:
    return TOS_SIGNAL_EVENT(RADIO_STATE_RX_START_EVENT)(bit);
    
  case RX_SYNC:
    return TOS_SIGNAL_EVENT(RADIO_STATE_RX_SYNC_EVENT)(bit);
    
  case RX_DATA:
    return TOS_SIGNAL_EVENT(RADIO_STATE_RX_DATA_EVENT)(bit);
    
  case TX_MAC:
    return TOS_SIGNAL_EVENT(RADIO_STATE_TX_MAC_EVENT)(bit);
    
  default:
    dbg(DBG_ERROR, ("ERROR: RX bit event in a non-RX state: %i. This was possibly resulting from an instantaneous transition from TX_MAC state into TX_START in the TX_MAC_START event handler.\n", (int)VAR(state)));
    return 0;
  }
  return 1;
}

char TOS_EVENT(RADIO_STATE_TX_BIT_EVENT)() {

  while(VAR(stateChanged)) {
    VAR(stateChanged) = 0;

    switch(VAR(state)) {

    case TX_START:
      TOS_SIGNAL_EVENT(RADIO_STATE_TX_START_START)();
      break;
      
    case TX_SYNC:
      TOS_SIGNAL_EVENT(RADIO_STATE_TX_SYNC_START)();
      break;
      
    case TX_DATA:
      TOS_SIGNAL_EVENT(RADIO_STATE_TX_DATA_START)();
      break;
    }
    
  }
  
  switch(VAR(state)) {

  case TX_START:
    return TOS_SIGNAL_EVENT(RADIO_STATE_TX_START_EVENT)();
    
  case TX_SYNC:
    return TOS_SIGNAL_EVENT(RADIO_STATE_TX_SYNC_EVENT)();

  case TX_DATA:
    return TOS_SIGNAL_EVENT(RADIO_STATE_TX_DATA_EVENT)();

  default:
    dbg(DBG_ERROR, ("ERROR: TX bit event in a non-TX state: %i. This is probably the result of instantaneously transitioning from a TX state to an RX state in a TX_START event handler.\n", (int)VAR(state)));
    return 0;
  }
  return 1;
}

