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
 * $Id: XCommandM.nc,v 1.3 2005/01/27 03:36:31 husq Exp $
 */

includes XCommand;
#if FEATURE_XEE_PARAMS 
includes config;
#endif

module XCommandM {
  provides {
    interface XCommand;
  }

  uses {
  	interface Send;
    interface Receive as Bcast; 
    interface ReceiveMsg; 
    interface Leds; 
#if FEATURE_XEE_PARAMS       
    interface Config[uint32_t setting];
    interface ConfigSave;
#else
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
    interface CC1000Control;
#else    
    interface CC2420Control;
#endif        
#endif    
    // SerialID
	interface StdControl as DS2401;  
	interface HardwareId;	

  }
}

implementation {
  TOS_Msg msg_buf;
  XCmdDataMsg readings;
  
  /***************************************************************************
 * Task to xmit radio message
 *
 *    msg_radio->addr = TOS_BCAST_ADDR;
 *    msg_radio->type = 0x31;
 *    msg_radio->length = MSG_LEN;
 *    msg_radio->group = TOS_AM_GROUP;
 ***************************************************************************/
    task void send_msg() {
	uint8_t   i;
	uint16_t  len;
	XCmdDataMsg *data;
	
	call Leds.yellowOn();
	// Fill the given data buffer.	    
	data = (XCmdDataMsg*)call Send.getBuffer(&msg_buf, &len);
	
	for (i = 0; i <= sizeof(XCmdDataMsg)-1; i++) 
	    ((uint8_t*)data)[i] = ((uint8_t*)&readings)[i];

	data->xHeader.board_id  = MOTE_BOARD_ID;
	data->xHeader.packet_id = 1;    
	data->xHeader.node_id   = TOS_LOCAL_ADDRESS;
//	data->xHeader.parent    = call RouteControl.getParent();
    if (call Send.send(&msg_buf, sizeof(XCmdDataMsg)) != SUCCESS) {
	    }
	return;
}

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
  
#if FEATURE_XEE_PARAMS     
   event result_t ConfigSave.saveDone(result_t success, AppParamID_t failed)
  {
    return SUCCESS;
  }
#endif

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
#if FEATURE_XEE_PARAMS       	
  	  uint16_t nodeid;
	  uint8_t groupid, rf_power, rf_channel;
#endif	  
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
	  case XCOMMAND_GET_SERIALID:
	  	  call DS2401.init();
	  	  call HardwareId.read((uint8_t *)(&(readings.xData.sid.id[0])));
	  	  break;              
              
	  case XCOMMAND_GET_CONFIG:
#if FEATURE_XEE_PARAMS   
	  	   call Config.get[CONFIG_MOTE_ID](&nodeid,sizeof(uint16_t));
	  	   call Config.get[CONFIG_MOTE_GROUP](&groupid,sizeof(uint8_t));
	  	   call Config.get[CONFIG_CC1000_RF_POWER](&rf_power,sizeof(uint8_t));
	  	   call Config.get[CONFIG_CC1000_RF_CHANNEL](&rf_channel,sizeof(uint8_t));    
#endif	  	   
	  	   break;          

	  case XCOMMAND_SET_NODEID:
	      // Only allow programming nodeid via direct UART, 
	      // or over RF to a specific destination node (broadcast illegal) 
	      if (cmdMsg->dest == 0xFFFF)  
		  break;    // In case of broadcast to UART, drop forwarding.
#if FEATURE_XEE_PARAMS   		  
	      call Config.set[CONFIG_MOTE_ID](&(opcode->param.nodeid),sizeof(uint16_t));
		  call ConfigSave.save(CONFIG_MOTE_ID,CONFIG_MOTE_ID);
#else
	      atomic TOS_LOCAL_ADDRESS = opcode->param.nodeid;
#endif		  
	      break;

	  case XCOMMAND_SET_GROUP:
#if FEATURE_XEE_PARAMS   	  
	      call Config.set[CONFIG_MOTE_GROUP](&(opcode->param.group),sizeof(uint8_t)); 
       	  call ConfigSave.save(CONFIG_MOTE_GROUP,CONFIG_MOTE_GROUP);
#else
	      atomic TOS_AM_GROUP = opcode->param.group;
#endif       	  
	      break;

	  case XCOMMAND_SET_RF_POWER:

#if FEATURE_XEE_PARAMS 
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
		  call Config.set[CONFIG_CC1000_RF_POWER](&(opcode->param.rf_power),sizeof(uint8_t));
		  call ConfigSave.save(CONFIG_CC1000_RF_POWER,CONFIG_CC1000_RF_POWER);
#else
#if defined(PLATFORM_MICAZ)
		  call Config.set[CONFIG_CC2420_RF_POWER](&(opcode->param.rf_power),sizeof(uint8_t));
		  call ConfigSave.save(CONFIG_CC2420_RF_POWER,CONFIG_CC2420_RF_POWER);
#endif
#endif	
#else
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
	      call CC1000Control.SetRFPower(opcode->param.rf_power);
#else	      
		 call CC2420Control.SetRFPower(opcode->param.rf_power);
#endif
#endif
	  
	      break;
	  case XCOMMAND_SET_RF_CHANNEL:
#if FEATURE_XEE_PARAMS 	  
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)	  
		  call Config.set[CONFIG_CC1000_RF_CHANNEL](&(opcode->param.rf_channel),sizeof(uint8_t));
		  call ConfigSave.save(CONFIG_CC1000_RF_CHANNEL,CONFIG_CC1000_RF_CHANNEL);	
#else
#if defined(PLATFORM_MICAZ)
		  call Config.set[CONFIG_CC2420_RF_CHANNEL](&(opcode->param.rf_channel),sizeof(uint8_t));
		  call ConfigSave.save(CONFIG_CC2420_RF_CHANNEL,CONFIG_CC2420_RF_CHANNEL);
#endif		  
#endif	
#endif	  		  
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
  
  
/**
  * Handle completion of sent RF packet.
  *
  * @author    Martin Turon
  * @version   2004/5/27      mturon       Initial revision
  */
  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) 
  {
      return SUCCESS;
  }
  
 
    event result_t HardwareId.readDone(uint8_t *id, result_t success)
  {	
    if(success){
		post send_msg();
    }
    return SUCCESS;
  } 
  
}
