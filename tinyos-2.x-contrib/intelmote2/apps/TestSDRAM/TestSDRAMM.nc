// $Id: TestSDRAMM.nc,v 1.1 2009/07/16 02:45:43 radler Exp $

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

/**
 * Implementation for Blink application.  Toggle the red LED when a
 * Timer fires.
 **/
module TestSDRAMM {
  uses {
    interface Boot;
    interface Leds;
  }
}
implementation {
  
  //allocate 1MB worth of memory
  #define SDRAMVARSIZE 262144
  uint32_t sdramVar[SDRAMVARSIZE] __attribute__((section(".sdram"))); 
  task void SDRAMTask();
  task void SDRAMCheck();
  
  event void Boot.booted() {
    post SDRAMTask();
  }
 
  task void SDRAMTask(){
    int i;
    for( i=0; i<SDRAMVARSIZE; i++){
      sdramVar[i] = i & 0xFFFF;
    }
    post SDRAMCheck();
  }
  
  task void SDRAMCheck(){
    int i;
    for( i=0; i<SDRAMVARSIZE; i++){
      if(sdramVar[i] != (i & 0xffff)){
	call Leds.led0On();
	return;
      }      
    }
    call Leds.led1On();
    }

  
}


