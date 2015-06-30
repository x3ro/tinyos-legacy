/*									
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
 * Author: Naveen Sastry, nks
 */
includes SpanTree;

module RouteInterpretM {
  provides interface StdControl;
  uses interface ERoute;
  uses interface Leds;  
  uses interface RoutingReceive as CmdRecv;
  uses interface RoutingSendByAddress as AnswerSend;
} implementation {
  TOS_Msg msg;
  command result_t StdControl.init ()
    {
      return SUCCESS;
    }

  command result_t StdControl.start ()
    {
      return SUCCESS;
    }

  command result_t StdControl.stop ()
    {
      return SUCCESS;
    }

  event TOS_MsgPtr CmdRecv.receive(TOS_MsgPtr pMsg) {
    RT2Command * cmd = (RT2Command *) pMsg->data;
    int i = 0;
    //call Leds.yellowToggle();    
    for (i = 0 ; i < pMsg->length; i++) {
      dbg(DBG_USR1, "** RT: CmdRecv.receive [%d] %x\n", i, pMsg->data[i]);
    }
    dbg(DBG_USR1, "** RT: CmdRecv.receive. sizeof(cmd->cmd %d)\n", sizeof(cmd->cmd));     
    dbg(DBG_USR1, "** RT: CmdRecv.receive. cmdType = %d\n", (uint16_t)cmd->cmd);
    switch (cmd->cmd) {
    case RT2MCD_TREE_ROOT:
      //call Leds.redToggle();
      dbg(DBG_USR1, "**RT: building span tree %d\n", TREE_LANDMARK); 
      call ERoute.build (TREE_LANDMARK);
      break;
    case RT2MCD_CRUMB_BUILD:
      // fixme: the seqno doesn't matter now, but when it does, you'll need to
      // fix this.
      //call Leds.greenToggle();      
      dbg(DBG_USR1, "**RT: building a crumb trail on tree %d\n", cmd->dest); 
      call ERoute.buildTrail (cmd->dest, TREE_LANDMARK, 100);
      break;
    case RT2MCD_ROUTE:
      //call Leds.yellowToggle();            
      dbg(DBG_USR1, "**RT: routing a message to %d\n", cmd->dest);       
      call ERoute.send (cmd->dest, sizeof (struct RT2Action),
                        (uint8_t*)&cmd->action);
      break;
    case RT2CMD_CLEARLEDS:
      call Leds.set (0);
      break;
    default:
    }
    return pMsg;
  }

  event result_t AnswerSend.sendDone(TOS_MsgPtr ptr, result_t success)
    {
      return SUCCESS;
    }
  
  event result_t ERoute.sendDone (EREndpoint dest, uint8_t * data)
    {
      return SUCCESS;
    }

  event result_t ERoute.receive (EREndpoint dest, uint8_t len, uint8_t * data)
    {
      struct RT2Action * action = (struct RT2Action *)data;
      struct RT2AnswerMsg * asmsg;
      int i;
      for (i = 0; i < len; i++) {
        dbg(DBG_USR1, "** RT: ERoute.receive [%d] %x\n", i, data[i]);
      }
      dbg(DBG_USR1, "**RT: ERoute.receive %d\n", action->action);      
      switch (action->action) {
      case RT2A_LEDS:
        dbg(DBG_USR1, "**RT: Setting leds to %d\n", action->value);
        call Leds.set(action->value);
        break;
      case RT2A_BCAST:
        dbg(DBG_USR1, "**RT: sending msg to %d\n", action->value);
        call Leds.set(action->value);        
        initRoutingMsg( &msg, 0);
        msg.length = sizeof(struct RT2AnswerMsg);
        asmsg = (struct RT2AnswerMsg *)msg.data;
        asmsg->value = action->value;
        asmsg->timestampout = action->timestampout;
        asmsg->timestampin  = 0;
        msg.ext.retries = 0;
        call AnswerSend.send (0, &msg);
      default:
      }
      return SUCCESS;
    }


}
