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
// $Id: TickSensorM.nc,v 1.1 2003/01/24 20:11:42 cssharp Exp $

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

  event void Config_counter_period.updated()
  {
    call Timer.stop();
    call Timer.start( TIMER_REPEAT, G_Config.counter_period );
  }

  command result_t StdControl.init()
  {
    m_now = 0;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call Timer.start( TIMER_REPEAT, G_Config.counter_period );
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call Timer.stop();
    return SUCCESS;
  }

  event result_t Timer.fired()
  {
    m_now++;
    return SUCCESS;
  }

  command Ticks_t TickSensor.get()
  {
    return m_now;
  }
}

