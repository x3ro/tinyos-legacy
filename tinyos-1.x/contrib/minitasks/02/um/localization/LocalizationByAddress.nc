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

// Authors: Kamin Whitehouse

//!! Neighbor 2 { location_t location = { pos:{x:0, y:0, z:0}, stdv:{x:0, y:0, z:0}, coordinate_system:0 }; }

includes Localization;
includes Neighbor;

module LocalizationByAddress
{
  provides
  {
    interface StdControl;
    interface Localization;
  }
  uses
  {
    interface Leds;
    interface Neighbor_location;
  }
}
implementation
{
  location_t m_my_location;

  command result_t StdControl.init()
  {
    m_my_location = G_DefaultNeighbor.location;
    m_my_location.pos.x = (TOS_LOCAL_ADDRESS >> 4) & 0x0f;
    m_my_location.pos.y = (TOS_LOCAL_ADDRESS     ) & 0x0f;
    m_my_location.coordinate_system = (TOS_LOCAL_ADDRESS >> 8) & 0xff;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call Localization.estimateLocation();
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }

  uint8_t leds_set_u8( uint8_t n )
  {
    if(n&1) call Leds.redOn(); else call Leds.redOff();
    if(n&2) call Leds.greenOn(); else call Leds.greenOff();
    if(n&4) call Leds.yellowOn(); else call Leds.yellowOff();
    return n;
  }

  event void Neighbor_location.updatedFromRemote( uint16_t address )
  {
    leds_set_u8(~(uint8_t)address);
  }

  command void Localization.estimateLocation(){
    call Neighbor_location.set(TOS_LOCAL_ADDRESS, &m_my_location);
    call Neighbor_location.requestRemoteTuples();
  } 	
}

