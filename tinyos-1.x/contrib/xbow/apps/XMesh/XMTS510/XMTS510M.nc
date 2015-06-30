/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 * $Id: XMTS510M.nc,v 1.3 2004/12/21 09:15:52 pipeng Exp $
 */

/******************************************************************************
 *
 *    -Tests the MTS510 Mica2Dot Sensor Board
 *     Reads the light and accelerometer sensor readings
 *     Reads a sound sample
 *-----------------------------------------------------------------------------
 * Output results through mica2dot uart and radio. 
 * Use Xlisten.exe program to view data from either port:
 *  uart: mount mica2dot on mib510 with MTS510
 *        connect serial cable to PC
 *        run xlisten.exe at 19200 baud
 *  radio: run mica2dot with or without MTS510, 
 *         run mica2 with TOSBASE
 *         run xlisten.exe at 57600 baud
 *-----------------------------------------------------------------------------
 * Data packet structure  :
 *  msg->data[0] : sensor id, MTS510 = 0x02
 *  msg->data[1] : packet id
 *  msg->data[2] : node id
 *  msg->data[3] : reserved
 *  msg->data[4,5] : Light ADC data
 *  msg->data[6,7] : ACCEL - X-axis data
 *  msg->data[8,9] : ACCEL - Y-axis data
 *  msg->data[10,11] : Sound sample 0
 *  msg->data[12,13] : Sound sample 1
 *  msg->data[14,15] : Sound sample 2
 *  msg->data[16,17] : Sound sample 3
 *  msg->data[18,19] : Sound sample 4
 * 
 *------------------------------------------------------------------------------
 *
 *****************************************************************************/  

#define STATE_WAITING 0
#define STATE_LIGHT   1
#define STATE_ACCEL   2
#define STATE_SOUND   3

#define SOUNDSAMPLES  5

#include "appFeatures.h"
includes XCommand;
includes sensorboard;

module XMTS510M 
{
  provides interface StdControl;
  uses 
  {
	interface Leds;

	interface Send;
	interface RouteControl;
	interface XCommand;

    interface Timer;

    interface StdControl as AccelControl;
    interface ADC as AccelX;
    interface ADC as AccelY;
    interface StdControl as MicControl;
    interface ADC as MicADC;
    interface Mic;
    interface ADC as PhotoADC;
    interface StdControl as PhotoControl;

#if FEATURE_UART_SEND
	interface SendMsg as SendUART;
	command result_t PowerMgrEnable();
	command result_t PowerMgrDisable();
#endif
  }
}

