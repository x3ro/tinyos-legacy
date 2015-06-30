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
 * Interface for the channel state functions.
 *
 */
 
interface ChannelState {

  /**
   * Turns radio on and tunes to the given channel.
   * @param channel ID of the channel.
   * @return SUCCESS if succeeded, FAIL otherwise.
   */
  command result_t turnOnRadio(uint8_t channel);

  /**
   * Turns radio off.
   */
  command result_t turnOffRadio();

  command bool isRadioOn();
  
  /**
   * Gets the current channel. Valid only if the radio is on.
   * @return ID of the current channel.
   */
  command uint8_t getChannel();

  /**
   * Sets the radio transmission power.
   * @param newRFPower the new radio transmission power. 
   *                   Valid values are platform dependent.
   * @return SUCCESS if succeeded, FAIL otherwise.
   */
  command result_t setRFPower(uint8_t newRFPower);

  /**
   * Gets the current radio transmission power.
   * @return the current radio transmission power.
   */
  command uint8_t getRFPower();
}
