/*									tab:2
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * Authors:	Phil Levis
 *              Nelson Lee
 *    Date:     July 24 2001
 *              June 6 2002
 *              July 2 2002 (ported to Nesc)
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
 *   FILE: NarproTestM.td
 * AUTHOR: Phil Levis, Nelson Lee
 *  DESCR: Beaconless routing protocol test program
 */
/**
 * This program is a simple test of the Narpro protocol, to show how it
 * can be used. Every 5 seconds, narproTestClock is called, which
 * causes a message filled with 0xdeadbeef to be sent out.
 **/

module NarproTestM {
  provides interface StdControl;
  
  uses {
    interface Clock;
    interface Leds;
    interface SendData as SendDataNarpro;
    interface StdControl as StdControlNarpro;
    command result_t active();
  }
}

implementation {

  /**
   * Initialize the component by setting the clock rate and
   * calling <code>StdControlNarpro.init</code>
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.init() {   
    call StdControlNarpro.init();
    call Clock.setRate(32, 0x07);
    return SUCCESS;
  }

  /**
   * Start things up; does nothing really
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.start() {
    return SUCCESS;
  }

  /**
   * Stop things; does nothing really
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  /**
   * Toggle the red LED in response to the <code>SendDataNarpro.sendDone</code> event.  
   *
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t SendDataNarpro.sendDone(uint8_t* data, result_t success) {
    call Leds.redToggle();
    return success;
  }

  /**
   * Send out a packet filled with 0xdeadbeef over Narpro in response to the <code>Clock.fire</code> event.  
   *
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t Clock.fire() {
    char data[26] = {0xde, 0xad, 0xbe, 0xef,
		     0xde, 0xad, 0xbe, 0xef,
		     0xde, 0xad, 0xbe, 0xef,
		     0xde, 0xad, 0xbe, 0xef,
		     0xde, 0xad, 0xbe, 0xef, 
		     0xde, 0xad, 0xbe, 0xef,
		     0xaa, 0xff};
    
    dbg(DBG_USR1, "NARPRO clock ticked!\n");
    call SendDataNarpro.send(data, (uint8_t) 26);
    //call Leds.redToggle();

    //if (call active()) {
    //call Leds.yellowOn();
    //}
    //else {
    //call Leds.yellowOff();
    //}
    return SUCCESS;
  }
}

