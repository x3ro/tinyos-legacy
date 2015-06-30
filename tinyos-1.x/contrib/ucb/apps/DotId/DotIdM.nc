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

/* Authors:   Sam Madden, Su Ping
 *
 */

module DotIdM
{
  provides interface StdControl;
  uses {
    interface Leds;
    interface LoggerRead;
    interface LoggerWrite;
    interface StdControl as CommControl;
    interface StdControl as LoggerControl;
    interface SendMsg as SendDotIdMsg;
  }
}

implementation
{

  uint8_t line[16];
  TOS_Msg msg;			/* Message to be sent out */

  /* DotIdM_INIT:  
    
     initialize lower components.
     
  */
  command result_t StdControl.init() {
    uint16_t *sline = (uint16_t *)line;
    sline[0] = TOS_LOCAL_ADDRESS;

    call CommControl.init();
    call LoggerControl.init();
    call LoggerWrite.write(0, line);
    return 1;
  }


  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  // event handler: logger write done event
  event result_t LoggerWrite.writeDone(result_t status) {
    uint16_t *sline = (uint16_t *)line;
    call Leds.redOn();
    if (status== SUCCESS) {
      sline[0] = 0; //clear out for debugging purposes
      call LoggerRead.read(0, line);
      if (sline[0]==TOS_LOCAL_ADDRESS) {
    	//call Leds.redOn();
	return SUCCESS;
      }
    }
    return FAIL;
  }
  event result_t LoggerRead.readDone(uint8_t * data, result_t status) {
    //  if (status == SUCCESS) {  
    msg.data[0] = line[0];
    msg.data[1] = line[1];
	
    call SendDotIdMsg.send(TOS_BCAST_ADDR, 16, &msg);
    call Leds.yellowOn();
    // }
    return 1;
  }

  event result_t SendDotIdMsg.sendDone(TOS_MsgPtr pmsg, result_t status) {
    //if (status== SUCCESS)
    call Leds.greenOn(); 
    return SUCCESS;
  }

}
