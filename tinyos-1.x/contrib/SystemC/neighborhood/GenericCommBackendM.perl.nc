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
// $Id: GenericCommBackendM.perl.nc,v 1.1 2003/10/09 01:14:14 cssharp Exp $

includes Routing;

module ${Neighborhood}CommBackendM
{
  provides interface NeighborhoodCommBackend;
  provides interface StdControl;
  uses interface SendMsg;
  uses interface ReceiveMsg;
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


  result_t pushSrc( TOS_MsgPtr msg )
  {
    nodeID_t* id = (nodeID_t*)pushToRoutingMsg( msg, sizeof(nodeID_t) );
    if( id != 0 )
    {
      *id = TOS_LOCAL_ADDRESS;
      return SUCCESS;
    }
    return FAIL;
  }

  nodeID_t popSrc( TOS_MsgPtr msg )
  {
    nodeID_t* id = (nodeID_t*)popFromRoutingMsg( msg, sizeof(nodeID_t) );
    return (id != 0) ? *id : INVALID_NEIGHBOR;
  }

  result_t send( uint16_t dest, TOS_MsgPtr msg )
  {
    if( pushSrc( msg ) == SUCCESS )
      return call SendMsg.send( dest, msg->length, msg );
    return FAIL;
  }



  command result_t NeighborhoodCommBackend.sendPotentialConeighbors( TOS_MsgPtr msg )
  {
    return send( TOS_BCAST_ADDR, msg );
  }


  command result_t NeighborhoodCommBackend.sendPotentialNeighbors( TOS_MsgPtr msg )
  {
    return send( TOS_BCAST_ADDR, msg );
  }


  command result_t NeighborhoodCommBackend.sendAllNeighbors( TOS_MsgPtr msg )
  {
    return FAIL;
  }


  command result_t NeighborhoodCommBackend.sendNeighbor( nodeID_t dst, TOS_MsgPtr msg )
  {
    return send( dst, msg );
  }


  command result_t NeighborhoodCommBackend.sendNAN( RoutingDestination_t dst, TOS_MsgPtr msg )
  {
    return send( dst.address, msg );
  }


  event result_t SendMsg.sendDone( TOS_MsgPtr msg, result_t success )
  {
    popSrc( msg );
    return signal NeighborhoodCommBackend.sendDone( msg, success );
  }

  
  event TOS_MsgPtr ReceiveMsg.receive( TOS_MsgPtr msg )
  {
    nodeID_t id = popSrc( msg );
    if( id != INVALID_NEIGHBOR )
    {
      RoutingDestination_t srcAddr = { address : id };
      return signal NeighborhoodCommBackend.receive( id, srcAddr, msg );
    }
    return msg;
  }

  command RoutingDestination_t NeighborhoodCommBackend.getRoutingDestination( nodeID_t id )
  {
    RoutingDestination_t dest = { address : id };
    return dest;
  }
}

