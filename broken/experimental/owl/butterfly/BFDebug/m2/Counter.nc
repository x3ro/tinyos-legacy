// $Id: Counter.nc,v 1.1 2003/10/30 23:22:14 idgay Exp $

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
/*
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 */

/**
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */

/* A counter modified to use the butterfly debug stuff 
   (displays current counter value, allows reset by pressing the joystick)
*/

module Counter {
  provides {
    interface StdControl;
  }
  uses {
    interface Timer;
    interface IntOutput;
    interface BFDebug;
  }
}
implementation {
  int state;

  command result_t StdControl.init()
  {
    state = 0;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    return call Timer.start(TIMER_REPEAT, 2000);
  }

  command result_t StdControl.stop()
  {
    return call Timer.stop();
  }

  event result_t Timer.fired()
  {
    state++;
    call BFDebug.displayInt(state);
    return call IntOutput.output(state);
  }

  event result_t IntOutput.outputComplete(result_t success) 
  {
    if(success == 0) state --;
    return SUCCESS;
  }

  event result_t BFDebug.joystick(uint8_t direction) {
    if (direction == 4)
      state = 0;
    return SUCCESS;
  }
}
