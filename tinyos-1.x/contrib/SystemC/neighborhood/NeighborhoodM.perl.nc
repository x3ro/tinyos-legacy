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
// $Id: NeighborhoodM.perl.nc,v 1.1 2003/10/09 01:14:14 cssharp Exp $

includes Routing;
includes Neighborhood;
includes ${Neighborhood};

module ${Neighborhood}M
{
  provides interface Neighborhood;
  provides interface NeighborhoodComm[ RoutingProtocol_t proto ];
  provides interface ${Neighborhood}_private;
  provides interface StdControl;
  uses interface NeighborhoodCommBackend;
  uses interface NeighborhoodManager;
  uses interface StdControl as ManagerStdControl;
  uses interface StdControl as ReflectionStdControl;
  uses interface StdControl as CommandStdControl;
  uses interface StdControl as CommBackendStdControl;
  uses interface MsgBuffers;
}
implementation
{
  ${Neighborhood}_t m_nodes[MAX_MEMBERS_${Neighborhood}];
  uint8_t m_numNodes;

  command result_t StdControl.init()
  {
    int ii;
    m_numNodes = 0;
    call MsgBuffers.init();
    for( ii=0; ii<MAX_MEMBERS_${Neighborhood}; ii++ )
      m_nodes[ii] = G_default_node_${Neighborhood};
    call ManagerStdControl.init();
    call CommandStdControl.init();
    call ReflectionStdControl.init();
    call CommBackendStdControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call ManagerStdControl.start();
    call CommandStdControl.start();
    call ReflectionStdControl.start();
    call CommBackendStdControl.start();
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call CommBackendStdControl.stop();
    call ReflectionStdControl.stop();
    call CommandStdControl.stop();
    call ManagerStdControl.stop();
    return SUCCESS;
  }

  default command result_t ReflectionStdControl.init() { return SUCCESS; }
  default command result_t ReflectionStdControl.start() { return SUCCESS; }
  default command result_t ReflectionStdControl.stop() { return SUCCESS; }

  default command result_t CommandStdControl.init() { return SUCCESS; }
  default command result_t CommandStdControl.start() { return SUCCESS; }
  default command result_t CommandStdControl.stop() { return SUCCESS; }


  command void Neighborhood.purge() {
    uint8_t ii;
    m_numNodes = 0;
    for( ii=0; ii<MAX_MEMBERS_${Neighborhood}; ii++ )
      m_nodes[ii] = G_default_node_${Neighborhood};
  }
  
  command uint8_t Neighborhood.numNeighbors()
  {
    return m_numNodes;
  }

  command nodeID_t Neighborhood.getNeighbor( uint8_t n_index )
  {
    return (n_index < m_numNodes) ? m_nodes[n_index].id : INVALID_NEIGHBOR;
  }

  command bool Neighborhood.isNeighbor( nodeID_t id )
  {
    return (call ${Neighborhood}_private.getID(id) != INVALID_NEIGHBOR);
  }

  command void Neighborhood.bootstrap()
  {
    call NeighborhoodManager.prune();
    call NeighborhoodManager.pullManagementInfo();
  }

  command void Neighborhood.refresh()
  {
    call NeighborhoodManager.pushManagementInfo();
  }

  command ${Neighborhood}_t* ${Neighborhood}_private.getID( nodeID_t id )
  {
    if( id != INVALID_NEIGHBOR )
    {
      int ii;
      for( ii=0; ii<m_numNodes; ii++ )
      {
	if( m_nodes[ii].id == id )
	  return m_nodes+ii;
      }
    }
    return 0;
  }

  command ${Neighborhood}_t* ${Neighborhood}_private.getNeighbors()
  {
    return m_nodes;
  }

  command result_t ${Neighborhood}_private.removeID( nodeID_t id )
  {
    if( m_numNodes > 0 )
    {
      ${Neighborhood}_t* node = call ${Neighborhood}_private.getID( id );
      if( node != 0 )
      {
    dbg(DBG_USR1, "AllNeighborhoods DIRECTED GRAPH: remove edge %d\n", id);
	signal Neighborhood.removingNeighbor( id );
	*node = m_nodes[m_numNodes-1];
	m_nodes[m_numNodes-1] = G_default_node_${Neighborhood};
	m_numNodes--;
	return SUCCESS;
      }
    }
    return FAIL;
  }

  command result_t ${Neighborhood}_private.addID( nodeID_t id, const ${Neighborhood}_t* init )
  {
    return call ${Neighborhood}_private.changeID( INVALID_NEIGHBOR, id, init );
  }

  command result_t ${Neighborhood}_private.changeID( nodeID_t oldID, nodeID_t newID, const ${Neighborhood}_t* init )
  {
    // fail if the new id already exists or is invalid 
    ${Neighborhood}_t* node = call ${Neighborhood}_private.getID( newID );
    if( (node != 0) || (newID == INVALID_NEIGHBOR) )
      return FAIL;

    // if the old id exists, signal removing
    // otherwise, add if there's room, or fail
    node = call ${Neighborhood}_private.getID( oldID );
    if( node != 0 )
    {
	  dbg(DBG_USR1, "AllNeighborhoods DIRECTED GRAPH: remove edge %d\n", oldID);
      signal Neighborhood.removingNeighbor( oldID );
    }
    else
    {
      if( m_numNodes >= MAX_MEMBERS_${Neighborhood} )
	return FAIL;
      node = m_nodes + m_numNodes;
      m_numNodes++;
    }

    // commit the new node data
    *node = *init;
    node->id = newID;

    // signal added and finish
    dbg(DBG_USR1, "AllNeighborhoods DIRECTED GRAPH: add edge %d\n", newID);
    signal Neighborhood.addedNeighbor( newID );
    return SUCCESS;
  }


  // ---
  // --- Neighborhood comm
  // ---

  result_t pushProtoHeader( TOS_MsgPtr msg, RoutingProtocol_t proto )
  {
    RoutingProtocol_t* header = (RoutingProtocol_t*)pushToRoutingMsg( msg, sizeof(RoutingProtocol_t) );
    if( header == 0 ) return FAIL;
    *header = proto;
    return SUCCESS;
  }

  RoutingProtocol_t popProtoHeader( TOS_MsgPtr msg )
  {
    RoutingProtocol_t* header = (RoutingProtocol_t*)popFromRoutingMsg( msg, sizeof(RoutingProtocol_t) );
    return (header == 0) ? 0 : *header;
  }

  command result_t NeighborhoodComm.send[ RoutingProtocol_t proto ]( nodeID_t dest, TOS_MsgPtr msg )
  {
    if( pushProtoHeader( msg, proto ) == FAIL )
      return FAIL;

    switch( dest )
    {
      case INVALID_NEIGHBOR:
	return FAIL;

      case POTENTIAL_CONEIGHBORS:
	return call NeighborhoodCommBackend.sendPotentialConeighbors( msg );

      case POTENTIAL_NEIGHBORS:
	return call NeighborhoodCommBackend.sendPotentialNeighbors( msg );

      case ALL_NEIGHBORS:
	return call NeighborhoodCommBackend.sendAllNeighbors( msg );
    }

    return call NeighborhoodCommBackend.sendNeighbor( dest, msg );
  }

  command result_t NeighborhoodComm.sendNAN[ RoutingProtocol_t proto ]( RoutingDestination_t dest, TOS_MsgPtr msg )
  {
    if( pushProtoHeader( msg, proto ) == FAIL )
      return FAIL;
    return call NeighborhoodCommBackend.sendNAN( dest, msg );
  }

  event result_t NeighborhoodCommBackend.sendDone( TOS_MsgPtr msg, result_t success )
  {
    RoutingProtocol_t proto = popProtoHeader( msg );
    return signal NeighborhoodComm.sendDone[proto]( msg, success );
  }

  event TOS_MsgPtr NeighborhoodCommBackend.receive( nodeID_t srcID, RoutingDestination_t srcAddr, TOS_MsgPtr msg )
  {
    RoutingProtocol_t proto = popProtoHeader( msg );
    if( call Neighborhood.isNeighbor(srcID) == FALSE )
      return signal NeighborhoodComm.receiveNAN[proto]( srcAddr, msg );
    return signal NeighborhoodComm.receive[proto]( srcID, msg );
  }

  default event result_t NeighborhoodComm.sendDone[ RoutingProtocol_t proto ]( TOS_MsgPtr msg, result_t success )
  {
    return SUCCESS;
  }

  default event TOS_MsgPtr NeighborhoodComm.receive[ RoutingProtocol_t proto ]( nodeID_t srcID, TOS_MsgPtr msg )
  {
    return msg;
  }

  default event TOS_MsgPtr NeighborhoodComm.receiveNAN[ RoutingProtocol_t proto ]( RoutingDestination_t srcAddr, TOS_MsgPtr msg )
  {
    return msg;
  }

  command RoutingDestination_t NeighborhoodComm.getRoutingDestination[ RoutingProtocol_t proto ]( nodeID_t id )
  {
    return call NeighborhoodCommBackend.getRoutingDestination( id );
  }

}

