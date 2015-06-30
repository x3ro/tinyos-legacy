/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Copyright (c) 2004 Crossbow Technology, Inc.  
 *
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
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE CROSSBOW OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * $Id: TestSensorGGBM.nc,v 1.1 2004/11/22 14:20:45 husq Exp $
 */
module TestSensorGGBM {
  provides {
    interface StdControl;
  }
  uses {
    interface SendMsg;

    interface ADC as ADCBATT;
    interface ADC as ADCTemp;
    interface mADC as mADCAcl;
 
    interface Timer;
    interface Leds;
  }
}

implementation {
  TOS_Msg msg_buf;
  XbowSensorboardPacket *sensor_packet;
  XSensorGGBACLTSTData *sensor_data;
  bool to_uart;

  task void send_radio_msg() {
    call SendMsg.send(TOS_UART_ADDR, sizeof(XbowSensorboardPacket), &msg_buf);
  }
  task void send_uart_msg() {
    call SendMsg.send(TOS_BCAST_ADDR, sizeof(XbowSensorboardPacket), &msg_buf);
  }

  command result_t StdControl.init() {
    call Leds.init();
    sensor_packet = (XbowSensorboardPacket *)msg_buf.data;
    atomic sensor_data = (XSensorGGBACLTSTData *)sensor_packet->data;
 
    sensor_packet->board_id = SENSOR_BOARD_ID;
    sensor_packet->packet_id = 1;
    sensor_packet->node_id = TOS_LOCAL_ADDRESS;
    sensor_packet->parent = 0;
    return SUCCESS;
  }
  command result_t StdControl.start()
  {
    call Leds.greenOn();
    call Timer.start(TIMER_REPEAT, 1000);
    return SUCCESS;	
  }
  command result_t StdControl.stop() {
    return SUCCESS;    
  }



  event result_t Timer.fired() {
    call Leds.redToggle();
    to_uart = TRUE;
    call ADCBATT.getData();
    return SUCCESS;
  }

  async event result_t ADCBATT.dataReady(uint16_t data) {
    sensor_data->vref = data;
    call ADCTemp.getData(); 
      return SUCCESS;
  }
  async event result_t ADCTemp.dataReady(uint16_t data) {
    uint16_t acl_data_buf[4];
    sensor_data->temperature = data;
    call mADCAcl.getData(acl_data_buf);
    sensor_data->high_vertical = acl_data_buf[0];
    sensor_data->high_horizontal = acl_data_buf[1];
    sensor_data->low_vertical = acl_data_buf[2];
    sensor_data->low_horizontal = acl_data_buf[3];
    post send_uart_msg();
    return SUCCESS;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    if (to_uart) {
      to_uart = FALSE;
      post send_radio_msg();
    }
    return SUCCESS;
  }
}

