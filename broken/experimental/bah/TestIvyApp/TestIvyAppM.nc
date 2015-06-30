/*									tab:4
 *
 *
 * "Copyright (c) 2002-2004 The Regents of the University  of California.  
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
/** 
 *
 *	Ivy Test Application
 *
 *	This demonstrates how to write an Ivy applicaition using 
 * 	the Ivy MultihopApp component. Every SYNCH_FREQ it 
 *	receives an ActiveNotify event indicating the radio 
 *      is on and the application can send a message. 
 * 
 *	If sampling sensor data, the idea is to send 
 *	the ith - 1 sample when the ActiveNotify event is
 *	received and then take the next sample.
 *
 *	Note: Radio Power Management is handled by the MultiHopApp 
 *	component. The application only sends a message when it 
 *	is activated by the MultiHopApp component.
 *
 *	It is the applications's responsibility to power down
 *	it's sensors.
 *
 * Author:	Barbara Hohlt
 * Project:	Ivy
 *
 **/
module TestIvyAppM {

  provides interface StdControl as Control;
  uses {
	interface Send; 
	interface StdControl as SubControl;
	interface ActiveNotify;
	//interface StdControl as ADCControl;
	//interface ADC;
  }
}
implementation
{
  TOS_Msg msg1;
  bool doWork;

  command result_t Control.init() {

    //call ADCControl.init();
    return call SubControl.init();
  }
 
  command result_t Control.start() {
    doWork = FALSE;
    call SubControl.start();
    return SUCCESS; 
  } 

  command result_t Control.stop() {
    doWork = FALSE;
    call SubControl.stop();
    return SUCCESS;
  } 

  task void doProcessing() {

    uint16_t dlen;
    uint8_t *dataPtr;
    uint16_t i;

    dbg(DBG_ROUTE,"TestIvyApp:doProcessing().\n");

    if (!doWork)
	return;

    dataPtr = call Send.getBuffer(&msg1,&dlen);

    for(i=0;i<dlen;i++)
    {
	/* fill data buffer with data ! */
    }

    call Send.send(&msg1,dlen);


    return;
  }


  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {

    // get ith data sample
    // call ADC.getData();
    
    return SUCCESS;
  }

 /* radio on every SYNCH_FREQ */
 event void ActiveNotify.activated() {
    doWork = TRUE;

    //call ADCControl.start();

    // send ith - 1 sample
    post doProcessing();
    return;
  }

  /* radio off after mesage is sent */
  event void ActiveNotify.deactivated() {
    doWork = FALSE;
    return;
  }

}

