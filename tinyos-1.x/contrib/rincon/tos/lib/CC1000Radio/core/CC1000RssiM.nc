/*
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 *   RSSI fun. It's used for lots of things, and a request to read it
 *   for one purpose may have to be discarded if conditions change. For
 *   example, if we've initiated a noise-floor measure, but start 
 *   receiving a packet, we have to:
 *   - cancel the noise-floor measure (we don't know if the value will
 *     reflect the received packet or the previous idle state)
 *   - start an RSSI measurement so that we can report signal strength
 *     to the application
 *
 *   This module hides the complexities of cancellation from the rest of
 *   the stack.
 * 
 * @author 
 * @author David Moss
 */

module CC1000RssiM {
  provides {
    interface StdControl;
    interface Rssi[uint8_t id];
  }
  
  uses { 
    interface ADCControl;
    interface ADC;
  }
}

implementation {

  /** The client that made the current request */
  uint8_t currentClient;

  /** The next client in line for a request */
  uint8_t nextClient;
  
  enum {
    EMPTY = unique("Rssi"),
  };

  /***************** Prototypes ****************/
  task void startNextClient();
  
  /***************** StdControl Commands ****************/
  command result_t StdControl.init() {
    call ADCControl.bindPort(TOS_ADC_CC_RSSI_PORT, TOSH_ACTUAL_CC_RSSI_PORT);
    call ADCControl.init();

    atomic currentClient = EMPTY;
    atomic nextClient = EMPTY;
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  

  /***************** RSSI Commands ****************/
  /**
   * Read the RSSI value
   */
  async command result_t Rssi.read[uint8_t id]() {
    atomic {
      nextClient = id;
      post startNextClient();
    }
    return SUCCESS;
  }

  /**
   * Cancel all current RSSI requests
   */
  async command void Rssi.cancel[uint8_t id]() {
    currentClient = EMPTY;
    nextClient = EMPTY;
  }

  /***************** ADC Events ****************/
  async event result_t ADC.dataReady(uint16_t data) {
    atomic {
      if(currentClient != EMPTY) {
        signal Rssi.readDone[currentClient](SUCCESS, data);
      }
      
      currentClient = EMPTY;
      
      post startNextClient();
    }
    return SUCCESS; 
  }

  /***************** Tasks ****************/
  task void startNextClient() {
    atomic {
      if (nextClient != EMPTY) {
        currentClient = nextClient;
        nextClient = EMPTY;
        call ADC.getData();
      }
    }
  }

  /**************** Defaults ****************/
  default async event void Rssi.readDone[uint8_t id](result_t result, uint16_t data) { 
  }
}
