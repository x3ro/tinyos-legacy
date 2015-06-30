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
// $Id: AppCountM.nc,v 1.9 2002/12/21 02:04:50 cssharp Exp $

module AppCountM
{
  provides
  {
    interface StdControl;
  }
  uses
  {
    interface Leds;
    interface RoutingReceive;
  }
}
implementation
{
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
    return SUCCESS;
  }

  uint8_t leds_set_u8( uint8_t n )
  {
    if(n&1) call Leds.redOn(); else call Leds.redOff();
    if(n&2) call Leds.greenOn(); else call Leds.greenOff();
    if(n&4) call Leds.yellowOn(); else call Leds.yellowOff();
    return n;
  }

  event TOS_MsgPtr RoutingReceive.receive( TOS_MsgPtr msg )
  {
    int8_t* head = popFromRoutingMsg( msg, 1 );
    if( head == 0 ) return msg;
    leds_set_u8( *(uint8_t*)head );
    return msg;
  }
}

