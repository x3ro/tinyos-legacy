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
 * Author: Matt Welsh, David Culler
 * Last updated: 24 Dec 2002
 * 
 */

includes Surge;
includes bcast;

/*
 *  Data gather application
 */

module SurgeM {
  provides {
    interface StdControl;
  }
  uses {
    interface ADC;
    interface Timer;
    interface Leds;
    interface StdControl as Sounder;
    interface IntOutput;
    interface Bcast; 
  }
}

implementation {

  enum {
    TIMER_GETADC_COUNT = 1,            // Timer ticks for ADC 
    TIMER_CHIRP_COUNT = 10,            // Timer on/off chirp count
  };

  bool sleeping;			// application command state
  bool focused;
  bool rebroadcast_adc_packet;

  uint16_t sensor_reading;              // data collection
  bool send_busy;

  int timer_rate;
  int timer_ticks;
  /***********************************************************************
   * Initialization 
   ***********************************************************************/
      
  static void initialize() {
    timer_rate = INITIAL_TIMER_RATE;
    send_busy = FALSE;
    sleeping = TRUE;
    rebroadcast_adc_packet = FALSE;
    focused = FALSE;
  }

  command result_t StdControl.init() {
    initialize();
    // DEBUG STUFF
    outp(12, UBRR);
    inp(UDR); 
    // Enable reciever and transmitter
    outp((1 << TXEN) ,UCR);
    // END DEBUG STUFF

    return SUCCESS;
  }

  command result_t StdControl.start() {
    return call Timer.start(TIMER_REPEAT, timer_rate);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return call Timer.stop();
  }

  /***********************************************************************
   * Commands and events
   ***********************************************************************/

  event result_t Timer.fired() {
    dbg(DBG_USR1, "SurgeM: Timer fired\n");
    timer_ticks++;
    if (timer_ticks % TIMER_GETADC_COUNT == 0) {
      call ADC.getData();
    }
    // If we're the focused node, chirp
    if (focused && timer_ticks % TIMER_CHIRP_COUNT == 0) {
      call Sounder.start();
    }
    // If we're the focused node, chirp
    if (focused && timer_ticks % TIMER_CHIRP_COUNT == 1) {
      call Sounder.stop();
    }
    return SUCCESS;
  }

  event result_t ADC.dataReady(uint16_t data) {
    dbg(DBG_USR1, "SurgeM: Got ADC reading: 0x%x\n", data);
    if (!send_busy) {
      dbg(DBG_USR1, "SurgeM: Sending sensor reading\n");
      send_busy = TRUE;	
      if (call IntOutput.output(data)!= SUCCESS) send_busy = FALSE;
    }
    return SUCCESS;
  }

  event result_t IntOutput.outputComplete(bool success) {
    dbg(DBG_USR2, "SurgeM: output complete 0x%x\n", success);
    call Leds.greenToggle();
    send_busy = FALSE;
    return SUCCESS;
  }


  /* Command interpreter for broadcasts
   *
   */

  event result_t Bcast.cmd(bcastMsg *bcast_msg) {
    Surgedbg(DBG_USR2, "SurgeM: bcast.cmd, source 0x%02x, origin 0x%02x, type 0x%02x, seq 0x%02x\n", 
	     bcast_msg->sourceaddr, bcast_msg->originaddr, bcast_msg->type, bcast_msg->seqno);
    if (bcast_msg->type == SURGE_TYPE_SETRATE) {       // Set timer rate
      timer_rate = bcast_msg->args.newrate;
      Surgedbg(DBG_USR2, "SurgeM: set rate %d\n", timer_rate);
      call Timer.stop();
      call Timer.start(TIMER_REPEAT, timer_rate);

    } else if (bcast_msg->type == SURGE_TYPE_SLEEP) {
      // Go to sleep - ignore everything until a SURGE_TYPE_WAKEUP
      Surgedbg(DBG_USR2, "SurgeM: sleep\n");
      sleeping = TRUE;
      call Timer.stop();
      call Leds.greenOff();
      call Leds.yellowOff();
      call Leds.redOff();

    } else if (bcast_msg->type == SURGE_TYPE_WAKEUP) {
      Surgedbg(DBG_USR2, "SurgeM: wakeup\n");

      // Wake up from sleep state
      if (sleeping) {
	initialize();
        call Timer.start(TIMER_REPEAT, timer_rate);
	sleeping = FALSE;
      }

    } else if (bcast_msg->type == SURGE_TYPE_FOCUS) {
      Surgedbg(DBG_USR2, "SurgeM: focus %d\n", bcast_msg->args.focusaddr);
      // Cause just one node to chirp and increase its sample rate;
      // all other nodes stop sending samples (for demo)
      if (bcast_msg->args.focusaddr == TOS_LOCAL_ADDRESS) {
	// OK, we're focusing on me
	focused = TRUE;
	call Sounder.init();
	call Timer.stop();
	call Timer.start(TIMER_REPEAT, FOCUS_TIMER_RATE);
      } else {
	// Focusing on someone else
	call Timer.stop();
	call Timer.start(TIMER_REPEAT, FOCUS_NOTME_TIMER_RATE);
      }

    } else if (bcast_msg->type == SURGE_TYPE_UNFOCUS) {
      // Return to normal after focus command
      Surgedbg(DBG_USR2, "SurgeM: unfocus\n");
      focused = FALSE;
      call Sounder.stop();
      call Timer.stop();
      call Timer.start(TIMER_REPEAT, timer_rate);
    }
    return SUCCESS;
  }

}


