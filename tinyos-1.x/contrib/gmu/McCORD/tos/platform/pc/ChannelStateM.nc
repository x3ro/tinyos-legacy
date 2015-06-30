/**
 * Copyright (c) 2008 - George Mason University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL GEORGE MASON UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF GEORGE MASON
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *      
 * GEORGE MASON UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND GEORGE MASON UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 **/

/**
 * @author Leijun Huang <lhuang2@gmu.edu>
 **/

/**
 * Implementation of the channel state functions.
 * 
 * Author: Leijun Huang
 */

includes nido;

module ChannelStateM {
  provides {
      interface StdControl;
      interface ChannelState;
  }
  uses {
      interface StdControl as RadioStdControl;
      interface SystemTime;
  }
}

implementation {

  enum {
      DEFAULT_CHANNEL = 0,
  };

  bool _radioOn;

  command result_t StdControl.init() {
      _radioOn = FALSE;
      return call RadioStdControl.init();
  }

  command result_t StdControl.start() {
      call RadioStdControl.start();
      doChannelSwitch(TOS_LOCAL_ADDRESS, DEFAULT_CHANNEL);
      dbg(DBG_USR1, "CHANNEL: listen to default channel %d at %u ms\n", 
          DEFAULT_CHANNEL, call SystemTime.getCurrentTimeMillis());
      _radioOn = TRUE;
      return SUCCESS;
  }

  command result_t StdControl.stop() {
      call RadioStdControl.stop();
      if (_radioOn == TRUE) {
          _radioOn = FALSE;
          dbg(DBG_USR1, "RADIO OFF at %u ms\n", 
              call SystemTime.getCurrentTimeMillis());
      }
      return SUCCESS;
  }

  command bool ChannelState.isRadioOn() {
      return _radioOn;
  }

  command result_t ChannelState.turnOnRadio(uint8_t channel) {
    bool changed = FALSE;
    if (tos_state.node_state[TOS_LOCAL_ADDRESS].channel != channel) {
        doChannelSwitch(TOS_LOCAL_ADDRESS, channel);
        changed = TRUE;
    }
    if (_radioOn == FALSE) {
//        call RadioStdControl.start();
        _radioOn = TRUE;
        changed = TRUE;
    }
    if (changed) {
        // Either channel is changed or on/off state is changed.
        dbg(DBG_USR1, "RADIO ON at %u ms Channel %d\n", 
            call SystemTime.getCurrentTimeMillis(), channel);
    }
    return SUCCESS;
  }

  command result_t ChannelState.turnOffRadio() {
    if (_radioOn == TRUE) {
//        call RadioStdControl.stop();
        _radioOn = FALSE;
        dbg(DBG_USR1, "RADIO OFF at %u ms\n", call SystemTime.getCurrentTimeMillis());
    }
    return SUCCESS;
  }
  
  command uint8_t ChannelState.getChannel() {
    return tos_state.node_state[TOS_LOCAL_ADDRESS].channel;
  }

  command result_t ChannelState.setRFPower(uint8_t newRFPower) {
    return SUCCESS;
  }

  command uint8_t ChannelState.getRFPower() {
    return 0;
  }

}
