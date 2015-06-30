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

module RouteTestM {
  provides interface StdControl;
  uses interface ERoute;
  uses interface Leds;  
  uses interface RoutingReceive as CmdRecv;
  uses command void getRouteData(SpanTreeStatusConcise_t* status);
  uses interface EvaderDemoStore;
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
    case RT2MCD_ROUTED: {
      RT2CommandD* cmdD = (RT2CommandD*)cmd;
      if (cmdD->action.action == RT2AD_ROUTE_DATA) {
	call getRouteData((SpanTreeStatusConcise_t*)cmdD->action.values);
        call ERoute.send (cmd->dest, sizeof (struct RT2ActionD),
                          (uint8_t*)&cmd->action);
      }
      else if (cmdD->cmd == RT2AD_LOCATION_DATA) {
        uint16_t* vals = (uint16_t*)cmdD->action.values;
	vals[0] = call EvaderDemoStore.getPositionX();
	vals[1] = call EvaderDemoStore.getPositionY();
	vals[2] = call EvaderDemoStore.getEvaderX();
	vals[3] = call EvaderDemoStore.getEvaderY();
	call ERoute.send (cmd->dest, sizeof (struct RT2ActionD),
                          (uint8_t*)&cmd->action);
      }			 
      else if (cmdD->cmd == RT2AD_SET_LOCATION) {
        uint16_t* vals = (uint16_t*)cmdD->action.values;
        call EvaderDemoStore.setRealPosition(vals[0], vals[1]);
      }
      else if (cmdD->cmd == RT2AD_SET_EVADER) {
        uint16_t* vals = (uint16_t*)cmdD->action.values;
        call EvaderDemoStore.setRealEvader(vals[0], vals[1]);
      }}
      break;
      case RT2MCD_ACTIVATE_EVADER_REAL:
        call EvaderDemoStore.useEstimatedEvader(FALSE);
	break;
      case RT2MCD_ACTIVATE_EVADER_ESTIMATE:
        call EvaderDemoStore.useEstimatedEvader(TRUE);
	break;
      case RT2MCD_ACTIVATE_LOCATION_REAL:
	call EvaderDemoStore.useWhichPosition(POSITION_WORD);
	break;
      case RT2MCD_ACTIVATE_LOCATION_ESTIMATE: 
	call EvaderDemoStore.useWhichPosition(POSITION_LOCALIZED);
	break;
    default:
    }
    return pMsg;
  }

  event result_t ERoute.sendDone (EREndpoint dest, uint8_t * data)
    {
      return SUCCESS;
    }

  event result_t ERoute.receive (EREndpoint dest, uint8_t len, uint8_t * data)
    {
      struct RT2Action * action = (struct RT2Action *)data;
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
      default:
      }
      return SUCCESS;
    }


}
