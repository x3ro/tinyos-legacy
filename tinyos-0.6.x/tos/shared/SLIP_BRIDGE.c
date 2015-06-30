/* 
 *
 * Copyright (c) 2001 Rutgers University and Richard P. Martin.
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the following conditions are met:
 *
 *    1. Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *
 *    2. Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *
 *    3. All advertising materials mentioning features or use of this
 *       software must display the following acknowledgment:
 *           This product includes software developed by 
 *           Rutgers University and its contributors.
 *
 *    4. Neither the name of the University nor the names of its
 *       contributors may be used to endorse or promote products derived from
 *       this software without specific prior written permission.
 * 
 * IN NO EVENT SHALL RUTGERS UNIVERSITY BE LIABLE TO ANY PARTY FOR DIRECT, 
 * INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RUTGERS
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *  
 * RUTGERS UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND RUTGERS UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 *
 * Author:         Richard P. Martin 
 * Version:        $Id: SLIP_BRIDGE.c,v 1.2 2002/01/31 02:31:13 rrubin Exp $
 * Creation Date:  Wed Jul 18 21:41:36 2001
 * Filename:       SLIP_BRIDGE.c
 * History:
 * $Log: SLIP_BRIDGE.c,v $
 * Revision 1.2  2002/01/31 02:31:13  rrubin
 * int to short
 *
 * Revision 1.1.1.1  2001/09/26 21:55:08  szewczyk
 *
 *
 * Revision 1.1  2001/08/24 21:43:13  rmartin101
 *
 * A Serial Line IP (SLIP) to mote Active Message bridge
 *
 */

/* A simple bridge(shunt) that connects the SLIP driver on the UART side 
 * to the GENERIC_COMM component. Also connects the generic comm to the 
 * SLIP driver.
 * 
 * This was built as a test-harness for the SLIP driver.
 * 
 *                        Theory of operation: 
 * The driver is a classic buffer swapper type of driver for an 
 * event-driven system (like TOS). Each low-level driver (SLIP and 
 * Generic_comm), has a single RX buffer. The highest level component, 
 * in this case the SLIP_BRIDGE, maintains a buffer for each low-level 
 * driver. On an RX from either side, the SLIP_BRIDGE swaps one of its 
 * buffers for the driver's buffer. By having two buffers, SLIP_BRIDGE 
 * allows for simulaneous full-duplex operation. Compare to the 
 * half-duplex GENERIC_BASE. 
 *
 * The component has a nice symmetrical structure.
 *
 * The SLIP_BRIDGE modifies the first word of the message over the radio to 
 * include the length field from the SLIP driver. 
 *
 * You have to compile with different destination addresses to make 
 * the bridge work. 
 *

 */

#include "tos.h"
//#define FULLPC_DEBUG 1
#include "SLIP_BRIDGE.h"

#define BRIDGE_DEST 11  /* send to node 11. Usually defined elsewhere */

#ifndef BRIDGE_DEST
#error A bridge destination must be defined in BRIDGE_DEST for SLIP_BRIDGE.c
#endif 

/* general TOSy defines */
#define HANDSHAKE_SUCCESS 1 
#define HANDSHAKE_FAILIED 0 
#define EVENT_SUCCESS 1
#define EVENT_FAILIED 0 

/*           ------------ Frame Declaration ----------             */
#define TOS_FRAME_TYPE SLIP_BRIDGE_frame
TOS_FRAME_BEGIN(SLIP_BRIDGE_frame) {
  TOS_MsgPtr radio_msg;   /* ptr to msg "owned" by the bridge for radio*/
  TOS_MsgPtr slip_msg;    /* ptr to msg "owned" by the bridge for slip slide*/
  TOS_Msg init_buffer1;   /* a base message buffer */
  TOS_Msg init_buffer2;   /* a base message buffer */
  char slip_tx_pending;   /* we have an outstanding TX message to the uart*/
  char radio_tx_pending;  /* outstanding message flag to the radio */
}
TOS_FRAME_END(SLIP_BRIDGE_frame);


/* ------------------ Initialization section  --------------------*/
char TOS_COMMAND(SLIP_BRIDGE_INIT)(){ 

  VAR(radio_msg) = (TOS_MsgPtr) &(VAR(init_buffer1)); 
  VAR(slip_msg)  = (TOS_MsgPtr) &(VAR(init_buffer2)); 

  VAR(slip_tx_pending) = 0 ;
  VAR(radio_tx_pending) = 0 ;

  /* init the radio side then the slip side */
  if (TOS_CALL_COMMAND(SLIP_BRIDGE_SUB_RADIO_INIT)() == HANDSHAKE_FAILIED) {
    return HANDSHAKE_FAILIED;
  }

  TOS_CALL_COMMAND(SLIP_BRIDGE_SUB_LED_INIT)();

  TOS_CALL_COMMAND(SLIP_BRIDGE_SUB_TOG_GREEN)(); /* bang the red led */
  return (TOS_CALL_COMMAND(SLIP_BRIDGE_SUB_SLIP_INIT)());
}

