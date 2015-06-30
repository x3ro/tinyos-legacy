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

/**
 * 
 * This application serves as a test of off-chip EEPROM functionality. The
 * application is meant to be used with net/tinyos/tools/TestEEPROM.java
 * application; it provides interfaces for testing the reading and writing
 * functions of the EEPROM. The mote running this code should turn on the red
 * LED on initialization; from that point on the LEDs toggle.  Green LED is
 * toggled when the app receives the command to either read or write to
 * EEPROM; red LED toggles when the app attempt to send a response, and yellow
 * LED toggles when the app thinks that the response transmission was
 * successful.  Contents of the response can be displayed with GenericBase
 * and ForwarderListen tools. 
 *
 * @author tinyos-help@millennium.berkeley.edu
 *
 */ 

module TestEEPROMM
{
  provides interface StdControl;

  uses {
    interface StdControl as EEPROMControl;
    interface PageEEPROM;

    interface Leds;

    interface StdControl as CommControl;
    interface ReceiveMsg as ReceiveTestMsg;
    interface SendMsg as SendResultMsg;

    interface Debug;
  }
}
implementation
{
  TOS_Msg buffer; 
  TOS_MsgPtr msg;
  bool bufferInuse;

  /** 
   * Application initialization code. Initializes subcomponents: the eeprom
   * driver and the communication stack. 
   *
   * @return always SUCCESS
   */

  command result_t StdControl.init() {
    call EEPROMControl.init();
    call CommControl.init();
    call Leds.init();
    
    msg = &buffer;
    bufferInuse = 0;
    dbg(DBG_BOOT, "EETEST initialized\n");
    call Leds.redOn();

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Debug.init();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  /** 
   * When a message has been sent, the app marks the message buffer as
   * available for further use. The buffer will be used in processing further
   * directives from the network. 
   * 
   * @return Always SUCCESS.
   */

  event result_t SendResultMsg.sendDone(TOS_MsgPtr data, result_t success) {
    call Leds.yellowToggle();
    if(msg == data)
      {
	dbg(DBG_USR2, "EETEST send buffer free\n");
	bufferInuse = FALSE;
      }
    return SUCCESS;
  }

  /** 
   * Helper function used to produce the final response of the app to the
   * command fron the network.  The first byte of the message is the success
   * code; the remainder is the response specic data. The return codes are as
   * follows: 
   *<ul>
   *<li> 0x80 -- READ command was not accepted by the driver
   *<li> 0x82 -- WRITE command was not accepted by the driver
   *<li> 0x84 -- READ command failed 
   *<li> 0x85 -- WRITE command failed to write data into the temporary buffer
   *<li> 0x86 -- WRITE command failed to flush the temporary buffer into
   *nonvolatile storage. 
   *<li> 0x90 -- READ command succeeded 
   *<li> 0x91 -- WRITE command succeeded 
   *</ul>
   */ 

  void sendAnswer(uint8_t code) {
    TOS_MsgPtr lmsg = msg;

    call Leds.redToggle();
    lmsg->data[0] = code;
    if (!call SendResultMsg.send(TOS_UART_ADDR, DATA_LENGTH, lmsg))
      bufferInuse = FALSE;
  }

  /** 
   * This event is called when the eeprom read command succeeds; it sends a
   * message indicating the success or failure of the operation. If read
   * succeeded the data read will be located in the response buffer, starting
   * at the 3rd byte. 
   *
   * @return Always SUCCESS
   */ 

  event result_t PageEEPROM.readDone(result_t success) {
    sendAnswer(success ? 0x90 : 0x8f);
    return SUCCESS;
  }

  /**
   * This event is invoked when EEPROM finishes transfering data into its
   * temporary buffer. In this app the temporary buffer is immediately flushed
   * to nonvolatile storage. If a transfer to the temporary buffer failed,
   * this handler will send a response code over the radio. 
   *
   * @return Always SUCCESS. 
   */ 

  event result_t PageEEPROM.writeDone(result_t success) {
    sendAnswer(success ? 0x92 : 0x8f);
    return SUCCESS;
  }

  event result_t PageEEPROM.syncDone(result_t success) {
    sendAnswer(success ? 0x91 : 0x8f);
    return SUCCESS;
  }

  event result_t PageEEPROM.flushDone(result_t success) {
    sendAnswer(success ? 0x91 : 0x8f);
    return SUCCESS;
  }

  event result_t PageEEPROM.eraseDone(result_t success) {
    sendAnswer(success ? 0x93 : 0x8f);
    return SUCCESS;
  }

  event result_t PageEEPROM.computeCrcDone(result_t success, uint16_t crc) {
    msg->data[1] = crc;
    msg->data[2] = crc >> 8;
    sendAnswer(success ? 0x93 : 0x8f);
    return SUCCESS;
  }

  /** 
   * Decode the message buffer: pull out operation (0 for read, 2 for write),
   * code, decode the address, and execute the operation. 
   */ 

  task void processPacket() {
    TOS_MsgPtr lmsg = msg;
    uint8_t error = 0x7f;
    uint8_t page = lmsg->data[1];
    uint8_t offset = lmsg->data[2];
    uint8_t length = lmsg->data[3];
    uint8_t *buffer = (uint8_t *)lmsg->data + 4;

    switch (lmsg->data[0])
      {
      case 0: /* Read a line */
	if (call PageEEPROM.read(page, offset, buffer, length))
	  return;
	error = 0x80;
	break;
      case 1: /* Sync */
	if (call PageEEPROM.sync(page))
	  return;
	error = 0x81;
      case 2: /* Write a line */
	if (call PageEEPROM.write(page, offset, buffer, length))
	  return;
	error = 0x82;
	break;
      case 3: /* page erase */
	if (call PageEEPROM.erase(page, TOS_EEPROM_ERASE))
	  return;
	error = 0x83;
	break;
      case 4: /* check crc */
	if (call PageEEPROM.computeCrc(page, offset, length))
	  return;
	error = 0x84;
	break;
      }
    sendAnswer(error);
  }


  /** 
   * When the command message has been received, this handler check if the
   * previous operation was completed, and if so it will dispatch the incoming
   * message to processPacket task. 
   *
   */

  event TOS_MsgPtr ReceiveTestMsg.receive(TOS_MsgPtr data) {
    TOS_MsgPtr tmp = data;

    call Leds.greenToggle();
    dbg(DBG_USR2, "EETEST received packet\n");
    if (!bufferInuse)
      {
	bufferInuse = TRUE;
	tmp = msg;
	msg = data;
	dbg(DBG_USR2, "EETEST forwarding packet\n");
	post processPacket();
      }
    return tmp;
  }
}
