/*									tab:4
 *
 *
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
 */
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
 */
/*
 * Authors:  Jason Hill  Su Ping
 * Date:     July 29, 2002
 *
 *
 *
 * This component checks the functionality of the device and sends a
 * report message over both the UART and the radio.  It should be run
 * with the java program hardware_check.java, which interprets the
 * report messages. To test the radio, program a second mote with
 * generic_base_high_speed, which will forward the received radio
 * packets to the java program for interpretation.  This program also
 * prints out he serial_ID for the ID chip of the mote.
 */

includes HWVerifyMsg;
module MicaHWVerifyM {
  provides interface StdControl;
  uses {
    interface Leds;
    interface StdControl as CommControl;
    interface SendMsg as Send;
    interface ReceiveMsg;
    interface Clock;
  }
}

implementation {
  uint8_t count;
  TOS_Msg diag;

  void check_FLASH();
  void check_SERIAL_ID();
  void check_SPI_FIX();

  /* MICA_HARDWARE_VERIFY_INIT:  
     flash the LEDs
     initialize lower components.
     initialize component state, including constant portion of msgs.
  */
  command result_t StdControl.init() {
    call Leds.redOff();
    call Leds.greenOff();
    call Leds.yellowOff();
       	
    check_SERIAL_ID();
    check_SPI_FIX();
    check_FLASH();

    call CommControl.init();
    call Clock.setRate(TOS_I2PS, TOS_S2PS); 
    dbg(DBG_BOOT, ("MICA_HARDWARE_VERIFY initialized\n"));
    return 1;
  }

  /* MICA_HARDWARE_VERIFY_START
     start data reading.
  */
  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  /*   MICA_HARDWARE_VERIFY_SUB_MSG_SEND_DONE event handler:
       When msg is sent, shot down the radio.
  */
  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }

  /* Clock Event Handler: 
     signaled at end of each clock interval.

  */
  event result_t Clock.fire() {
    struct DIAG_PACKET* pack = (struct DIAG_PACKET*)diag.data;
    int state = pack->count ++;
    uint16_t dest = 0;
    dest = (pack->send_type ^= 1) & 0x1;
    if (dest) {
      dest = TOS_UART_ADDR;
    } else {
      dest = 0xffff;
    }
    if (state & 1) call Leds.yellowOn();  else call Leds.yellowOff();
    if (state & 2) call Leds.greenOn();  else call Leds.greenOff();
    if (state & 4) call Leds.redOn();  else call Leds.redOff();
    call Send.send(dest, sizeof(struct DIAG_PACKET), &diag);
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr msg) {
    struct DIAG_PACKET* pack = (struct DIAG_PACKET*)diag.data;
    pack->RX_TEST ++;
    return msg;
  }

  void serial_delay(uint16_t u_sec) {
    uint16_t cnt;
    // The loop takes 6 cycles. Adjust u_sec
    u_sec -= (u_sec >> 2) + (u_sec >> 4);
    for (cnt = 0; cnt < u_sec; cnt ++) { cnt++; cnt--; }
  }



  uint8_t serial_ID_read() {
    int i;
    uint8_t data = 0;
    for(i = 0; i < 8; i ++) {
      data >>= 1;
      data &= 0x7f;
      TOSH_MAKE_ONE_WIRE_OUTPUT();
      serial_delay(1);
      TOSH_MAKE_ONE_WIRE_INPUT();
      serial_delay(10);
      if (TOSH_READ_ONE_WIRE_PIN()) {
	data |= 0x80;
      }
      serial_delay(30);
    }
    return data;
  }

  void serial_ID_send(uint8_t data) {
    int i;
    for(i = 0; i < 8; i ++) {
      TOSH_MAKE_ONE_WIRE_OUTPUT();
      serial_delay(1);
      if (data & 0x1) {
	TOSH_MAKE_ONE_WIRE_INPUT();
      }
      serial_delay(50);
      TOSH_MAKE_ONE_WIRE_INPUT();
      serial_delay(10);
      data >>= 1;
    }
  }



  void check_SERIAL_ID() {
    int cnt = 0;
    struct DIAG_PACKET* pack = (struct DIAG_PACKET *)diag.data;
    TOSH_CLR_ONE_WIRE_PIN();
    TOSH_MAKE_FLASH_SELECT_OUTPUT();
    TOSH_SET_FLASH_SELECT_PIN();
    TOSH_MAKE_ONE_WIRE_OUTPUT();
    serial_delay(400);
    cnt = 0;
    TOSH_MAKE_ONE_WIRE_INPUT();
    while (0 ==TOSH_READ_ONE_WIRE_PIN() && cnt < 30) {
      cnt ++;
      serial_delay(40);
    }
    if (cnt < 30) {
      serial_delay(200);
      serial_ID_send(0x33);
      for(cnt = 0; cnt < 8; cnt ++) {
	pack->serial_ID[cnt] = serial_ID_read();
      }
    }
  }



  uint8_t send_byte(uint8_t input) {
    int i;
    for(i = 0; i < 8; i ++) {
      if (input & 0x80) {
	TOSH_SET_FLASH_OUT_PIN();
      }else{
	TOSH_CLR_FLASH_OUT_PIN();
      }
      input <<= 1;
      TOSH_SET_FLASH_CLK_PIN();
      if (TOSH_READ_FLASH_IN_PIN()) {
	input |= 0x1;
      }
      TOSH_CLR_FLASH_CLK_PIN();
    }
    return input;
  }


  void check_FLASH() {
    struct DIAG_PACKET* pack = (struct DIAG_PACKET*)diag.data;
    TOSH_MAKE_ONE_WIRE_INPUT();
    TOSH_MAKE_FLASH_SELECT_OUTPUT();
    TOSH_CLR_FLASH_SELECT_PIN();
    send_byte(0x84);
    send_byte(0x0);
    send_byte(0x0);
    send_byte(0x0);
    send_byte(0x1);
    send_byte(0x8f);
    send_byte(0x9);
    TOSH_SET_FLASH_SELECT_PIN();
    serial_delay(200);
    TOSH_CLR_FLASH_SELECT_PIN();
    send_byte(0xD4);
    send_byte(0x0);
    send_byte(0x0);
    send_byte(0x0);
    send_byte(0x0);
    pack->flash_check[0] = send_byte(0x0);
    pack->flash_check[1] = send_byte(0x0);
    pack->flash_check[2] = send_byte(0x0);
    TOSH_CLR_FLASH_OUT_PIN();
    TOSH_SET_FLASH_SELECT_PIN();
  }

  void check_SPI_FIX() {
    //MAKE
    struct DIAG_PACKET* pack = (struct DIAG_PACKET*)diag.data;
    pack->SPI_FIX = 0;
    pack->flash_comm = 1;
    TOSH_MAKE_ONE_WIRE_OUTPUT();
    TOSH_MAKE_FLASH_SELECT_INPUT();
    TOSH_CLR_ONE_WIRE_PIN();
    serial_delay(200);
	
    if (TOSH_READ_FLASH_SELECT_PIN() == 0) pack->SPI_FIX |= 1;
    else pack->SPI_FIX |=2;
    TOSH_SET_ONE_WIRE_PIN();
    serial_delay(200);
    if (TOSH_READ_FLASH_SELECT_PIN() == 1) pack->SPI_FIX |= 4;
    else pack->SPI_FIX |=8;
    TOSH_MAKE_ONE_WIRE_INPUT();
  }

}
