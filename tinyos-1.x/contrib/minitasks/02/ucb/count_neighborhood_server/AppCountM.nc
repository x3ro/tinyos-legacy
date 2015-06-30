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
// $Id: AppCountM.nc,v 1.6 2003/02/03 23:45:12 cssharp Exp $

//!! Neighbor 15 { uint8_t leds = 7; }

includes Neighbor;

module AppCountM
{
  provides
  {
    interface StdControl;
  }
  uses
  {
    interface Leds;
    interface Timer;
    interface TupleStore;
    interface Neighbor_leds;
  }
}
implementation
{
  uint8_t m_count;

  command result_t StdControl.init()
  {
    m_count = 6;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    if( call Timer.start( TIMER_REPEAT, 500 ) == FALSE )
      return FAIL;
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call Timer.stop();
    return SUCCESS;
  }

  uint8_t leds_set_u8( uint8_t n )
  {
    if(n&1) call Leds.redOn(); else call Leds.redOff();
    if(n&2) call Leds.greenOn(); else call Leds.greenOff();
    if(n&4) call Leds.yellowOn(); else call Leds.yellowOff();
    return n;
  }

  event result_t Timer.fired()
  {
//      call Leds.redToggle();
    m_count++;
    leds_set_u8(m_count);
    call Neighbor_leds.set(TOS_LOCAL_ADDRESS, &m_count);
    return SUCCESS;
  }

  event void Neighbor_leds.updatedFromRemote( uint16_t address )
  {
  }

}



