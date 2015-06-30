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

/* Authors:             Joe Polastre
 * 
 * $Id: GDI2SoftBaseM.nc,v 1.2 2003/10/07 21:45:32 idgay Exp $
 *
 */

includes GDI2SoftMsg;
includes avr_eeprom;
includes gdi_const;

/**
 * 
 */
module GDI2SoftBaseM {
  provides {
    interface StdControl;
    command result_t ForwardDone(uint8_t id);
  }
  uses {
    command result_t SetListeningMode(uint8_t power);
    command uint8_t GetListeningMode();
    command result_t SetTransmitMode(uint8_t power);
    command uint8_t GetTransmitMode();

    command void setRouteUpdateInterval(uint32_t millisec);

    interface CC1000Control;

    interface Leds;
    interface Timer as NetworkTimer;

    interface Receive as ReceiveNetwork;
  }
}
implementation {

#define MOTE_TYPE 1
#define CONST_30_SEC 30720

  /**
   * Initialize this and all low level components used in this application.
   * 
   * @return returns <code>SUCCESS</code> or <code>FAIL</code>
   */
  command result_t StdControl.init() {
    // set multihop routing to update routes every 5 minutes
    call setRouteUpdateInterval(NETWORK_UPDATE_SLOW);

    // set low power listening mode
    call SetListeningMode(ON_MODE);
    call SetTransmitMode(OFF_MODE);

    return SUCCESS;
  }

  /**
   * Start this component.
   * 
   * @return returns <code>SUCCESS</code>
   */
  command result_t StdControl.start(){
    call CC1000Control.SetRFPower(RF_POWER_LEVEL);

    return SUCCESS;
  }

  /**
   * Stop this component.
   * 
   * @return returns <code>SUCCESS</code>
   */
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t NetworkTimer.fired() {
    call Leds.redOff();
    call setRouteUpdateInterval(NETWORK_UPDATE_SLOW);
    call SetTransmitMode(OFF_MODE);
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveNetwork.receive(TOS_MsgPtr m, void* payload, uint16_t payloadLen) {
    call Leds.redOn();
    call setRouteUpdateInterval(NETWORK_UPDATE_FAST);
    call NetworkTimer.start(TIMER_ONE_SHOT, NETWORK_UPDATE_FAST_TIMEOUT);

    return m;
  }

  command result_t ForwardDone(uint8_t id) {
    if (id == AM_GDI2SOFT_NETWORK_MSG) {
      call SetTransmitMode(ON_MODE);
    }
    return SUCCESS;
  }

}

