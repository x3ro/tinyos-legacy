// $Id: ErrorMgrM.nc,v 1.5 2006/05/18 19:58:40 chien-liang Exp $

/* Agilla - A middleware for wireless sensor networks.
 * Copyright (C) 2004, Washington University in Saint Louis 
 * By Chien-Liang Fok.
 * 
 * Washington University states that Agilla is free software; 
 * you can redistribute it and/or modify it under the terms of 
 * the current version of the GNU Lesser General Public License 
 * as published by the Free Software Foundation.
 * 
 * Agilla is distributed in the hope that it will be useful, but 
 * THERE ARE NO WARRANTIES, WHETHER ORAL OR WRITTEN, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO, IMPLIED WARRANTIES OF 
 * MERCHANTABILITY OR FITNESS FOR A PARTICULAR USE.
 *
 * YOU UNDERSTAND THAT AGILLA IS PROVIDED "AS IS" FOR WHICH NO 
 * WARRANTIES AS TO CAPABILITIES OR ACCURACY ARE MADE. THERE ARE NO 
 * WARRANTIES AND NO REPRESENTATION THAT AGILLA IS FREE OF 
 * INFRINGEMENT OF THIRD PARTY PATENT, COPYRIGHT, OR OTHER 
 * PROPRIETARY RIGHTS.  THERE ARE NO WARRANTIES THAT SOFTWARE IS 
 * FREE FROM "BUGS", "VIRUSES", "TROJAN HORSES", "TRAP DOORS", "WORMS", 
 * OR OTHER HARMFUL CODE.  
 *
 * YOU ASSUME THE ENTIRE RISK AS TO THE PERFORMANCE OF SOFTWARE AND/OR 
 * ASSOCIATED MATERIALS, AND TO THE PERFORMANCE AND VALIDITY OF 
 * INFORMATION GENERATED USING SOFTWARE. By using Agilla you agree to 
 * indemnify, defend, and hold harmless WU, its employees, officers and 
 * agents from any and all claims, costs, or liabilities, including 
 * attorneys fees and court costs at both the trial and appellate levels 
 * for any loss, damage, or injury caused by your actions or actions of 
 * your officers, servants, agents or third parties acting on behalf or 
 * under authorization from you, as a result of using Agilla. 
 *
 * See the GNU Lesser General Public License for more details, which can 
 * be found here: http://www.gnu.org/copyleft/lesser.html
 */

includes Agilla;

/**
 * Manages address information, e.g., determines if a mote is a base
 * station and what the original address is.
 *
 * @author Chien-Liang Fok
 */
module ErrorMgrM {
  provides {
    interface StdControl;
    interface ErrorMgrI;
  }
  uses {
    interface Leds;
    interface AgentMgrI;
    interface AddressMgrI;
    interface CodeMgrI;
    interface Timer as ErrorTimer;
    interface SendMsg as SendError;
    interface ReceiveMsg as ReceiveError;  
  }
}
implementation {
  /** 
   * Determines whether the mote is in an error state.
   * A mote enters an error state when an agent crashes.
   */
  bool inErrorState;

  /**
   * A message buffer used for sending error messages.
   */
  TOS_Msg msg;    
  
  command result_t StdControl.init() {
    call Leds.init();
    inErrorState = FALSE;
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  /**
   * Called when an error with no associated data occurs.
   *
   * @param context The agent context that caused the error.
   */
  command result_t ErrorMgrI.error(AgillaAgentContext* context, uint8_t cause) {
    return call ErrorMgrI.errord(context, cause, 0);  
  }
  
  /**
   * Called when an error with one data parameter occurs.
   *
   * @param context The agent context that caused the error.
   * @param data1 The associated data paramter.
   */
  command result_t ErrorMgrI.errord(AgillaAgentContext* context, uint8_t cause, 
    uint16_t data1) 
  {
    return call ErrorMgrI.error2d(context, cause, data1, 0);
  }
  
  /**
   * Called when an error with two data parameters occurs.
   *
   * @param context The agent context that caused the error.
   * @param data1 The first associated data paramter.
   * @param data2 The second associated data parameter.
   */
  command result_t ErrorMgrI.error2d(AgillaAgentContext* context, uint8_t cause, 
    uint16_t data1, uint16_t data2) 
  {
    AgillaErrorMsg* errorMsg = (AgillaErrorMsg*)msg.data;
    inErrorState = TRUE;
    
    dbg(DBG_ERROR|DBG_USR1, "VM (%i, %i): Entering ERROR state. Agent: %i, pc: %i, cause %i (0x%x), reason1 %i, reason2 %i\n", 
      context == NULL ? 9999 : context->id.id,
      context == NULL ? 9999 : context->pc-1,
      context == NULL ? 9999 : context->id.id, 
      context == NULL ? 9999 : context->pc-1, 
      cause, cause, data1, data2);
    
    call Leds.redOn();
    call Leds.greenOff();
    call Leds.yellowOn();
    
    call ErrorTimer.start(TIMER_ONE_SHOT, 1024);    
    errorMsg->cause = cause;
    errorMsg->src = TOS_LOCAL_ADDRESS;
    errorMsg->reason1 = data1;
    errorMsg->reason2 = data2;
    
    if (context != NULL) {    
      //context->state = AGILLA_STATE_HALT;
      errorMsg->id = context->id;            
      errorMsg->pc = context->pc - 1;
      errorMsg->instr = call CodeMgrI.getInstruction(context, context->pc - 1);
      errorMsg->sp = context->opStack.sp;                  
      call AgentMgrI.reset(context);
    }
    else {
      errorMsg->id.id = 0xffff;
      errorMsg->pc = 0xffff;
      errorMsg->instr = 0xff;
      errorMsg->sp = 0xff;
    }
    return SUCCESS;        
  }
  
  /**
   * Returns SUCCESS if Agilla is in an error state, 
   * else returns FAIL.
   */
  command result_t ErrorMgrI.inErrorState() {
    return inErrorState;
  }
  
  command result_t ErrorMgrI.reset() {
    inErrorState = FALSE;
    return SUCCESS;
  }

  /**
   * Toggle the LEDs and broadcasting a message announcing the fact that an error
   * has occurred.
   */
  event result_t ErrorTimer.fired() {
    dbg(DBG_USR1|DBG_ERROR, "ErrorMgrM: ERROR cause = %i\n", ((AgillaErrorMsg*)msg.data)->cause);
    
    call Leds.redToggle();
    call Leds.greenToggle();
    call Leds.yellowToggle();

    if (call AddressMgrI.isGW())    
      call SendError.send(TOS_UART_ADDR, sizeof(AgillaErrorMsg), &msg);
    else
      call SendError.send(TOS_BCAST_ADDR, sizeof(AgillaErrorMsg), &msg);
    
    if (inErrorState)
      call ErrorTimer.start(TIMER_ONE_SHOT, 1024);
    
    return SUCCESS;
  }  
  
  /**
   * Base station forwards the error message over the UART.  All other nodes
   * ignore received error messages.
   */
  event TOS_MsgPtr ReceiveError.receive(TOS_MsgPtr m) {
    if (call AddressMgrI.isGW()) {
      msg = *m;
      call SendError.send(TOS_UART_ADDR, sizeof(AgillaErrorMsg), &msg);
    }
    return m;
  }  
  
  event result_t SendError.sendDone(TOS_MsgPtr mesg, result_t success) {
    return SUCCESS;
  }  
}
