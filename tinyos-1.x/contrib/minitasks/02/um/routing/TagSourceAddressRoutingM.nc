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
// $Id: TagSourceAddressRoutingM.nc,v 1.1 2003/06/02 12:34:18 dlkiskis Exp $

// Description: Routing component to tag the source address on the way out
// and grab it on the way back in.  Could/should be parameterized so that
// you can have two (or more), one just below and one just above your
// routing component, giving the address of the origin and last hop.

module TagSourceAddressRoutingM
{
  provides
  {
    interface Routing;
    interface RoutingGetSourceAddress;
    interface StdControl;
  }
  uses
  {
    interface Routing as BottomRouting;
  }
}
implementation
{
  typedef RoutingAddress_t header_t;

  enum {
    HEADER_LENGTH = sizeof(header_t),
  };

  RoutingAddress_t m_source_address;


  // ---
  // --- StdControl
  // ---

  command result_t StdControl.init()
  {
    m_source_address = 0;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }



  command result_t Routing.send( RoutingDestination_t dest, TOS_MsgPtr msg )
  {
    header_t* head = (header_t*)pushToRoutingMsg( msg, HEADER_LENGTH );
    if( head == 0 ) return FAIL;
    *head = TOS_LOCAL_ADDRESS;
    return call BottomRouting.send( dest, msg );
  }


  event result_t BottomRouting.sendDone( TOS_MsgPtr msg, result_t success )
  {
    popFromRoutingMsg( msg, HEADER_LENGTH );
    return signal Routing.sendDone( msg, success );
  }


  event TOS_MsgPtr BottomRouting.receive( TOS_MsgPtr msg )
  {
    header_t* head = (header_t*)popFromRoutingMsg( msg, sizeof(RoutingAddress_t) );
    if( head == 0 ) return msg;
    m_source_address = *head;
    return signal Routing.receive( msg );
  }


  command RoutingAddress_t RoutingGetSourceAddress.get()
  {
    return m_source_address;
  }
}

