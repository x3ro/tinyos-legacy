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
// $Id: TinyOSRoutingM.nc,v 1.1 2003/10/09 01:14:17 cssharp Exp $

// Description: Translation layer from the NestArch Routing API to TinyOS.
// This component should be at the very bottom of the routing stack.

module TinyOSRoutingM
{
  provides
  {
    interface Routing;
    interface StdControl;
  }
  uses
  {
    interface SendMsg as BottomSendMsg[ uint8_t id ];
    interface ReceiveMsg as BottomReceiveMsg;
    interface Leds;
  }
}
implementation
{
  command result_t StdControl.init()
  {
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
    // Send this message over TinyOS broadcast, leaving the NestArch routing
    // layer to do the filtering, forwarding, etc.
    return call BottomSendMsg.send[ msg->dispatch.method ](
	dest.address, msg->length, msg );
  }

  event result_t BottomSendMsg.sendDone[ uint8_t amid ](
      TOS_MsgPtr msg,
      result_t success
    )
  {
    // If the message was broadcast, force ack to true?  Or false?  With false,
    // in reliable routing, the message will always be rebroadcast as much as
    // msg.ext.retries says.
    if( msg->addr == TOS_BCAST_ADDR )
      msg->ack = 0; // we'll go for false for now.

    // Signal sendDone, extracting the routing type from the AM ID.
    return signal Routing.sendDone( msg, success );
  }

  event TOS_MsgPtr BottomReceiveMsg.receive( TOS_MsgPtr msg )
  {
    // upon receiving a message from TinyOS, reinitialize the NestArch fields
    initRoutingMsg( msg, msg->length );
    // prepapre the method dispatch field
    msg->dispatch.method = msg->type;
    return signal Routing.receive( msg );
  }
}

