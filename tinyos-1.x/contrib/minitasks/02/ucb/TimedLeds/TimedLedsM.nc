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
// $Id: TimedLedsM.nc,v 1.2 2003/06/11 07:05:09 cssharp Exp $

module TimedLedsM
{
  provides
  {
    interface TimedLeds;
    interface StdControl;
  }
  uses
  {
    interface Leds;
    interface Timer as TimerRed;
    interface Timer as TimerGreen;
    interface Timer as TimerYellow;
  }
}
implementation
{
  result_t redOn( uint16_t millis )
  {
    call TimerRed.stop();
    if( millis == 0 ) { call Leds.redOff(); return SUCCESS; }
    call Leds.redOn();
    if( (millis == ~0u) || (call TimerRed.start(TIMER_ONE_SHOT,millis) == SUCCESS) )
      return SUCCESS;
    call Leds.redOff();
    return FAIL;
  }

  event result_t TimerRed.fired()
  {
    call Leds.redOff();
    return SUCCESS;
  }

  command result_t TimedLeds.redOn( uint16_t millis )
  {
    return redOn( millis );
  }


  result_t greenOn( uint16_t millis )
  {
    call TimerGreen.stop();
    if( millis == 0 ) { call Leds.greenOff(); return SUCCESS; }
    call Leds.greenOn();
    if( (millis == ~0u) || (call TimerGreen.start(TIMER_ONE_SHOT,millis) == SUCCESS) )
      return SUCCESS;
    call Leds.greenOff();
    return FAIL;
  }

  event result_t TimerGreen.fired()
  {
    call Leds.greenOff();
    return SUCCESS;
  }

  command result_t TimedLeds.greenOn( uint16_t millis )
  {
    return greenOn( millis );
  }


  result_t yellowOn( uint16_t millis )
  {
    call TimerYellow.stop();
    if( millis == 0 ) { call Leds.yellowOff(); return SUCCESS; }
    call Leds.yellowOn();
    if( (millis == ~0u) || (call TimerYellow.start(TIMER_ONE_SHOT,millis) == SUCCESS) )
      return SUCCESS;
    call Leds.yellowOff();
    return FAIL;
  }

  event result_t TimerYellow.fired()
  {
    call Leds.yellowOff();
    return SUCCESS;
  }

  command result_t TimedLeds.yellowOn( uint16_t millis )
  {
    return yellowOn( millis );
  }


  result_t intOn( uint8_t n, uint16_t millis )
  {
    return redOn( (n&1) ? millis : 0 )
        && greenOn( (n&2) ? millis : 0 )
	&& yellowOn( (n&4) ? millis : 0 );
  }

  command result_t TimedLeds.intOn( uint8_t n, uint16_t millis )
  {
    return intOn( n, millis );
  }


  command result_t StdControl.init()
  {
    return call Leds.init();
  }

  command result_t StdControl.start()
  {
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return intOn(0,0);
  }
}

