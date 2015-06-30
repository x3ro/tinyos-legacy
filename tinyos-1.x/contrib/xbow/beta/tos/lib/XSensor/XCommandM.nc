/**
 * Provides a library module for handling basic application messages for
 * controlling a wireless sensor network.
 * 
 * @file      XCommandM.nc
 * @author    Martin Turon
 * @version   2004/10/1    mturon      Initial version
 *
 * Summary of XSensor commands:
 *      reset, sleep, wakeup
 *  	set/get (rate) "heartbeat"
 *  	set/get (nodeid, group)
 *  	set/get (radio freq, band, power)
 *  	actuate (device, state)
 *  	set/get (calibration)
 *  	set/get (mesh type, max resend)
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 *
 * $Id: XCommandM.nc,v 1.2 2004/11/11 00:59:47 mturon Exp $
 */

includes XCommand;


module XCommandM {
  provides {
    interface XCommand;
  }

  uses {
    interface Receive as Bcast; 
    interface ReceiveMsg; 
    interface Leds; 

    interface CC1000Control;
  }
}

implementation {

 /** 
  * Provided for debugging of module-level wiring. 
  *
  * Wire directly to GenericComm in application:
  *    XCommandC.ReceiveMsg -> Comm.ReceiveMsg[AM_XCOMMAND_MSG];
  *
  * @version   2004/10/5   mturon     Initial version
  */
  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr pMsg) 
  {
      //call Leds.redToggle();
      return pMsg;
  }

 /** 
  * Handle default LED acctuation handling.
  *
  * @version   2004/11/2   mturon     Initial version
  */
  static void XCommandAcctuate(uint16_t device, uint16_t state) {
      switch (device) {
	  
	  case XCMD_DEVICE_LEDS: 
	      call Leds.set(state);
	      break;
	      
	  case XCMD_DEVICE_LED_GREEN: 
	      switch (state) {
		  case 0: call Leds.greenOff();     break;
		  case 1: call Leds.greenOn();      break;
		  case 2: call Leds.greenToggle();  break;
	      }
	      break;
	      
	  case XCMD_DEVICE_LED_RED: 
	      switch (state) {
		  case 0: call Leds.redOff();       break;
		  case 1: call Leds.redOn();        break;
		  case 2: call Leds.redToggle();    break;
	      }
	      break;

	  case XCMD_DEVICE_LED_YELLOW: 
	      switch (state) {
		  case 0: call Leds.yellowOff();    break;
		  case 1: call Leds.yellowOn();     break;
		  case 2: call Leds.yellowToggle(); break;
	      }
	      break;
	      
	  default: break;
      }      
  }

 /** 
  * Performs main command parsing and signal callback to application.
  *
  * NOTE: Bcast messages will not be received if seq_no is not properly
  *       set in first two bytes of data payload.  Also, payload is 
  *       the remaining data after the required seq_no.
  *
  * @version   2004/10/5   mturon     Initial version
  */
  event TOS_MsgPtr Bcast.receive(TOS_MsgPtr pMsg, void* payload, 
				 uint16_t payloadLen) 
  {
      XCommandMsg *cmdMsg = (XCommandMsg *)payload;
      XCommandOp  *opcode = &(cmdMsg->inst[0]);

      // Basic group filter
      if (!((pMsg->group == 0xFF) || (pMsg->group == TOS_AM_GROUP)))
	  return pMsg; 

      // Basic nodeid filter
      if ((cmdMsg->dest != 0xFFFF) && (cmdMsg->dest != TOS_LOCAL_ADDRESS)) 
	  return pMsg; 

      // Forward command message to application.
      if (signal XCommand.received(opcode) != SUCCESS) return pMsg;

      // Perform default handling.
      switch (opcode->cmd) {

	  case XCOMMAND_RESET:
	      // Link into NetProg instead.
	      wdt_disable();
	      wdt_enable(1); while(1);
              break;

	  case XCOMMAND_SET_NODEID:
	      // Only allow programming nodeid via direct UART, 
	      // or over RF to a specific destination node (broadcast illegal) 
	      if (cmdMsg->dest == 0xFFFF)  
		  break;    // In case of broadcast to UART, drop forwarding.
	      TOS_LOCAL_ADDRESS = opcode->param.nodeid;
	      break;

	  case XCOMMAND_SET_GROUP:
	      TOS_AM_GROUP = opcode->param.group;
	      break;

	  case XCOMMAND_SET_RF_POWER:
	      call CC1000Control.SetRFPower(opcode->param.rf_power);
	      break;

	  // Handle LED actuation.
	  case XCOMMAND_ACTUATE: {
	      uint16_t device = opcode->param.actuate.device;
	      uint16_t state  = opcode->param.actuate.state;
	      XCommandAcctuate(device, state);
	      break;
	  }

	  default:
	      break;
      }    

      return pMsg;
  }
  
}
