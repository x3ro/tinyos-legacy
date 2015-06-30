// $Id: ResetMgrM.nc,v 1.9 2006/05/26 02:58:20 chien-liang Exp $

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
 * Resets the mote when it receives a reset command from the
 * basestation.
 *
 * @author Chien-Liang Fok
 */
module ResetMgrM {
  provides {
    interface StdControl;
    interface ResetMgrI;
  }
  uses {
    interface Reset;
    
    interface AgentMgrI;
    interface TupleSpaceI;
    interface AddressMgrI;
    interface LEDBlinkerI;
    interface ErrorMgrI;
    interface ReceiveMsg as ReceiveReset;
    interface SendMsg as SendReset;
    interface MessageBufferI;

    interface Leds;

    #if ENABLE_EXP_LOGGING
      interface ExpLoggerI;
    #endif

  }
}
implementation {
  /**
   * Remembers whether the mote is resetting, used to ensure
   * each mote only sends out one reset message while resetting.
   */
  bool resetting;

  /**
   * Remembers whether the mote is waiting for a reset operation
   * to complete.  This is used to prevent continuous reset message
   * flooding when only a single mote in the network needs to be reset.
   */
  bool waiting;

  command result_t StdControl.init()
  {
    resetting = waiting = FALSE;
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }

  /**
   * When the first reset message is received, re-broadcast it then
   * set a reset timer.  When the reset timer fires, reset the mote.
   * After re-broadcasting the reset message, and before the reset
   * timer fires, ignore all other reset messages.
   */
  event TOS_MsgPtr ReceiveReset.receive(TOS_MsgPtr m)
  {
    AgillaResetMsg* rmsg = (AgillaResetMsg*)m->data;

    // Reset this mote only.
    if (call AddressMgrI.isOrigAddress(rmsg->address))
    {
      if (!resetting)
      {
        resetting = TRUE;
        call LEDBlinkerI.blink((uint8_t)RED|GREEN|YELLOW, 1, 1024);
      }
    }

    // Reset all motes.  Re-broadcast the reset message before resetting.
    else if (rmsg->address == TOS_BCAST_ADDR)
    {
      if (!resetting)  // only re-broadcast once (prevents recursive flooding)
      {
        TOS_MsgPtr msg = call MessageBufferI.getMsg();
        if (msg != NULL)
        {
          resetting = TRUE;
          rmsg->from = TOS_LOCAL_ADDRESS;
          *msg = *m;
          if (!call SendReset.send(TOS_BCAST_ADDR, sizeof(AgillaResetMsg), msg))
            call MessageBufferI.freeMsg(msg);
          call LEDBlinkerI.blink((uint8_t)RED|GREEN|YELLOW, 1, 1024);
        }
      }
    }

    // Reset a specific mote.  Get the neighbor closest to the destination
    // and send it to it
    else {
      if (!waiting) // only re-broadcast once
      {
        TOS_MsgPtr msg = call MessageBufferI.getMsg();
        if (msg != NULL)
        {
          waiting = TRUE;
          rmsg->from = TOS_LOCAL_ADDRESS;
          *msg = *m;
          if (!call SendReset.send(TOS_BCAST_ADDR, sizeof(AgillaResetMsg), msg))
            call MessageBufferI.freeMsg(msg);
          call LEDBlinkerI.blink((uint8_t)RED|GREEN|YELLOW, 1, 1024);
        }
      }
    }
    return m;
  }

  /**
   * Signalled when the blinking is done and blink(...) can be called again.
   */
  event result_t LEDBlinkerI.blinkDone()
  {
    if (waiting)
      waiting = FALSE;
    else if (resetting)
    {
      dbg(DBG_USR1, "ResetMgrM: Resetting...\n");
      call Reset.reset();
      
      call AgentMgrI.resetAll();
      call TupleSpaceI.reset();
      call ErrorMgrI.reset();
      call Leds.redOff();
      call Leds.yellowOff();
      call Leds.greenOff();

      #if ENABLE_EXP_LOGGING
        call ExpLoggerI.reset();
      #endif

      resetting = FALSE;
    }
    return SUCCESS;
  }

  event result_t SendReset.sendDone(TOS_MsgPtr m, result_t success)
  {
    call MessageBufferI.freeMsg(m);
    return SUCCESS;
  }

  /**
   * Returns true if the mote is in the process or resetting.
   */
  command result_t ResetMgrI.isResetting() {
    return resetting;
  }

  event result_t TupleSpaceI.newTuple(AgillaTuple* tuple) {
    return SUCCESS;
  }

  event result_t TupleSpaceI.byteShift(uint16_t from, uint16_t amount) {
    return SUCCESS;
  }
}
