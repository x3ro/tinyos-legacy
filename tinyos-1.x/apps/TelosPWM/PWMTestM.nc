// $Id: PWMTestM.nc,v 1.5 2005/05/10 05:16:48 johnyb_4 Exp $

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

// @author Cory Sharp <cssharp@eecs.berkeley.edu>

// revised by John Breneman - 5/9/05 <johnyb_4@berkeley.edu>


module PWMTestM
{
  provides interface StdControl;
  uses interface TelosPWM;
  uses interface Timer;
  uses interface Leds;
}
implementation
{
  static const uint16_t m_pwm[] = { 1024, 1280, 1536, 1792, 2048, 1792, 1536, 1280 };
  enum { NUM_PWM = sizeof(m_pwm)/sizeof(uint16_t) };

  int m_index0;
  int m_index1;
  int m_index2;

  command result_t StdControl.init()
  {
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    m_index0 = 0;
    m_index1 = 0;
    m_index2 = 0;
    call TelosPWM.setHigh0( 1024 );
    call TelosPWM.setHigh1( 1280 );
    call TelosPWM.setHigh2( 1536 );
    call TelosPWM.setHigh3( 1792 );
    call Timer.start( TIMER_REPEAT, 1000 );
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }

  event result_t Timer.fired()
  {
    call Leds.redToggle();
    return SUCCESS;
  }
}

