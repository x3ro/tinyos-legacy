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
 * Counts the number of times that the user input button is pressed and 
 * displays the count to the leds. Uses the time to debounce the button
 **/

/**
 * @author Andrew Redfern <aredfern@kingkong.me.berkeley.edu
 * Modified by Joe Polastre to match the Count* applications in contrib/ucb
 **/


includes CountMsg;
includes Timer;

module CountInputM
{
  provides interface StdControl;
  uses interface Leds;
  uses interface Timer as DebounceTimer;
  uses interface MSP430Interrupt as UserInput;
}
implementation
{
  TOS_Msg m_msg;
  int m_int;
  bool m_sending;
  bool m_taskposted;

  task void startDebounceTimer(){
    atomic m_taskposted = FALSE;
    call DebounceTimer.start(TIMER_ONE_SHOT, 100);
  }

  command result_t StdControl.init()
  {
    m_int = 0;
    m_sending = FALSE;
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    m_taskposted = FALSE;
    call UserInput.disable();
    call UserInput.clear();
    call UserInput.edge(TRUE);
    call UserInput.enable();
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call DebounceTimer.stop();
    return SUCCESS;
  }

  async event void UserInput.fired(){
    call UserInput.disable();
    call Leds.set(++m_int);
    call UserInput.clear();
    if (!m_taskposted)
      if (post startDebounceTimer() == SUCCESS)
	m_taskposted = TRUE;
  }

  event result_t DebounceTimer.fired(){
    call UserInput.enable();
    return SUCCESS;
  }

}
