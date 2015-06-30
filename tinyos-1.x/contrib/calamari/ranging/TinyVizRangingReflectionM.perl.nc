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
// $Id: TinyVizRangingReflectionM.perl.nc,v 1.1 2003/10/09 05:56:04 fredjiang Exp $

/* this component will read the distance and standard deviation
   from the tinyviz plugin called Calamari.  That plugin must be installed
   and running.

   the user must define the parameters:
   ${Distance_ADC_channel}
   ${Distance_stdv_ADC_channel}
*/

includes ${Neighborhood};
includes TinyVizRangingReflection;

module ${Reflection}M
{
  provides interface ${Attribute}Reflection;
  provides interface ${Attribute}ReflectionSnoop;
  provides interface StdControl;
  uses interface ${Attribute};
  uses interface SendMsg;
  uses interface NeighborhoodComm as DataComm;
  uses interface NeighborhoodComm as PullComm;
  uses interface ${Neighborhood}_private;

  uses command result_t addNeighbor(uint16_t nodeID);

  uses interface MsgBuffers;

}
implementation
{
  bool m_pushTask_pending;
  nodeID_t m_pull_id;
  TOS_Msg m_msg;
  RangingDebugMsg_t* d;

  command result_t StdControl.init()
  {
    d = (RangingDebugMsg_t*)&(m_msg.data);
    m_pushTask_pending = FALSE;
    m_pull_id = 0;
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

  command ${Type} ${Attribute}Reflection.get( nodeID_t id )
  {
    ${Neighborhood}_t* node = call ${Neighborhood}_private.getID( id );
    return node ? node->data_${Reflection} : G_default_node_${Neighborhood}.data_${Reflection};
  }

  task void push()
  {
    TOS_MsgPtr msg = call MsgBuffers_alloc();//call ${Neighborhood}_private.lockMsgBuffer();
    m_pushTask_pending = FALSE;
    if( msg != 0 )
    {
      ${Type}* data = (${Type}*)initRoutingMsg( msg, sizeof(${Type}) );
      if( data != 0 )
      {
	*data = call ${Attribute}.get();
	if( call DataComm.send( POTENTIAL_CONEIGHBORS, msg ) == SUCCESS )
	  return;
      }
      dbg(DBG_USR1, "ERROR sending ranging data");
      call MsgBuffers.free(msg);//${Neighborhood}_private.unlockMsgBuffer( msg );
    }
  }

  command result_t ${Attribute}Reflection.push()
  {
    return post push() ? SUCCESS : FAIL;
  }

  void postPushTask()
  {
    if( m_pushTask_pending == FALSE )
    {
      m_pushTask_pending = TRUE;
      post push();
    }
  }

  event result_t DataComm.sendDone( TOS_MsgPtr msg, result_t success )
  {
    call MsgBuffers.free(msg);//${Neighborhood}_private.unlockMsgBuffer( msg );
    return SUCCESS;
  }

  TOS_MsgPtr processIncomingRangingData( nodeID_t src, TOS_MsgPtr msg )
  {
  }

  task void sendDebugMsg(){
    call SendMsg.send(TOS_BCAST_ADDR, 8, &m_msg);
  }

  event TOS_MsgPtr DataComm.receive( nodeID_t src, TOS_MsgPtr msg )
  {
    ${Type}* data = (${Type}*)popFromRoutingMsg( msg, sizeof(${Type}) );
    ${Neighborhood}_t* node = call ${Neighborhood}_private.getID( src );
    if( node != 0 )
    {
      dbg(DBG_USR1, "RSSI MSG: transmitter %d\n", src);                  //just for simulation
	  data->distance=generic_adc_read(TOS_LOCAL_ADDRESS,${Distance_ADC_channel},0);//just for simulation
	  data->stdv=generic_adc_read(TOS_LOCAL_ADDRESS,${Distance_stdv_ADC_channel},0);//just for simulation
	  if(data->distance==0) return msg;
	  node->data_${Reflection}=*data;
      addToEWMA(data->distance,&(node->data_EWMA${Reflection}));//added for EWMA
	  node->data_${Reflection}.distance=node->data_EWMA${Reflection}.mean;//added for EWMA
      signal ${Attribute}Reflection.updated( src, node->data_${Reflection} );
	  d->myID=TOS_LOCAL_ADDRESS;
	  d->hisID=src;
	  d->distance=node->data_${Reflection};
	  post sendDebugMsg();
    }
    return msg;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success){return SUCCESS;}

  event TOS_MsgPtr DataComm.receiveNAN( RoutingDestination_t src, TOS_MsgPtr msg ) {
    ${Type}* data = (${Type}*)popFromRoutingMsg( msg, sizeof(${Type}) );
    ${Neighborhood}_t* node;
    dbg(DBG_USR1, "RSSI MSG: transmitter %d\n", src);                  //just for simulation
    data->distance=generic_adc_read(TOS_LOCAL_ADDRESS,${Distance_ADC_channel},0);//just for simulation
    data->stdv=generic_adc_read(TOS_LOCAL_ADDRESS,${Distance_stdv_ADC_channel},0);//just for simulation
    if(data->distance==0)
      return msg;
    call addNeighbor(src.address);
    node = call ${Neighborhood}_private.getID( src.address );
    if( node != 0 ) {
      node->data_${Reflection} = *data;
      addToEWMA(data->distance,&(node->data_EWMA${Reflection}));//added for EWMA
      node->data_${Reflection}.distance=node->data_EWMA${Reflection}.mean;//added for EWMA
      signal ${Attribute}Reflection.updated( src.address, node->data_${Reflection} );
    }
    return msg;
  }

  default event void ${Attribute}ReflectionSnoop.updatedNAN( RoutingDestination_t src, ${Type} value ){}

  task void pull()
  {
    TOS_MsgPtr msg = call MsgBuffers_alloc(); //${Neighborhood}_private.lockMsgBuffer();
    if( msg != 0 )
    {
      if( call PullComm.send( m_pull_id, msg ) == SUCCESS )
	return;
      call MsgBuffers.free(msg);//${Neighborhood}_private.unlockMsgBuffer( msg );
    }
  }

  command result_t ${Attribute}Reflection.pull( nodeID_t id )
  {
    m_pull_id = id;
    return post pull() ? SUCCESS : FAIL;
  }

  event result_t PullComm.sendDone( TOS_MsgPtr msg, result_t success )
  {
    call MsgBuffers.free(msg);//${Neighborhood}_private.unlockMsgBuffer( msg );
    return SUCCESS;
  }

  event TOS_MsgPtr PullComm.receive( nodeID_t src, TOS_MsgPtr msg )
  {
    postPushTask();
    return msg;
  }

  event TOS_MsgPtr PullComm.receiveNAN( RoutingDestination_t src, TOS_MsgPtr msg )
  {
    postPushTask();
    return msg;
  }



  command void ${Attribute}Reflection.scribble( nodeID_t id, ${Type} value )
  {
    ${Neighborhood}_t* node = call ${Neighborhood}_private.getID( id );
    if( node != 0 )
      node->data_${Reflection} = value;
  }

  event void ${Attribute}.updated()
  {
    if( ${AutoPush} )
      postPushTask();
  }
}