implementation
{

#define MSG_LEN  29

  TOS_Msg msg_buf;
  TOS_MsgPtr msg_ptr;

  bool sending_packet;
  bool  bIsUart;
  uint8_t samplecount;
  uint8_t state;
  XDataMsg pack;


    uint32_t   timer_rate;  
    bool       sleeping;	       // application command state


  static void initialize() 
    {
      atomic 
      {
    	  sleeping = FALSE;
    	  sending_packet = FALSE;
    	  timer_rate = XSENSOR_SAMPLE_RATE;
      }
    }

task void send_radio_msg() {

    uint16_t  len;
	XDataMsg *data;
    uint8_t i;
    if(sending_packet) return; 
    atomic sending_packet=TRUE;  

    data = (XDataMsg*)call Send.getBuffer(msg_ptr, &len);
	for (i=0; i<= sizeof(XDataMsg)-1; i++)
		((uint8_t*) data)[i] = ((uint8_t*)&pack)[i];
    data->xMeshHeader.board_id = SENSOR_BOARD_ID;
    data->xMeshHeader.packet_id = 1;     
    data->xMeshHeader.node_id = TOS_LOCAL_ADDRESS;
    data->xMeshHeader.parent    = call RouteControl.getParent();

    #if FEATURE_UART_SEND
    	if (TOS_LOCAL_ADDRESS != 0) {
    		call Leds.yellowOn();
    	    call PowerMgrDisable();
    	    TOSH_uwait(1000);
    	    if (call SendUART.send(TOS_UART_ADDR, sizeof(XDataMsg),msg_ptr) != SUCCESS) 
    	    {
        		atomic sending_packet = FALSE;
        		call Leds.greenToggle();
        		call PowerMgrEnable();
    	    }
    	} 
    	else 
    #endif
    	{
    	    // Send the RF packet!
    	    if (call Send.send(msg_ptr, sizeof(XDataMsg)) != SUCCESS) {
        		atomic sending_packet = FALSE;
    		    call Leds.yellowOn();
        		call Leds.greenOff();
    	    }
    	}
    return;

}



  /*************************************** 
     initialize lower components.
  ***************************************/
  command result_t StdControl.init() 
  {

    sending_packet = TRUE;
    atomic{
    msg_ptr = &msg_buf;
    }

    call Leds.init();
    sending_packet = FALSE;
    call MicControl.init();
    call Mic.gainAdjust(64);
    call PhotoControl.init();
    call AccelControl.init();
    state = STATE_WAITING;
    samplecount = 0;

    call Leds.greenOff(); 
    call Leds.yellowOff(); 
    call Leds.redOff(); 

    call Leds.redOn();
    TOSH_uwait(1000);
    call Leds.redOff();
    initialize();
    return SUCCESS;
  }

  command result_t StdControl.start() 
  {
    call MicControl.start();
    call PhotoControl.start();
    call Timer.start(TIMER_REPEAT, timer_rate);

    state = STATE_LIGHT;

    return SUCCESS;
  }

  command result_t StdControl.stop() 
  {
    call Timer.stop();
    call MicControl.stop();
    call PhotoControl.stop();

    return SUCCESS;
  }

/*********************************************
event handlers
*********************************************/

/***********************************************/  
  event result_t Timer.fired() 
  {
    bIsUart=TRUE;
    if (state == STATE_LIGHT) {
      call PhotoADC.getData();
    }
    return SUCCESS;
  }


/*******************************************/
  async event result_t PhotoADC.dataReady(uint16_t data)
  {

	pack.xData.datap1.light = data;

    call AccelX.getData();

    return SUCCESS;
  }  

/**********************************************/
  async event result_t AccelX.dataReady(uint16_t  data)
  {
	pack.xData.datap1.accelX   = data ;
    call AccelY.getData();

    return SUCCESS;
  }

/**************************************************/
  async event result_t AccelY.dataReady(uint16_t  data)
  {

	pack.xData.datap1.accelY = data ;

    call MicADC.getData();

    return SUCCESS;
  }


/***************************************************/    
async event result_t MicADC.dataReady(uint16_t data)
{

    atomic {
       pack.xData.datap1.sound[samplecount] = data ;
       samplecount++;
       if (samplecount == SOUNDSAMPLES) {
           samplecount = 0;
           post send_radio_msg();
       } else { 
           call MicADC.getData();
       }
    }

    return SUCCESS;
}

#if FEATURE_UART_SEND
 /**
  * Handle completion of sent UART packet.
  *
  * @author    Martin Turon
  * @version   2004/7/21      mturon       Initial revision
  */
  event result_t SendUART.sendDone(TOS_MsgPtr msg, result_t success) 
  {
      //      if (msg->addr == TOS_UART_ADDR) {
      atomic msg_ptr = msg;
      msg_ptr->addr = TOS_BCAST_ADDR;
      
      if (call Send.send(msg_ptr, sizeof(XDataMsg)) != SUCCESS) {
	  atomic sending_packet = FALSE;
	  call Leds.yellowOff();
      }
      
      if (TOS_LOCAL_ADDRESS != 0) // never turn on power mgr for base
	  call PowerMgrEnable();
      
      //}
      return SUCCESS;
  }
#endif

 /**
  * Handle completion of sent RF packet.
  *
  * @author    Martin Turon
  * @version   2004/5/27      mturon       Initial revision
  */
  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) 
  {
      atomic {
	  msg_ptr = msg;
	  sending_packet = FALSE;
      }
      call Leds.yellowOff();
      
#if FEATURE_UART_SEND
      if (TOS_LOCAL_ADDRESS != 0) // never turn on power mgr for base
	  call PowerMgrEnable();
#endif
      
      return SUCCESS;
  }

 /** 
  * Handles all broadcast command messages sent over network. 
  *
  * NOTE: Bcast messages will not be received if seq_no is not properly
  *       set in first two bytes of data payload.  Also, payload is 
  *       the remaining data after the required seq_no.
  *
  * @version   2004/10/5   mturon     Initial version
  */
  event result_t XCommand.received(XCommandOp *opcode) {

      switch (opcode->cmd) {
	  case XCOMMAND_SET_RATE:
	      // Change the data collection rate.
	      timer_rate = opcode->param.newrate;
	      call Timer.stop();
	      call Timer.start(TIMER_REPEAT, timer_rate);
	      break;
	      
	  case XCOMMAND_SLEEP:
	      // Stop collecting data, and go to sleep.
	      sleeping = TRUE;
	      call Timer.stop();
	      call Leds.set(0);
              break;
	      
	  case XCOMMAND_WAKEUP:
	      // Wake up from sleep state.
	      if (sleeping) {
		  initialize();
		  call Timer.start(TIMER_REPEAT, timer_rate);
		  sleeping = FALSE;
	      }
	      break;
	      
	  case XCOMMAND_RESET:
	      // Reset the mote now.
	      break;

	  case XCOMMAND_ACTUATE: {
	      state = opcode->param.actuate.state;
	      if (opcode->param.actuate.device != XCMD_DEVICE_SOUNDER) 
                break;
	      }
	      break;	      

	  default:
	      break;
      }    
      
      return SUCCESS;
  }


} 
