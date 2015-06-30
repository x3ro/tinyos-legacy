// $Id: HPLCC2420InterruptM.nc,v 1.1 2004/09/19 23:55:58 jpolastre Exp $

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
/*
 *
 * Authors: Matt Miller
 * Date last modified:  $Revision: 1.1 $
 *
 */

/**
 * @author Matt Miller, Crossbow
 */

module HPLCC2420InterruptM {
  provides {
    interface HPLCC2420Interrupt as FIFOP;
    interface HPLCC2420Interrupt as FIFO;
    interface HPLCC2420Interrupt as CCA;
    interface HPLCC2420Capture as SFD;
  }
  uses {
    interface TimerCapture as SFDCapture;
    interface Timer as FIFOTimer;
    interface Timer as CCATimer;
  }
}
implementation
{
    norace uint8_t FIFOWaitForState;
	norace uint8_t FIFOLastState;

    norace uint8_t CCAWaitForState;
	norace uint8_t CCALastState;
  // Add stdcontrol.init/.start to setup TimerCapture timebase

  // ************* FIFOP Interrupt handlers and dispatch *************
  
  /*********************************************************
  * 
  *  enable CC2420 fifop interrupt (on INT6 pin of ATMega128)
  CC2420 is configured for FIFOP interrupt on RXFIFO > Thresh
  where thresh is programmed in CC2420Const.h CP_IOCFGO reg. 
  Threshold is 127 asof 15apr04 (AlmostFull)
  FIFOP is asserted as long as RXFIFO>Threshold
  FIFOP is active LOW
  Type	ISCn1 ISCn0
  Hi-Lo	1	0
  Lo-Hi	1	1
  ********************************************************/
	async command result_t FIFOP.startWait(bool low_to_high) {
	    atomic {
	        CC2420_FIFOP_INT_MODE(low_to_high);
	        CC2420_FIFOP_INT_ENABLE();
	    }//atomic
	return SUCCESS;
	}

	/**
	* disables FIFOP interrupts
	*/
	async command result_t FIFOP.disable() {
		CC2420_FIFOP_INT_DISABLE();
	return SUCCESS;
	}

  /**
   * Event fired by lower level interrupt dispatch for FIFOP
   */
  TOSH_SIGNAL(TOSH_CC_FIFOP_INT) {
    result_t val = SUCCESS;
    val = signal FIFOP.fired();
    if (val == FAIL) {
        CC2420_FIFOP_INT_DISABLE();
        CC2420_FIFOP_INT_CLEAR();
    }
  } //FIFOP interrupt

  default async event result_t FIFOP.fired() { return FAIL; }
  
  // ************* FIFO Interrupt handlers and dispatch *************
  
  /**
   * enable an edge interrupt on the FIFO pin
    not INTERRUPT enabled on MICAz
    Best we can do is poll periodically and monitor line level changes
   */
  async command result_t FIFO.startWait(bool low_to_high) {

     atomic FIFOWaitForState = low_to_high; //save the state we are waiting for
	 FIFOLastState = TOSH_READ_CC_FIFO_PIN(); //get current state
     return call FIFOTimer.start(TIMER_ONE_SHOT,1); //wait 1msec
   } //.startWait

  /**
   * TImer Event fired so now check  FIFO pin level
   */
  event result_t FIFOTimer.fired() {
    uint8_t FIFOState;
    result_t val = SUCCESS;
    //check FIFO state
	 FIFOState = TOSH_READ_CC_FIFO_PIN(); //get current state
    if ((FIFOLastState != FIFOWaitForState) && (FIFOState==FIFOWaitForState)) {
		//here if found an edge
        val = signal FIFO.fired();
        if (val == FAIL) 
            return SUCCESS;  //all done
        }//if FIFO Pin
    //restart timer and try again
	FIFOLastState = FIFOState;
   return call FIFOTimer.start(TIMER_ONE_SHOT,1); //wait 1msec
  }//FIFOTimer.fired


  /**
   * disables FIFO interrupts
   */
  async command result_t FIFO.disable() {
    call FIFOTimer.stop();
    return SUCCESS;
  }

  default async event result_t FIFO.fired() { return FAIL; }

  // ************* CCA Interrupt handlers and dispatch *************
  
  /**
   * enable an edge interrupt on the CCA pin
   NOT an interrupt in MICAz. Implement as a timer polled pin monitor
   */
  async command result_t CCA.startWait(bool low_to_high) {
     atomic CCAWaitForState = low_to_high; //save the state we are waiting for
	 CCALastState = TOSH_READ_CC_CCA_PIN(); //get current state
     return call CCATimer.start(TIMER_ONE_SHOT,1); //wait 1msec
  }

  /**
   * disables CCA interrupts
   */
  async command result_t CCA.disable() {
    call CCATimer.stop();
    return SUCCESS;
  }

  /**
   * TImer Event fired so now check for CCA	level
   */
  event result_t CCATimer.fired() {
    uint8_t CCAState;
    result_t val = SUCCESS;
    //check CCA state
	 CCAState = TOSH_READ_CC_CCA_PIN(); //get current state
	//here if waiting for an edge
    if ((CCALastState != CCAWaitForState) && (CCAState==CCAWaitForState)) {
        val = signal CCA.fired();
        if (val == FAIL) 
            return SUCCESS;  //all done
        }//if CCA Pin is correct and edge found
    //restart timer and try again
	CCALastState = CCAState;
   return call CCATimer.start(TIMER_ONE_SHOT,1); //wait 1msec
  }//CCATimer.fired

  default async event result_t CCA.fired() { return FAIL; }

  // ************* SFD Interrupt handlers and dispatch *************
 /**
 SFD.enableCapture
 Configure Atmega128 TIMER1 to capture edge input of SFD signal.
 This will cause an interrupt and save TIMER1 count.
 Timer1 Timebase is set by stdControl.start - see SFDCapture Component Module
 *******************************************************************/
  async command result_t SFD.enableCapture(bool low_to_high) {
    atomic {
      //TOSH_SEL_CC_SFD_MODFUNC();
      call SFDCapture.disableEvents(); //this also clears any capture interrupt
      call SFDCapture.setEdge(low_to_high);
      call SFDCapture.clearOverflow();
      call SFDCapture.enableEvents();
    }
    return SUCCESS;
  }

  async command result_t SFD.disable() {
    call SFDCapture.disableEvents();
   // TOSH_SEL_CC_SFD_IOFUNC();
    return SUCCESS;
  }
/** .captured
Handle signal from SFDCapture interface indicating an external event has
been timestamped. 
Signal client with time and disable capture timer if nolonger needed.
*****************************************************************************/
  async event void SFDCapture.captured(uint16_t time) {
    result_t val = SUCCESS;
//    call SFDCapture.clearPendingInterrupt(); //redundant?
    val = signal SFD.captured(time);     //signal client
    if (val == FAIL) {
      call SFDCapture.disableEvents();
     // call SFDCapture.clearPendingInterrupt();  //done in .disableEvents
    }
    else {  //time capture keeps running
      if (call SFDCapture.isOverflowPending())
	    call SFDCapture.clearOverflow();
    }
  }//captured

  default async event result_t SFD.captured(uint16_t val) { return FAIL; }

} //Module HPLCC2420InterruptM
  
