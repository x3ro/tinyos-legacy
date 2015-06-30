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

includes nido;

module ChannelStateM {
  provides {
      interface StdControl;
      interface ChannelState;
  }
  uses interface StdControl as RadioStdControl;
}

implementation {

  command result_t StdControl.init() {
      return call RadioStdControl.init();
  }

  command result_t StdControl.start() {
      return call RadioStdControl.start();
  }

  command result_t StdControl.stop() {
      return call RadioStdControl.stop();
  }

  command result_t ChannelState.setChannel(uint8_t newChannel) {
    if (tos_state.node_state[TOS_LOCAL_ADDRESS].channel != newChannel) {
        doChannelSwitch(TOS_LOCAL_ADDRESS, newChannel);
        dbg(DBG_USR1, "CHANNEL: changed to Channel %d at %lld\n", newChannel, tos_state.tos_time);
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
