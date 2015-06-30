// $Id: BlinkTaskM.nc,v 1.1 2004/01/26 19:14:32 vlahan Exp $

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

/* Authors:  Su Ping  <sping@intel-research.net>
 *           Intel Research Berkeley Lab
 *
 */

/**
 * Implementation for Blink application.  Toggle the red LED when the
 * timer fires, using tasks.
 * @author Su Ping <sping@intel-research.net>
 * @author Intel Research Berkeley Lab
 **/
module BlinkTaskM {
  provides {
    interface StdControl;
  }
  uses {
    interface Timer;
    interface Leds;
  }
}
implementation {
  /** 
   * the state of the red LED (on or off)
   */
  bool state;

  /**
   * Initialize the component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.init() {
    state = FALSE;
    call Leds.init();
    return SUCCESS;
  }

  /**
   * Start things up.  This sets the rate for the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.start() {
    return call Timer.start(TIMER_REPEAT, 1000);
  }

  /**
   * Start things up.  This just sets the rate for the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.stop() {
    return call Timer.stop();
  }

/**
 * Module task: processing
 *
 * Toggles  the red LED only.  
 * The task is triggered by the <code>Timer.fired</code> event.
 *
 * @return None
 **/
task void processing()
{
   if (state)
       call Leds.redOn();
   else 
       call Leds.redOff();
}

  /**
   * Toggle the red LED in response to the <code>Timer.fired</code> event
   * using the <code>processing</code> task.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t Timer.fired()
  {
    state = !state;
    post processing();
    return SUCCESS;
  }
}

