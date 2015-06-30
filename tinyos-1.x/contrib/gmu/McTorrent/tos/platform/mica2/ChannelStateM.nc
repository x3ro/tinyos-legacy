/**
 * Copyright (c) 2006 - George Mason University
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
    interface CC1000Control as RadioControl;
    interface StdControl as RadioStdControl;
  }
}

implementation {

  enum {
    // Suppose channel 0 is reserved for common use.
    MC_MAX_CHANNELS = 32,

    RADIO_FREQ_BASE = 902000000, // max freq is 928MHz
    RADIO_FREQ_INC  =    800000,  
  };

  uint8_t _currentChannel;

  command result_t StdControl.init() {
    call RadioStdControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    _currentChannel = 0;
    call RadioStdControl.stop();
    call RadioControl.TuneManual(RADIO_FREQ_BASE);
    call RadioStdControl.start(); 
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call RadioStdControl.stop();
    return SUCCESS;
  }

  command result_t ChannelState.setChannel(uint8_t newChannel) {
    if (newChannel >= MC_MAX_CHANNELS) return FAIL;

    if (newChannel != _currentChannel) {
      call RadioStdControl.stop();
      call RadioControl.TuneManual(RADIO_FREQ_BASE + newChannel * RADIO_FREQ_INC);
      call RadioStdControl.start();    
      _currentChannel = newChannel;
    }
    return SUCCESS;
  }
  
  command uint8_t ChannelState.getChannel() {
    return _currentChannel;
  }

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
