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
 * $Id: TestSensorMTS510M.nc,v 1.5 2004/12/14 11:04:23 pipeng Exp $
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

includes sensorboard;

module TestSensorMTS510M 
{
  provides interface StdControl;
  uses 
  {
//communication
	interface StdControl as CommControl;
	interface SendMsg as Send;
	interface ReceiveMsg as Receive;

    interface Leds;
    interface Timer;

    interface StdControl as AccelControl;
    interface ADC as AccelX;
    interface ADC as AccelY;
    interface StdControl as MicControl;
    interface ADC as MicADC;
    interface Mic;
    interface ADC as PhotoADC;
    interface StdControl as PhotoControl;

  }
}

implementation
{

#define MSG_LEN  29

  TOS_Msg msg_buf;
  TOS_MsgPtr msg_ptr;

  bool sendPending;
  bool  bIsUart;
  uint8_t samplecount;
  uint8_t state;
  XDataMsg *pack;

task void send_radio_msg() {

    if(sendPending) return;
    atomic sendPending=TRUE;
    call Send.send(TOS_BCAST_ADDR,sizeof(XDataMsg),msg_ptr);
    return;

}

task void send_uart_msg() {

    if(sendPending) return;
    atomic sendPending=TRUE;
    call Send.send(TOS_UART_ADDR,sizeof(XDataMsg),msg_ptr);
    return;

}



  /*************************************** 
     initialize lower components.
  ***************************************/
  command result_t StdControl.init() 
  {

    sendPending = TRUE;
    atomic{
    msg_ptr = &msg_buf;
    }
    pack=(XDataMsg *)msg_ptr->data;

    call CommControl.init();
    call Leds.init();
    sendPending = FALSE;
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

    return SUCCESS;
  }

  command result_t StdControl.start() 
  {
    call MicControl.start();
    call PhotoControl.start();
    call CommControl.start();
    call Timer.start(TIMER_REPEAT, 500);
    pack->xSensorHeader.board_id = SENSOR_BOARD_ID;
    pack->xSensorHeader.packet_id = 1;     // Only one packet for MDA500
    pack->xSensorHeader.node_id = TOS_LOCAL_ADDRESS;
    pack->xSensorHeader.rsvd = 0;

    state = STATE_LIGHT;

    return SUCCESS;
  }

  command result_t StdControl.stop() 
  {
    call Timer.stop();
    call CommControl.stop();
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

	pack->xData.datap1.light = data;

    call AccelX.getData();

    return SUCCESS;
  }  

/**********************************************/
  async event result_t AccelX.dataReady(uint16_t  data)
  {
	pack->xData.datap1.accelX   = data ;
    call AccelY.getData();

    return SUCCESS;
  }

/**************************************************/
  async event result_t AccelY.dataReady(uint16_t  data)
  {

	pack->xData.datap1.accelY = data ;

    call MicADC.getData();

    return SUCCESS;
  }


/***************************************************/    
async event result_t MicADC.dataReady(uint16_t data)
{

    atomic {
       pack->xData.datap1.sound[samplecount] = data ;
       samplecount++;
       if (samplecount == SOUNDSAMPLES) {
           samplecount = 0;
           post send_uart_msg();
       } else { 
           call MicADC.getData();
       }
    }

    return SUCCESS;
}

/****************************************************************************
 * if Uart msg xmitted,Xmit same msg over radio
 * if Radio msg xmitted, issue a new round measuring
 ****************************************************************************/
  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
      //atomic msg_uart = msg;

      
	  sendPending = FALSE;
      //if message have sent by UART, send the message once again by radio.
      if(bIsUart)
      { 
        bIsUart=!bIsUart;  
        post send_radio_msg();
      }
      else
      {
        atomic msg_ptr = msg;
      }
      return SUCCESS;
  }

/****************************************************************************
 * Uart msg rcvd. 
 * This app doesn't respond to any incoming uart msg
 * Just return
 ****************************************************************************/
  event TOS_MsgPtr Receive.receive(TOS_MsgPtr data) {
      return data;
  }

} 
