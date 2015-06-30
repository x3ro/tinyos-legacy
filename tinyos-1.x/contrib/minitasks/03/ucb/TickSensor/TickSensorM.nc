/* "Copyright (c) 2000-2002 The Regents of the University of California.  
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
 */

// Authors: Cory Sharp
// $Id: TickSensorM.nc,v 1.2 2003/07/08 18:53:34 cssharp Exp $

// Description: Tick counter implementation, for some definition of
// implementation.

//!! Config 1 { uint16_t counter_period = 64; }

includes TickSensor;

module TickSensorM
{
  provides
  {
    interface TickSensor;
    interface StdControl;
  }
  uses
  {
    interface Timer;
    interface Config_counter_period;
  }
}
implementation
{
  Ticks_t m_now;
  Ticks_t m_inc;

  void start_timer()
  {
    call Timer.stop();
    m_inc = 32768L / G_Config.counter_period;  //relative to jiffies (+1 to help rounding)
    call Timer.start( TIMER_REPEAT, G_Config.counter_period );
  }

  event void Config_counter_period.updated()
  {
    start_timer();
  }

  command result_t StdControl.init()
  {
    m_now = 0;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    start_timer();
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call Timer.stop();
    return SUCCESS;
  }

  event result_t Timer.fired()
  {
    m_now += m_inc;
    return SUCCESS;
  }

  command Ticks_t TickSensor.get()
  {
    return m_now;
  }
}

