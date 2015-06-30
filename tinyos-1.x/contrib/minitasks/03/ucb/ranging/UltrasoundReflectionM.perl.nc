
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
// $Id: UltrasoundReflectionM.perl.nc,v 1.19 2003/10/03 01:14:25 ckarlof Exp $

includes ${Neighborhood};
includes Omnisound;
includes Config;

module ${Reflection}M
{
  provides interface ${Attribute}Reflection;
  provides interface ${Attribute}ReflectionSnoop;
  provides interface StdControl;
  provides interface RangingControl;
  provides interface AnchorInfoPropagation;
  
  uses interface ${Attribute};
  uses interface NeighborhoodComm as PullComm;
  uses interface Neighborhood as ${Neighborhood};
  uses interface ${Neighborhood}_private;

  uses command result_t addNeighbor(uint16_t nodeID);

  uses interface UltrasonicRangingTransmitter;
  uses interface UltrasonicRangingReceiver;
  uses interface Timer;
  uses interface DiagMsg;
  uses interface Leds;
  uses interface MsgBuffers;
  uses interface Random;
}
implementation
{
  enum
  {
    STATE_IDLE,
    STATE_BACKOFF,
    STATE_LISTEN,
    STATE_RANGING,
    STATE_RANGING_ONCE
  };

  bool m_pushTask_pending;
  nodeID_t m_pull_id;
  uint8_t state;
  
  TOS_Msg msgBuf;
  uint8_t rangingSequenceNumber = 0;
  uint8_t batchNumber = 0;
  
  command result_t StdControl.init() {
    state = STATE_IDLE;
    G_Config.myRangingId = TOS_LOCAL_ADDRESS;
    m_pushTask_pending = FALSE;
    m_pull_id = 0;
    batchNumber = 0;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call Timer.stop();
    state = STATE_IDLE;
    return SUCCESS;
  }

  task void range() {
    call UltrasonicRangingTransmitter.send(G_Config.myRangingId,
					   batchNumber,
					   rangingSequenceNumber, 
					   FALSE); 
  }
  
  void task signalRangingDone() {
    if(G_Config.signalRangingDone) {
      if( call DiagMsg.record() == SUCCESS ) {
	call DiagMsg.str("ranging done");
	call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
	call DiagMsg.send();
      }
    }
    signal RangingControl.rangingDone(SUCCESS);
  }
  
  event result_t Timer.fired() {
    if(state == STATE_BACKOFF) {
      state = STATE_LISTEN;
      call Timer.start(TIMER_ONE_SHOT,G_Config.RangingStartDelay.rangingStartDelayBase);
    } else if(state == STATE_LISTEN) {
      rangingSequenceNumber++;
      post range();
      state = STATE_RANGING;
      call Timer.start(TIMER_ONE_SHOT,G_Config.RangingParameters.rangingPeriodEstimate);
    } else {
      rangingSequenceNumber++;
      post range();
      if(rangingSequenceNumber < G_Config.RangingParameters.numberOfRangingEstimates)
	call Timer.start(TIMER_ONE_SHOT,G_Config.RangingParameters.rangingPeriodEstimate);
      else {
	state = STATE_IDLE;
	post signalRangingDone();
      }
    }
    return SUCCESS;
  }
  
  command ${Type} ${Attribute}Reflection.get( nodeID_t id ) {
    ${Neighborhood}_t* node = call ${Neighborhood}_private.getID( id );
    return node ? node->data_${Reflection} : G_default_node_${Neighborhood}.data_${Reflection};
  }
  
  event void UltrasonicRangingTransmitter.sendDone() {
//    rangingSequenceNumber++;
    call Leds.redToggle();
    //  if(state == STATE_RANGING && // checks if stop command was issued
    // rangingSequenceNumber < G_Config.RangingParameters.numberOfRangingEstimates)
    //post range();

  }

  event result_t UltrasonicRangingReceiver.receive(uint16_t actuator,
						   uint16_t receivedRangingId,
						   uint16_t sequenceNumber,
						   bool initiateRangingSchedule_) {
    call Leds.redToggle();
    if(state == STATE_LISTEN) {
      state = STATE_BACKOFF;
      call Timer.start(TIMER_ONE_SHOT,
		       (G_Config.RangingParameters.numberOfRangingEstimates-sequenceNumber+1) *
		       G_Config.RangingParameters.rangingPeriodEstimate +
		       G_Config.RangingParameters.rangingPeriodFudgeFactor +
		       (call Random.rand() & G_Config.RangingStartDelay.rangingStartDelayMask));
    } 
    return SUCCESS;
  }

  event void UltrasonicRangingReceiver.receiveDone(uint16_t actuator, uint16_t receivedRangingId,
						   uint16_t distance) {
    ${Type} data;
    ${Neighborhood}_t* node;

    if(distance > G_Config.UltrasoundFilterParameters.ultrasoundFilterLow &&
       distance < G_Config.UltrasoundFilterParameters.ultrasoundFilterHigh) { // filtering
      if(!call ${Neighborhood}.isNeighbor(actuator))
	call addNeighbor(actuator);
      node = call ${Neighborhood}_private.getID( actuator );
      if( node != 0 ) {
	data.distance=distance;
	//estimate the vu ranging to have 20 centimeter error
	data.stdv=G_Config.RangingParameters.rangingStdv;
	node->data_${Reflection} = data;
	addToEWMA(data.distance,&(node->data_EWMA${Reflection}));//added for EWMA
	node->data_${Reflection}.distance=node->data_EWMA${Reflection}.mean;//added for EWMA
	node->data_RangingCountRefl = node->data_RangingCountRefl + 1;
	signal ${Attribute}Reflection.updated( actuator, node->data_${Reflection} );
      }   
    }

    if(G_Config.rangingDebug) {
      //this if statement is only for debugging
      if( call DiagMsg.record() == SUCCESS ) {
	call DiagMsg.str("ranging");
	call DiagMsg.uint16(actuator);
	call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
	call DiagMsg.uint16(distance);
	call DiagMsg.send();
      }
    }
   
  }

  command result_t ${Attribute}Reflection.push()
  {
    result_t result = SUCCESS;
    return result;
  }

  void postPushTask()
  {
/*      if( m_pushTask_pending == FALSE ) { */
/*        m_pushTask_pending = TRUE; */
/*        post push(); */
/*      } */
  }

  default event void ${Attribute}ReflectionSnoop.updatedNAN( RoutingDestination_t src,
							     ${Type} value ){}

  task void pull()
  {
/*      TOS_MsgPtr msg = call MsgBuffers_alloc(); */
/*      if( msg != 0 ) { */
/*        if( call PullComm.send( m_pull_id, msg ) == SUCCESS ) */
/*  	return; */
/*        call MsgBuffers.free(msg); */
/*      } */
  }
  
  command result_t ${Attribute}Reflection.pull( nodeID_t id )
  {
/*      m_pull_id = id; */
/*      return post pull() ? SUCCESS : FAIL; */
    return SUCCESS;
  }

  event result_t PullComm.sendDone( TOS_MsgPtr msg, result_t success )
  {
//    call MsgBuffers.free(msg);
    return SUCCESS;
  }

  event TOS_MsgPtr PullComm.receive( nodeID_t src, TOS_MsgPtr msg )
  {
//    postPushTask();
    return msg;
  }

  event TOS_MsgPtr PullComm.receiveNAN( RoutingDestination_t src, TOS_MsgPtr msg )
  {
//    postPushTask();
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
  
  command result_t RangingControl.rangeOnce() {
    rangingSequenceNumber = 0;
    batchNumber = 0;
    state = STATE_RANGING_ONCE;
    call Timer.start(TIMER_ONE_SHOT,G_Config.RangingParameters.rangingPeriodEstimate);
    return SUCCESS;
//return post range() ? SUCCESS : FAIL;
  }

  command result_t RangingControl.range(uint8_t batchNumber_) {
    if(state == STATE_IDLE) {
      state = STATE_LISTEN;
      rangingSequenceNumber = 0;
      batchNumber = batchNumber_;
      call Timer.start(TIMER_ONE_SHOT,G_Config.RangingStartDelay.rangingStartDelayBase + call Random.rand() & G_Config.RangingStartDelay.rangingStartDelayMask);
    }
    return SUCCESS;
  }
  
  command result_t RangingControl.stop() {
    //call Timer.stop();
    //state = STATE_IDLE;
    return SUCCESS;
  }

  command result_t RangingControl.reset() {
    call Timer.stop();
    state = STATE_IDLE;
    batchNumber = 0;
  }
}

