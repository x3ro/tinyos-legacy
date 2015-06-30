// $Id: TestUartRadioM.nc,v 1.3 2003/10/07 21:45:25 idgay Exp $

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
module TestUartRadioM {
  provides {
    interface StdControl;
  }
  uses {
    interface Debugger;
    interface Timer;
    interface Leds;
    interface ReceiveMsg;
    interface ReceiveMsg as ReceiveBLMsg;
  }
}
implementation {
  char buf[20];
  int idx;
  char state;
  TOS_Msg buffer;
  
#define INIT_STR "\xFE\x1\xFE\xF0        TinyOS 1.x"

  enum { READY, OFF, BUSY };

  command result_t StdControl.init() {
    state = OFF;
    idx = 0;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    TOSH_MAKE_PW0_OUTPUT();
    // we have to wait for the LCD to initialize
    call Timer.start(TIMER_ONE_SHOT, 800);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    state = OFF;
    call Timer.stop();
    return SUCCESS;
  }

  event result_t Timer.fired() {
    state = BUSY;
    call Debugger.writeString(INIT_STR, strlen(INIT_STR));
    return SUCCESS;
  }
  
  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr data) {
    call Leds.yellowToggle();
    if (state == READY) {
        state = BUSY;
	call Debugger.writeLine(data->data,data->length);
    }
    return data;
  }  

  event TOS_MsgPtr ReceiveBLMsg.receive(TOS_MsgPtr data) {
    if (data->data[0] == 0) {
      TOSH_CLR_PW0_PIN();
      call Leds.greenOff();
    }
    else {
      TOSH_SET_PW0_PIN();
      call Leds.greenOn();
    }
    return data;
  }

  event result_t Debugger.writeDone(char *string, result_t success) {
/*    char idxStr[10];
    idx++;
    itoa(idx, idxStr, 10);
    strcpy(buf, "Test # " );
    strcat(buf, idxStr);

    return call Debugger.writeLine(buf, strlen(buf));
*/
    state = READY;
    return SUCCESS;
  }
}


