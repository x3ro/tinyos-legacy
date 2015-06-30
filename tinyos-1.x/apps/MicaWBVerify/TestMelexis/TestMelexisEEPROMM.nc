/*									tab:4
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

/* Authors:  Joe Polastre
 *
 */

includes GDI2SoftMsg;

module TestMelexisEEPROMM {
    provides interface StdControl;
    uses {
        interface Leds;
        interface SplitControl as ADCControl;
        interface StdControl as LowerControl;
	interface SendMsg as Send;
        interface ReceiveMsg as ReadMsg;
        interface ReceiveMsg as WriteMsg;
        interface ThermopileEEPROM;
    }
}
implementation {
  // declare module static variables here
  
  TOS_Msg msg_buf;
  TOS_MsgPtr readmsg;
  TOS_Msg write_msg_buf;
  TOS_Msg ack_msg_buf;
  TOS_MsgPtr writemsg;
  TOS_MsgPtr ackmsg;

  Thermopile_Ack_Msg *ackbuffer;

  uint8_t state;
  uint16_t wrdata[10];

  uint8_t addr;
  uint8_t length;
  uint8_t counter;

  int count;

  enum { IDLE, POWER_OFF, READ, WRITE };

  /**
   * Initialize this and all low level components used in this application.
   * 
   * @return returns <code>SUCCESS</code> or <code>FAIL</code>
   */
  command result_t StdControl.init() {
    readmsg = &msg_buf;
    writemsg = &write_msg_buf;
    ackmsg = &ack_msg_buf;
    ackbuffer = (Thermopile_Ack_Msg*)ackmsg->data;
    state = POWER_OFF;
    call ADCControl.init();
    call Leds.init();
    return SUCCESS;
  }

  /**
   * Start this component.
   * 
   * @return returns <code>SUCCESS</code>
   */
  command result_t StdControl.start(){
    state = IDLE;
    //call ADCControl.start();
    return SUCCESS;
  }

  /**
   * Stop this component.
   * 
   * @return returns <code>SUCCESS</code>
   */
  command result_t StdControl.stop() {
    call ADCControl.stop();
    return SUCCESS;
  }

  task void getTest() {
    call ThermopileEEPROM.setTest(TRUE);
  }

  event result_t ADCControl.startDone() {
    call LowerControl.start();
    post getTest();
    return SUCCESS;
  }

  event result_t ThermopileEEPROM.setTestDone() {
    call ThermopileEEPROM.setWP(TRUE);
    return SUCCESS;
  }

  event result_t ThermopileEEPROM.setWPDone() {
    if (state == WRITE)
      call ThermopileEEPROM.eraseEEPROM(addr);
    else if (state == READ)
      call ThermopileEEPROM.readEEPROM(addr);
    return SUCCESS;
  }

  event result_t ThermopileEEPROM.eraseEEPROMDone() {
    call ThermopileEEPROM.writeEEPROM(addr+counter, wrdata[counter]);
    return SUCCESS;
  }

  event result_t ADCControl.stopDone() {
    return SUCCESS;
  }

  event result_t ADCControl.initDone() {
    return SUCCESS;
  }

  event TOS_MsgPtr ReadMsg.receive(TOS_MsgPtr m) {
    Thermopile_Read_Msg* reader = (Thermopile_Read_Msg*)m->data;
    call Leds.redOn();
    if (state == IDLE) {
      state = READ;
      addr = reader->address;
      call ADCControl.start();
    }
    return m;
  }

  event result_t ThermopileEEPROM.readEEPROMDone(uint16_t value) {
    ackbuffer->address = addr;
    ackbuffer->length = 1;
    ackbuffer->data[0] = value;
    call LowerControl.stop();
    call ADCControl.stop();
    call Send.send(TOS_BCAST_ADDR, sizeof(Thermopile_Ack_Msg), ackmsg);
    state = IDLE;
    return SUCCESS;
  }
   
  event TOS_MsgPtr WriteMsg.receive(TOS_MsgPtr m) {
    int i = 0;
    Thermopile_Write_Msg* reader = (Thermopile_Write_Msg*)m->data;
    if (state == IDLE) {      
      call Leds.redOn();
      counter = 0;
      state = WRITE;
      addr = reader->address;
      length = reader->length;
      for (i = 0; i < length; i++)
        wrdata[i] = reader->data[i];
      call ADCControl.start();
    }
    return m;
  }

  event result_t ThermopileEEPROM.writeEEPROMDone() {
    counter++;
    if (counter < length) {
      call ThermopileEEPROM.eraseEEPROM(addr+counter, wrdata[counter]);
    }
    else {
      int i = 0;
      call LowerControl.stop();
      call ADCControl.stop();
      ackbuffer->address = addr;
      ackbuffer->length = counter;
      for (i = 0; i < counter; i++) {
        ackbuffer->data[i] = wrdata[i];
      }
      state = IDLE;
      call Send.send(TOS_BCAST_ADDR, sizeof(Thermopile_Ack_Msg), ackmsg);
    }
    return SUCCESS;
  }

  event result_t Send.sendDone(TOS_MsgPtr sent_msgptr, result_t success){ 
    call Leds.redOff();
    return SUCCESS;
  }

}
