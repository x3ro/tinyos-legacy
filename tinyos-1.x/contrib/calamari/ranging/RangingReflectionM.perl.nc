
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

// Authors: Cory Sharp and Kamin Whitehouse and Chris Karlof



includes ${Neighborhood};
includes Omnisound;
includes Config;
includes Localization;


module ${Reflection}M
{
  provides interface ${Attribute}Reflection;
  provides interface ${Attribute}ReflectionSnoop;
  provides interface StdControl;
  provides interface RangingControl;
  provides command void setRanging( RangingSetMsg_t args );

  
  uses interface ${Attribute};
  uses interface NeighborhoodComm as PullComm;
  uses interface Neighborhood as ${Neighborhood};
  uses interface ${Neighborhood}_private;

  uses command result_t addNeighbor(uint16_t nodeID);

  uses interface RangingTransmitter;
  uses interface RangingReceiver;
  uses interface Timer;
  uses interface DiagMsg;
  uses interface Leds;
  uses interface MsgBuffers;
  uses interface Random;
  uses interface ReceiveMsg as RangingReportReceive;
  
}
implementation
{
  enum
  {
    STATE_IDLE,
    STATE_BACKOFF,
    STATE_LISTEN,
    STATE_RANGING,
    STATE_RANGING_ONCE,
    STATE_RANGING_EXCHANGE
  };

  bool m_pushTask_pending;
  nodeID_t m_pull_id;
  uint8_t state;
  
  TOS_Msg msgBuf;
  uint8_t rangingSequenceNumber = 0;
  uint8_t batchNumber = 0;
  uint8_t rangingExchangeRetry = 0;

  uint8_t rangingValueReportIndex;
  uint8_t rangingValueReportNeighborIndex;
  uint8_t rangingValueReportType;
  uint8_t rangingNeighborsLeft = 0;
  bool rangingReportPending = FALSE;

  
  command result_t StdControl.init() {
    state = STATE_IDLE;
    G_Config.myRangingId = TOS_LOCAL_ADDRESS;
    m_pushTask_pending = FALSE;
    m_pull_id = 0;
    call Random.init();
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
    if(state == STATE_RANGING) {
      call RangingTransmitter.send(G_Config.myRangingId,
				   batchNumber,
				   rangingSequenceNumber, 
				   TRUE); 
    } else if( state == STATE_RANGING_ONCE){
      call RangingTransmitter.send(G_Config.myRangingId,
				   0, // rangingOnce gets batchNumber 0
				   rangingSequenceNumber, 
				   FALSE); 
    }

  }
  
  event result_t Timer.fired() {
    if(state == STATE_BACKOFF) {
      state = STATE_LISTEN;
      call Timer.start(TIMER_ONE_SHOT,
		       G_Config.RangingStartDelay.rangingStartDelayBase);
    } else if(state == STATE_LISTEN) {
      state = STATE_RANGING;
      rangingSequenceNumber = 1;
      post range();
    } else if(state == STATE_RANGING ||
	      state == STATE_RANGING_ONCE) { // in state STATE_RANGING or STATE_RANGE_ONCE
      post range(); 
    }
    else if(state == STATE_RANGING_EXCHANGE) {
      signal RangingControl.sendRangingExchange();
      rangingExchangeRetry++;
      if(rangingExchangeRetry < G_Config.RangingExchangeParameters.exchangeRetry) {
	call Timer.start(TIMER_ONE_SHOT,
			 G_Config.RangingExchangeParameters.exchangeRetryTimeout + (call Random.rand() & G_Config.RangingExchangeParameters.exchangeMask));
      } else {
	state = STATE_IDLE;
	signal RangingControl.rangingDone(SUCCESS);
      }
    }
    return SUCCESS;
  }
  
  command ${Type} ${Attribute}Reflection.get( nodeID_t id ) {
    ${Neighborhood}_t* node = call ${Neighborhood}_private.getID( id );
    return node ? node->data_${Reflection} : G_default_node_${Neighborhood}.data_${Reflection};
  }
  
  event void RangingTransmitter.sendDone(result_t success) {
    if((++rangingSequenceNumber) <=
       G_Config.RangingParameters.numberOfRangingEstimates)
      call Timer.start(TIMER_ONE_SHOT,
		       G_Config.RangingParameters.successiveRangeDelay +
		       (call Random.rand() & G_Config.RangingParameters.successiveRangeDelayMask));
    else if(batchNumber < G_Config.RangingParameters.numberOfBatches) {
      state = STATE_IDLE;
      call RangingControl.range();
    } 
    else if(G_Config.initiateSchedule) { 
      state = STATE_RANGING_EXCHANGE;
      rangingExchangeRetry = 0;
      call Timer.start(TIMER_ONE_SHOT,
		       G_Config.RangingExchangeParameters.exchangeTimeout + (call Random.rand() & G_Config.RangingExchangeParameters.exchangeMask));
    } else {
      state = STATE_IDLE;
      signal RangingControl.rangingDone(SUCCESS);
    }
  }

  void swap( uint16_t *x, uint16_t *y) {
    uint16_t tmp;
    
    tmp = *x;
    *x = *y;
    *y = tmp;
  }

  void bubble(uint16_t a[], uint8_t n) {
    uint8_t i,j;
    for ( i=0;i< n-1; i++)
      for (j=n-1;j>i; j--)
	if ( a[j-1] > a[j] )
	  swap( &a[j-1], &a[j]);
  }

  uint16_t median(uint16_t *tmp, uint8_t len){
    uint16_t array[len],i;
    for(i=0;i<len;i++)
      array[i]=tmp[i];
    
    bubble(array,len);
    return len%2 == 0 ? array[len/2-1] : array[(len-1)/2];
  }

  uint16_t medianMinFilter(moving_window_t *mw){ 
    uint16_t i, min=65535u, m_median, lowerBound=0;
    if(mw->n<G_Config.rangingCountMin) return 0;
    m_median = median(mw->begin, mw->n);
    //calculate lower bound
    if( (G_Config.proportionalMedianTube>0) && (G_Config.proportionalMedianTube<=1) ){
      lowerBound=m_median-G_Config.proportionalMedianTube*m_median;
    }
    else{
      if(m_median<G_Config.medianTube){ //check for unsigned underflow
	lowerBound=0;
      }
      else{
	lowerBound = m_median-G_Config.medianTube;
      }
    }
    for( i=0; i<mw->size; i++ ){ //find the min that is above the lowerBound
      if( (mw->begin[i]>= lowerBound) && (mw->begin[i]<min) ){
	min=mw->begin[i];
      }
    }
    return min==0? 1 : min;//don't return 0 because that means invalid data
  }
  
  uint16_t medianFilter(moving_window_t *mw){ 
    uint16_t m_median;
    if(mw->n<G_Config.rangingCountMin) return 0;
    m_median= median(mw->begin, mw->n);
    return m_median==0? 1 : m_median; //don't return 0 because that means invalid data
  }
  
  event result_t RangingReceiver.receive(uint16_t actuator,
					 uint16_t receivedRangingId,
					 uint16_t receivedBatchNumber,
					 uint16_t receivedSequenceNumber) {
    // signal up that ranging is still going on
    if(G_Config.LocationInfo.isAnchor && state == STATE_IDLE) {
      signal RangingControl.rangingOverheard();
    }
    if(state == STATE_LISTEN || state == STATE_RANGING) {
      state = STATE_BACKOFF;
      call RangingTransmitter.cancel();
      call Timer.stop();
      call Timer.start(TIMER_ONE_SHOT,
		       (G_Config.RangingParameters.numberOfRangingEstimates-
			receivedSequenceNumber+1) *
		       (G_Config.RangingParameters.successiveRangeDelay +
			(G_Config.RangingParameters.successiveRangeDelayMask+1)/2) + // half of randomness added to successive ranging delay
		       G_Config.RangingParameters.rangingPeriodFudgeFactor +
		       (call Random.rand() &
			G_Config.RangingStartDelay.rangingStartDelayMask));
    } else if(state == STATE_IDLE) {
      if(receivedBatchNumber > batchNumber) {
      call RangingControl.range();
      }
    } else if(state == STATE_RANGING_EXCHANGE) {
      call Timer.stop();
      call Timer.start(TIMER_ONE_SHOT,
		       G_Config.RangingExchangeParameters.exchangeTimeout + (call Random.rand() & G_Config.RangingExchangeParameters.exchangeMask));
    }
    return SUCCESS;
  }

  event void RangingReceiver.receiveDone(uint16_t actuator,
					 uint16_t receivedRangingId,
					 uint16_t distance,
					 bool initiateRangingSchedule) {
    ${Type} data;
    ${Neighborhood}_t* node;

    if(distance > G_Config.RangingFilterParameters.filterLow &&
       distance < G_Config.RangingFilterParameters.filterHigh) { // filtering
      if(!call ${Neighborhood}.isNeighbor(actuator)){
	call addNeighbor(actuator);
	node = call ${Neighborhood}_private.getID(actuator );
	init_moving_window(&(node->data_RangingMovingWindowRefl),
			   &(node->data_RangingWindowBufferRefl.buf[0]),
			   &(node->data_RangingWindowBufferRefl.buf[RANGING_WINDOW_BUFFER_SIZE-1]));
      }
      node = call ${Neighborhood}_private.getID( actuator );
      if( node != 0 ) {
	add_moving_window((moving_window_t*)&(node->data_RangingMovingWindowRefl),
			  distance);
	//data.distance=medianMinFilter((moving_window_t*)&(node->data_RangingMovingWindowRefl));
	data.distance=medianFilter((moving_window_t*)&(node->data_RangingMovingWindowRefl));

	/*	if(call DiagMsg.record() == SUCCESS) {
	  call DiagMsg.uint16(distance);
	  call DiagMsg.uint16(data.distance);
	  for(i=0;i<node->data_RangingMovingWindowRefl.size;i++) {
	    call DiagMsg.uint16(node->data_RangingMovingWindowRefl.begin[i]);
	  }
	  call DiagMsg.send();
	  }*/
	data.stdv=G_Config.RangingParameters.rangingStdv;
	node->data_${Reflection} = data;
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

  command void setRanging( RangingSetMsg_t args ) {
    ${Type} data;
    ${Neighborhood}_t* node;
    int i;

    for(i=0;i<args.numberOfNeighbors;i++){
      if(!call ${Neighborhood}.isNeighbor(args.neighbors[i].addr)){
	call addNeighbor(args.neighbors[i].addr);
	node = call ${Neighborhood}_private.getID(args.neighbors[i].addr );
	init_moving_window(&(node->data_RangingMovingWindowRefl), &(node->data_RangingWindowBufferRefl.buf[0]), &(node->data_RangingWindowBufferRefl.buf[RANGING_WINDOW_BUFFER_SIZE-1]));
      }
      
      node = call ${Neighborhood}_private.getID( args.neighbors[i].addr );
      if( node != 0 ) {
	add_moving_window((moving_window_t*)&(node->data_RangingMovingWindowRefl), args.neighbors[i].dist);
	data.distance=args.neighbors[i].dist; //not quite the same as above
	data.stdv=G_Config.RangingParameters.rangingStdv;
	node->data_${Reflection} = data;
	node->data_RangingCountRefl = node->data_RangingCountRefl + 1;
      }
    }   
  }

  event TOS_MsgPtr RangingReportReceive.receive(TOS_MsgPtr msg) {
    RangingReportMsg_t *report = (RangingReportMsg_t *)msg->data;
    uint8_t i=0;
    uint16_t sender = report->addr, distance=0;
    uint8_t numberOfNeighbors = report->numberOfNeighbors;
    ${Neighborhood}_t* node;
    ${Type} data;

    call Leds.redToggle();

    if(!G_Config.exchangeRanging)
      return msg;

    if(G_Config.LocationInfo.isAnchor && state == STATE_IDLE) {
      signal RangingControl.rangingOverheard();
    }

    for(i=0;i<numberOfNeighbors;i++) {
      distance = report->neighbors[i].dist;
      if(report->neighbors[i].addr == ((uint8_t) TOS_LOCAL_ADDRESS) && distance > 0) {
	if(!call ${Neighborhood}.isNeighbor(sender)) {
	  call addNeighbor(sender);
	  node = call ${Neighborhood}_private.getID(sender);
	  init_moving_window(&(node->data_RangingMovingWindowRefl), &(node->data_RangingWindowBufferRefl.buf[0]), &(node->data_RangingWindowBufferRefl.buf[RANGING_WINDOW_BUFFER_SIZE-1]));
	  data.distance = distance;
	  data.stdv = G_Config.RangingParameters.rangingStdv;
	} else {
	  node = call ${Neighborhood}_private.getID(sender);
	  data = node->data_${Reflection};
	  if(node->data_RangingCountRefl < G_Config.rangingCountMin)
	    data.distance = distance;
	  else {
	    switch (G_Config.rangingExchangeBehavior){
	    case 0: //average
	      data.distance = (uint16_t)((1.0*distance + data.distance)/(2.0));
	      break;
	    case 1: //max
	      if(distance > data.distance)
		data.distance = distance;
	      break;
	    case -1: //minimum
	      if(distance < data.distance)
		data.distance = distance;
	      break;
	    default:
	      break;
	    }
	  }
	  data.stdv = G_Config.RangingParameters.rangingStdv;
	}
	node->data_${Reflection} = data;
	signal ${Attribute}Reflection.updated( sender, node->data_${Reflection} );
      }
    }
    return msg;
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
    if(state == STATE_IDLE) {
      rangingSequenceNumber = 1;
      state = STATE_RANGING_ONCE;
      call Timer.start(TIMER_ONE_SHOT,
		       G_Config.RangingParameters.successiveRangeDelay);
    }
    return SUCCESS;
  }

  command result_t RangingControl.range() {
    if(state == STATE_IDLE) {
      state = STATE_LISTEN;
      rangingSequenceNumber = 1;
      batchNumber++;
      call Timer.start(TIMER_ONE_SHOT,
		       G_Config.RangingStartDelay.rangingStartDelayBase
		       + (call Random.rand() &
		       G_Config.RangingStartDelay.rangingStartDelayMask));
    }
    return SUCCESS;
  }

  command result_t RangingControl.rangingExchange() {
    state = STATE_RANGING_EXCHANGE;
    rangingExchangeRetry = 0;
    call Timer.stop();
    call Timer.start(TIMER_ONE_SHOT,
		     G_Config.RangingExchangeParameters.exchangeTimeout + 
		     (call Random.rand() & G_Config.RangingExchangeParameters.exchangeMask));
    return SUCCESS;
  }
/*    event result_t Wave.fired(uint8_t id, uint8_t level) { */
/*      if(id != RANGING_WAVE) */
/*        return SUCCESS; */
    
/*      rangingLevel = level; */
/*      if(state == STATE_IDLE) { */
/*        state = STATE_LISTEN; */
/*        rangingSequenceNumber = 1; */
/*        batchNumber = 1; */
/*        call Timer.start(TIMER_ONE_SHOT, */
/*  		       G_Config.RangingStartDelay.rangingStartDelayBase */
/*  		       + (call Random.rand() & */
/*  		       G_Config.RangingStartDelay.rangingStartDelayMask)); */
/*      } */
/*      return SUCCESS; */
/*    } */
  
  command result_t RangingControl.stop() {
    call Timer.stop();
    state = STATE_IDLE;
    return SUCCESS;
  }

  command result_t RangingControl.resume() {
   
    return SUCCESS;
  }

  
  command result_t RangingControl.reset() {
    call Timer.stop();
    state = STATE_IDLE;
    batchNumber = 0;
    call RangingHood.purge();
    return SUCCESS;
  }
}
