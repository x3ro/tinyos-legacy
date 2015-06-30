// ex: set tabstop=2 shiftwidth=2 expandtab syn=c:
// $Id: TestBVRSimpleM.nc,v 1.1 2005/11/19 02:58:52 rfonseca76 Exp $

/*                                                                      
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/*
 * Authors:  Rodrigo Fonseca
 * Date Last Modified: 2005/05/26
 */


includes AM;
includes BVR;

module TestBVRSimpleM {
  provides {
    interface StdControl;
    command result_t routeTo(Coordinates * destination, uint16_t addr, uint8_t r_mode);
  }
  uses {
    interface BVRSend as Send;
    interface BVRReceive as Receive;
    interface StdControl as RouterControl;

    interface LBlink;
    interface StdControl as LBlinkControl;
    interface Leds;

  }
}

implementation {


  TOS_Msg send_buffer;
  uint8_t *pAppMsg;
  uint16_t payloadLength;
  Coordinates dest;
  bool busy_sending;

  uint16_t d; //used to store the data that is passed around

  uint16_t mode;
  uint16_t dest_id;

  uint16_t msg_id;
   
  task void sendAnother();

  command result_t StdControl.init() { 
    call RouterControl.init();
    call Leds.init();
    call LBlinkControl.init();

    pAppMsg = (uint8_t*) call Send.getBuffer(&send_buffer,&payloadLength);
    msg_id = 1;
    busy_sending = 0;
 
    mode = 0;
    return SUCCESS;
  }

  command result_t StdControl.start() {  
    call RouterControl.start();
    call LBlinkControl.start();
    call LBlink.setRate(100);
    call LBlink.yellowBlink(3);
    call LBlink.greenBlink(2);
    call LBlink.redBlink(1);
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    call RouterControl.stop();
    call LBlinkControl.stop();
    return SUCCESS;
  }

  task void sendAnother() {
    if (busy_sending) {
      dbg(DBG_ROUTE,"sendAnother: mode:%d!!\n", mode);  
      if (call Send.send(&send_buffer, 2, &dest, dest_id, mode) != SUCCESS) {
        dbg(DBG_ROUTE,"sendAnother: send failed\n");
        busy_sending = FALSE;
      }
    } else 
      dbg(DBG_ROUTE,"sendAnother ERROR: called without busy_sending set\n");
  }

  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
    //finished sending
    if (msg == &send_buffer) {
      busy_sending = FALSE;
    } else {
      dbg(DBG_ROUTE,"App Send$sendDone: msg (%p)!=&send_buffer(%p)!\n",msg,&send_buffer);
    }
    return SUCCESS;
  }

  event TOS_MsgPtr Receive.receive(TOS_MsgPtr msg, void* payload, uint16_t payloadLen) {
    //final hop, received message
    d = *(uint16_t*)payload;
    dbg(DBG_ROUTE,"ReceiveApp: %d!!\n", d);  
    return msg; //we are done with the buffer
  }
	

  command result_t routeTo(Coordinates * destination, uint16_t addr, uint8_t r_mode) {
    dbg(DBG_USR2,"Received routeTo: addr:%d mode:%d coords:",addr,r_mode);
    if (!busy_sending) {
      coordinates_copy(destination, &dest);
      dest_id = addr;
      mode = r_mode;
      coordinates_print(DBG_USR2, &dest);
      *((uint16_t*)pAppMsg) = msg_id;
      msg_id++;  
      if (post sendAnother()) {
        busy_sending = TRUE;
        return SUCCESS;
      }
    }
    dbg(DBG_USR2, "routeTo failed\n ");
    return FAIL;
  }
}
