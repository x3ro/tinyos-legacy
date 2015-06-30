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

// Authors: Kamin Whitehouse
// Date:    5/2/03

/*  This component chooses N most recently heard neighbors.
	If the node you want is not in the list, you can add it
	and the oldest node will be bumped out.
	
	You should search-replace all occurences of RangingHood
	with the name of your hood
	*/

includes common_structs;
includes RangingHood;
includes Neighborhood;

module MostRecentNeighborsM
{
  provides
  {
    interface StdControl;
    interface NeighborhoodManager;
    command result_t addNeighbor(uint16_t nodeID);
  }
  uses
  {
    interface Neighborhood as RangingHood;
    interface RangingHood_private;
    interface NeighborhoodComm as ManagementComm;
    interface NeighborhoodComm as ManagementRequestComm;
    interface MsgBuffers;
  }
}

implementation
{
  uint8_t oldestNeighbor=0;
  bool m_pushTask_pending;

  enum {
    RANK_THRESHOLD = 65535u, //set threshold to zero so we never prune anybody
  };

  command result_t addNeighbor(uint16_t nodeID)
  {
    if(call RangingHood_private.changeID(call RangingHood.getNeighbor(oldestNeighbor),
					 nodeID, &G_default_node_RangingHood)) {
      oldestNeighbor++;
      if(oldestNeighbor>MAX_MEMBERS_RangingHood)
	oldestNeighbor=0;
    }
    return SUCCESS;
  }

  command result_t StdControl.init()
  {
    m_pushTask_pending = FALSE;
    call MsgBuffers.init();
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

  command void NeighborhoodManager.prune(){
  }

  task void push()
  {
    uint16_t *myID;
    TOS_MsgPtr msg = call MsgBuffers_alloc(); //RangingHood_private.lockMsgBuffer();
    m_pushTask_pending = FALSE;
    if( msg != 0 )
    {
      myID = (uint16_t*)pushToRoutingMsg( msg, sizeof(uint16_t) );
      if( myID != 0 )
      {
	*myID=TOS_LOCAL_ADDRESS;
	if(call ManagementComm.send(POTENTIAL_CONEIGHBORS, msg)==SUCCESS){
	  dbg(DBG_USR3, "CLOSEST_NBR_MGR: sending  management info\n");
	  return;
	}
      }
      call MsgBuffers.free(msg);
    }
  }

  void postPushTask()
  {
    if( m_pushTask_pending == FALSE )
    {
      m_pushTask_pending = TRUE;
      post push();
    }
  }


  command void NeighborhoodManager.pushManagementInfo(){
//    dbg(DBG_USR2, "CLOSEST_NBR_MGR: pushing management info\n");
    postPushTask();
  }

  event result_t ManagementComm.sendDone( TOS_MsgPtr msg, result_t success )
  {
    call MsgBuffers.free( msg ); //RangingHood_private.unlockMsgBuffer( msg );
    return SUCCESS;
  }

  event TOS_MsgPtr ManagementComm.receive( nodeID_t src, TOS_MsgPtr msg ) {
    call addNeighbor(src);
    return msg;
  }

  event TOS_MsgPtr ManagementComm.receiveNAN( RoutingDestination_t src, TOS_MsgPtr msg )
  {
    call addNeighbor(src.address);
    return msg;
  }

  task void pull()
  {
    TOS_MsgPtr msg = call MsgBuffers_alloc(); //RangingHood_private.lockMsgBuffer();
    if( msg != 0 )
    {
      if( call ManagementRequestComm.send(POTENTIAL_NEIGHBORS, msg ) == SUCCESS )
	return;
      call MsgBuffers.free( msg ); //RangingHood_private.unlockMsgBuffer( msg );
    }
  }
  
  command void NeighborhoodManager.pullManagementInfo(){
//    dbg(DBG_USR2, "CLOSEST_NBR_MGR: pulling management info\n");
    post pull() ? SUCCESS : FAIL;
  }

  event result_t ManagementRequestComm.sendDone( TOS_MsgPtr msg, result_t success )
  {
    call MsgBuffers.free( msg ); //RangingHood_private.unlockMsgBuffer( msg );
    return SUCCESS;
  }

  event TOS_MsgPtr ManagementRequestComm.receive( nodeID_t src, TOS_MsgPtr msg )
  {
    postPushTask();
    return msg;
  }

  event TOS_MsgPtr ManagementRequestComm.receiveNAN( RoutingDestination_t src, TOS_MsgPtr msg )
  {
    postPushTask();
    return msg;
  }

  event void RangingHood.removingNeighbor( nodeID_t id ){
    dbg(DBG_USR1, "RangingHood DIRECTED GRAPH: remove edge %d\n", id);
  }

  event void RangingHood.addedNeighbor( nodeID_t id ){
    dbg(DBG_USR1, "RangingHood DIRECTED GRAPH: add edge %d\n", id);
  }

}



