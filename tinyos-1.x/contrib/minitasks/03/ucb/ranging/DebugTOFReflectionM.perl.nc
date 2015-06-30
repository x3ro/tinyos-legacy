
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

// Authors: Cory Sharp and Kamin Whitehouse
// $Id: DebugTOFReflectionM.perl.nc,v 1.5 2003/07/10 17:59:57 cssharp Exp $

includes Timer;

includes ${Neighborhood};

module ${Reflection}M
{
  provides interface ${Attribute}Reflection;
  provides interface ${Attribute}ReflectionSnoop;
  provides interface StdControl;
  uses interface ${Attribute};
//  uses interface NeighborhoodComm as DataComm;
//  uses interface SendMsg;
  uses interface NeighborhoodComm as PullComm;
  uses interface Neighborhood as ${Neighborhood};
  uses interface ${Neighborhood}_private;

  uses command result_t addNeighbor(uint16_t nodeID);

  uses interface AcousticRangingActuator;
  uses interface AcousticRangingSensor;
  uses interface Timer;
  uses interface DiagMsg;
  uses interface Leds;
  uses interface MsgBuffers;
  
}
implementation
{
	enum
	{
		STATE_IDLE,
		STATE_ACTUATING,
		STATE_SENSING,
	};

	enum
	{
//		TIMER_RATE = 3276,	// 0.1 sec (in jiffies)
	        TIMER_RATE = 100,
		INITIAL_DELAY = 32,	// in TIMER_RATE units
		ACTUATE_PERIOD = 640,
		BUSY_BACKOFF = 64,
	};

  bool m_pushTask_pending;
  nodeID_t m_pull_id;

	uint8_t state;
	int16_t timeout;

  command result_t StdControl.init()
  {
    state = STATE_IDLE;
    m_pushTask_pending = FALSE;
    m_pull_id = 0;
    call MsgBuffers.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    timeout = INITIAL_DELAY;
    call Timer.start(TIMER_REPEAT,TIMER_RATE);
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }
  
  event result_t Timer.fired() {
//		call Leds.yellowToggle();

    if( --timeout == 0 ) {
      if( state == STATE_IDLE ) {
	if( call AcousticRangingActuator.send() == SUCCESS ) {
	  //call Leds.redOn();
	  state = STATE_ACTUATING;
	}
	else {
	  timeout = BUSY_BACKOFF;
	}
      }
    }
    
    return SUCCESS;
  }

  command ${Type} ${Attribute}Reflection.get( nodeID_t id )
  {
    ${Neighborhood}_t* node = call ${Neighborhood}_private.getID( id );
    return node ? node->data_${Reflection} : G_default_node_${Neighborhood}.data_${Reflection};
  }

  task void push()
  {
//	  call Leds.yellowToggle();
	  
//	  if( --timeout == 0 )
    {
      if( state == STATE_IDLE ) {
	if( call AcousticRangingActuator.send() == SUCCESS ) {
	  //call Leds.redOn();
	  state = STATE_ACTUATING;
	}
//					  else
//						  timeout = BUSY_BACKOFF;
      }
    }
/*    TOS_MsgPtr msg = call ${Neighborhood}_private.lockMsgBuffer();
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
      call ${Neighborhood}_private.unlockMsgBuffer( msg );
	  }*/
  }

  event void AcousticRangingActuator.sendDone() {
    //call Leds.redOff();
    timeout = ACTUATE_PERIOD;
    state = STATE_IDLE;
  }

  event result_t AcousticRangingSensor.receive(uint16_t actuator) {
    // this should always be true
    if( state == STATE_IDLE ) {
      state = STATE_SENSING;
      call Leds.greenToggle();
      return SUCCESS;
    }
    return FAIL;
  }

/*	task void sendDebugMsg(){
		call SendMsg.send(TOS_BCAST_ADDR, 8, &m_msg);
		}*/

  event void AcousticRangingSensor.receiveDone(uint16_t actuator, int16_t distance) {
    ${Type} data;
    ${Neighborhood}_t* node;

    call Leds.redToggle();
    //call Leds.greenOff();
    while( timeout < BUSY_BACKOFF )
      timeout += BUSY_BACKOFF;
    state = STATE_IDLE;
    
    if(distance != -1) { // VU code returns -1 for errors
      if(!call ${Neighborhood}.isNeighbor(actuator))
	call addNeighbor(actuator);
      node = call ${Neighborhood}_private.getID( actuator );
      if( node != 0 ) {
	data.distance=distance;
	data.stdv=5;//just give some small value for debugging
	node->data_${Reflection} = data;
	addToEWMA(data.distance,&(node->data_EWMA${Reflection}));//added for EWMA
	node->data_${Reflection}.distance=node->data_EWMA${Reflection}.mean;//added for EWMA
	signal ${Attribute}Reflection.updated( actuator, node->data_${Reflection} );
      }
/*				d->myID=TOS_LOCAL_ADDRESS;
				d->hisID=actuator;
				d->distance=node->data_${Reflection};
				post sendDebugMsg();*/
    }
		//this if statement is only for debugging
    if( call DiagMsg.record() == SUCCESS ) {
      call DiagMsg.str("ranging");
      call DiagMsg.uint16(actuator);
      call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
      call DiagMsg.int16(distance);
      call DiagMsg.send();
    } 
  }


  //event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success){return SUCCESS;}

  result_t postPushTask()
  {
    if( m_pushTask_pending == FALSE )
    {
      m_pushTask_pending = TRUE;
      return post push();
    }
    return FAIL;
  }

  command result_t ${Attribute}Reflection.push()
  {
    return postPushTask();
    //return post push() ? SUCCESS : FAIL;
  }

/*  event result_t DataComm.sendDone( TOS_MsgPtr msg, result_t success )
  {
    call ${Neighborhood}_private.unlockMsgBuffer( msg );
    return SUCCESS;
  }

  event TOS_MsgPtr DataComm.receive( nodeID_t src, TOS_MsgPtr msg )
  {
    ${Type}* data = (${Type}*)popFromRoutingMsg( msg, sizeof(${Type}) );
    ${Neighborhood}_t* node = call ${Neighborhood}_private.getID( src );
    if( node != 0 )
    {
      node->data_${Reflection} = *data;
      signal ${Attribute}Reflection.updated( src, *data );
    }
    return msg;
	}

  event TOS_MsgPtr DataComm.receiveNAN( RoutingDestination_t src, TOS_MsgPtr msg )
  {
    ${Type}* data = (${Type}*)popFromRoutingMsg( msg, sizeof(${Type}) );
    signal ${Attribute}ReflectionSnoop.updatedNAN( src, *data );
    return msg;
	}*/

  default event void ${Attribute}ReflectionSnoop.updatedNAN( RoutingDestination_t src, ${Type} value ){}

  task void pull()
  {
    //TOS_MsgPtr msg = call ${Neighborhood}_private.lockMsgBuffer();
    TOS_MsgPtr msg = call MsgBuffers_alloc();
    if( msg != 0 )
    {
      if( call PullComm.send( m_pull_id, msg ) == SUCCESS )
	return;
      //call ${Neighborhood}_private.unlockMsgBuffer( msg );
      call MsgBuffers.free(msg);
    }
  }

  command result_t ${Attribute}Reflection.pull( nodeID_t id )
  {
    m_pull_id = id;
    return post pull() ? SUCCESS : FAIL;
  }

  event result_t PullComm.sendDone( TOS_MsgPtr msg, result_t success )
  {
    call MsgBuffers.free(msg);
    //call ${Neighborhood}_private.unlockMsgBuffer( msg );
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

  event void RangingHood.removingNeighbor( nodeID_t id ){
  }

  event void RangingHood.addedNeighbor( nodeID_t id ){
  }

}