/* don't do anything here (yet) */
char TOS_COMMAND(SLIP_BRIDGE_START)(){ 
  return HANDSHAKE_SUCCESS;
}

/* another power-mode command */
char TOS_COMMAND(SLIP_BRIDGE_POWER)(char mode){ 

  TOS_CALL_COMMAND(SLIP_BRIDGE_SUB_SLIP_POWER)(mode); 
  TOS_CALL_COMMAND(SLIP_BRIDGE_SUB_RADIO_POWER)(mode); 
  
  return HANDSHAKE_SUCCESS ;
}

/* ------------------------ Radio side ---------------------------*/

/* handle an incomming message from the radio */
TOS_MsgPtr TOS_MSG_EVENT(SLIP_BRIDGE_RX_RADIO)(TOS_MsgPtr rx_msg) { 
  TOS_MsgPtr ret_msg; 
  int i,len; 

  ret_msg= rx_msg;        /* assume we're giving back the original buffer */

  if(VAR(slip_tx_pending) == 0) {

    /* swap the bridge SLIP TX buffer with the radio's RX buffer */
    ret_msg = VAR(slip_msg);
    VAR(slip_msg) = rx_msg;
    
    /* save the len field from the first word of the message */
    len = (int) (rx_msg->data[0]);

    /* and copy the rest of it in-place, thus nuking it */
    /* not efficient, but TOS msg's don't have a len field (yet) */
    for (i=0; i< len; i++) {
      rx_msg->data[i] = rx_msg->data[i+1];
    }
    
    /* call the slip side to TX the message */
    if(TOS_CALL_COMMAND(SLIP_BRIDGE_TX_SLIP)(VAR(slip_msg),(short)len)){
      TOS_CALL_COMMAND(SLIP_BRIDGE_SUB_TOG_RED)(); /* bang the red led */
      VAR(slip_tx_pending)  = 1;
    }
  }

  /* give back some buffer to the radio (generic base) */
  return ret_msg;
}

/* This event signals the radio TX is done, which was caused by the 
 * the SLIP RX event */
char TOS_EVENT(SLIP_BRIDGE_TX_RADIO_DONE)(TOS_MsgPtr tx_msg) { 

  if(VAR(radio_msg) == tx_msg){
    TOS_CALL_COMMAND(SLIP_BRIDGE_SUB_TOG_YELLOW)(); /* bang the green led */
    VAR(radio_tx_pending) = 0;
  }  

  return EVENT_SUCCESS;
}

/* ------------------------ SLIP side ----------------------------*/
TOS_MsgPtr TOS_EVENT(SLIP_BRIDGE_RX_SLIP)(TOS_MsgPtr rx_msg, short len) { 

  TOS_MsgPtr ret_msg; 
  int i; 

  ret_msg= rx_msg;        /* assume we're giving back the original buffer */

  if(VAR(radio_tx_pending) == 0) {

    /* swap the bridge radio TX buffer with the SLIP driver's RX buffer */
    ret_msg = VAR(radio_msg);
    VAR(radio_msg) = rx_msg;
    /* shift the bytes down by one. Should check the MTU here*/
    for (i=len; i > 0 ; i--) {
      rx_msg->data[i] = rx_msg->data[i-1];
    }    

    /* insert the length into the 1st byte */
    rx_msg->data[0] = len;
    
    /* call the radio side to TX the message */
    if(TOS_CALL_COMMAND(SLIP_BRIDGE_TX_RADIO)(BRIDGE_DEST,
					      AM_MSG(SLIP_BRIDGE_RX_RADIO),
					      VAR(radio_msg))) {
      VAR(radio_tx_pending)  = 1;
      TOS_CALL_COMMAND(SLIP_BRIDGE_SUB_TOG_GREEN)(); /* bang the green led */
    }
  }

  /* give back some buffer to the radio (generic base) */
  return ret_msg;  
}

/* handle the event where the SLIP driver tells us it's done */
/* This even signals the SLIP/UART TX is done, which was caused by the 
 * the Radio RX event */
char TOS_EVENT(SLIP_BRIDGE_TX_SLIP_DONE)(TOS_MsgPtr tx_msg) { 

  if(VAR(slip_msg) == tx_msg){
    VAR(slip_tx_pending) = 0;
  }

  return EVENT_SUCCESS;
}
