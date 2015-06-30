/* "Copyright (c) 2000-2003 The Regents of the University of California.  
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
// $Id: BroadcastBackendM.perl.nc,v 1.8 2003/06/27 07:45:53 cssharp Exp $

includes Routing;

module ${Neighborhood}CommBackendM
{
  provides interface NeighborhoodCommBackend;
  provides interface StdControl;
  uses interface RoutingSendByImplicit as RoutingSendBySingleBroadcast;
  uses interface RoutingSendByAddress;
  uses interface RoutingReceive;
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



  command result_t NeighborhoodCommBackend.sendPotentialConeighbors( TOS_MsgPtr msg )
  {
    return call RoutingSendBySingleBroadcast.send(msg);
  }


  command result_t NeighborhoodCommBackend.sendPotentialNeighbors( TOS_MsgPtr msg )
  {
    return call RoutingSendBySingleBroadcast.send(msg);
  }


  command result_t NeighborhoodCommBackend.sendAllNeighbors( TOS_MsgPtr msg )
  {
    return FAIL;
  }


  command result_t NeighborhoodCommBackend.sendNeighbor( nodeID_t dst, TOS_MsgPtr msg )
  {
    return call RoutingSendByAddress.send(dst,msg);
  }


  command result_t NeighborhoodCommBackend.sendNAN( RoutingDestination_t dst, TOS_MsgPtr msg )
  {
    return call RoutingSendByAddress.send(dst.address,msg);
  }


  event result_t RoutingSendBySingleBroadcast.sendDone( TOS_MsgPtr msg, result_t success )
  {
    return signal NeighborhoodCommBackend.sendDone( msg, success );
  }

  
  event result_t RoutingSendByAddress.sendDone( TOS_MsgPtr msg, result_t success )
  {
    return signal NeighborhoodCommBackend.sendDone( msg, success );
  }

  
  event TOS_MsgPtr RoutingReceive.receive( TOS_MsgPtr msg )
  {
    nodeID_t srcID = msg->ext.origin;
    RoutingDestination_t srcAddr = { address : srcID };
    return signal NeighborhoodCommBackend.receive( srcID, srcAddr, msg );
  }

  command RoutingDestination_t NeighborhoodCommBackend.getRoutingDestination( nodeID_t id )
  {
    RoutingDestination_t dest = { address : id };
    return dest;
  }
}

