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

module ChannelStateM {
  provides {
    interface StdControl;
    interface ChannelState;
  }
  uses {
    interface CC2420Control as RadioControl;
    interface StdControl as RadioStdControl;
  }
}

#define NO_PHYSICAL_OFF

implementation {

  enum {

    // For CC2420, valid values for preset channels are 11, 12, ..., 26
    MC_MAX_CHANNELS = 16,
    // virtual channel + MC_CHANNEL_OFFSET = actual preset channel
    // Suppose virtual channel 0 is reserved for common use.
    MC_CHANNEL_OFFSET = 11,
  };

  uint8_t _currentChannel;
  bool    _radioOn;

  command result_t StdControl.init() {
    _radioOn = FALSE;
    call RadioStdControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    _currentChannel = 0;  // default channel.
    call RadioStdControl.start(); 
    call RadioControl.TunePreset(_currentChannel + MC_CHANNEL_OFFSET);
    _radioOn = TRUE;
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call RadioStdControl.stop();
    _radioOn = FALSE;
    return SUCCESS;
  }

  command result_t ChannelState.turnOnRadio(uint8_t channel) {
    if (channel >= MC_MAX_CHANNELS) return FAIL;

    if (_radioOn == FALSE) {
#ifndef NO_PHYSICAL_OFF
        call RadioStdControl.start();
#endif
        _radioOn = TRUE;
    }

    if (channel != _currentChannel) {
        call RadioControl.TunePreset(channel + MC_CHANNEL_OFFSET);
        _currentChannel = channel;
    }
    return SUCCESS;
  }

  command result_t ChannelState.turnOffRadio() {
    if (_radioOn == TRUE) {
#ifndef NO_PHYSICAL_OFF
        call RadioStdControl.stop();
#endif
        _radioOn = FALSE;
    }
    return SUCCESS;
  }
  
  command bool ChannelState.isRadioOn() {
    return _radioOn;
  }

  command uint8_t ChannelState.getChannel() {
    return _currentChannel;
  }

  // Set the radio power.
  // For CC2420, valid values are 3 through 31 with power of 3 
  // equal to -25dBm and 31 equal to max power (0dBm).
  // By default, Telosb initializes the radio tx power to 31. 
  command result_t ChannelState.setRFPower(uint8_t newRFPower) {
    if (newRFPower != call RadioControl.GetRFPower()) {
        call RadioControl.SetRFPower(newRFPower);
    }
    return SUCCESS;
  }

  command uint8_t ChannelState.getRFPower() {
    return call RadioControl.GetRFPower();
  }

}
