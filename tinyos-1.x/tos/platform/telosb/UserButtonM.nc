//$Id: UserButtonM.nc,v 1.1 2005/05/05 02:05:00 cssharp Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * Andew's timer debouce logic used from the CountInput application.
 *
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 * @author Andrew Redfern <aredfern@kingkong.me.berkeley.edu>
 */

module UserButtonM
{
  provides interface StdControl;
  provides interface MSP430Event as UserButton;
  uses interface MSP430Interrupt;
  uses interface MSP430GeneralIO;
  uses interface Timer;
}
implementation
{
  command result_t StdControl.init()
  {
    atomic
    {
      call MSP430Interrupt.disable();
      call MSP430GeneralIO.makeInput();
      call MSP430GeneralIO.selectIOFunc();
      call MSP430Interrupt.edge(TRUE);
      call MSP430Interrupt.clear();
      call MSP430Interrupt.enable();
    }
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    atomic
    {
      call MSP430Interrupt.clear();
      call MSP430Interrupt.enable();
    }
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    atomic
    {
      call MSP430Interrupt.disable();
    }
    return SUCCESS;
  }

  event result_t Timer.fired()
  {
    atomic
    {
      call MSP430Interrupt.clear();
      call MSP430Interrupt.enable();
    }
    return SUCCESS;
  }

  task void debounce()
  {
    call Timer.start( TIMER_ONE_SHOT, 100 );
  }

  async event void MSP430Interrupt.fired()
  {
    atomic
    {
      signal UserButton.fired();
      // debounce
      call MSP430Interrupt.disable();
      post debounce();
    }
  }
}

