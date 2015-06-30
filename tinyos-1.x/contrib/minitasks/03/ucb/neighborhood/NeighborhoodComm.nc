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
// $Id: NeighborhoodComm.nc,v 1.8 2003/05/06 16:12:59 cssharp Exp $

includes Routing;
includes Neighborhood;

interface NeighborhoodComm
{
  command result_t send( nodeID_t dest, TOS_MsgPtr msg );
  command result_t sendNAN( RoutingDestination_t dest, TOS_MsgPtr msg );
  event result_t sendDone( TOS_MsgPtr msg, result_t success );
  event TOS_MsgPtr receive( nodeID_t src, TOS_MsgPtr msg );
  event TOS_MsgPtr receiveNAN( RoutingDestination_t src, TOS_MsgPtr msg );
  command RoutingDestination_t getRoutingDestination( nodeID_t id );
}

