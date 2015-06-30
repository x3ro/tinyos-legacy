
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
// $Id: UltrasoundReflectionM.perl.nc,v 1.14 2004/04/22 22:57:28 kaminw Exp $


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

  uses interface UltrasonicRangingTransmitter;
  uses interface UltrasonicRangingReceiver;
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
    STATE_RANGING_ONCE
  };

  bool m_pushTask_pending;
  nodeID_t m_pull_id;
  uint8_t state;
  
  TOS_Msg msgBuf;
  uint8_t rangingSequenceNumber = 0;
  uint8_t batchNumber = 0;
  
  command result_t StdControl.init() {
    //    uint8_t i;
    //    ${Neighborhood}_t* node;
    //    uint16_t *buffer;
    state = STATE_IDLE;
    G_Config.myRangingId = TOS_LOCAL_ADDRESS;
    m_pushTask_pending = FALSE;
    m_pull_id = 0;
    batchNumber = 0;

    //    for(i=0;i<MAX_MEMBERS_RangingHood;i++){
    //      node = call ${Neighborhood}_private.getID( call ${Neighborhood}.getNeighbor(i) );
      //buffer=node->data_RangingWindowBufferRefl.buf;
      //init_moving_window(&(node->data_RangingMovingWindowRefl), buffer, buffer+RANGING_WINDOW_BUFFER_SIZE-1);      
      //      init_moving_window(&(node->data_RangingMovingWindowRefl), node->data_RangingWindowBufferRefl.buf, node->data_RangingWindowBufferRefl.buf + RANGING_WINDOW_BUFFER_SIZE-1);
    //      init_moving_window(&(node->data_RangingMovingWindowRefl), &(node->data_RangingWindowBufferRefl.buf[0]), &(node->data_RangingWindowBufferRefl.buf[RANGING_WINDOW_BUFFER_SIZE-1]));
    //    }
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
    if(state == STATE_RANGING || state==STATE_RANGING_ONCE){
      call UltrasonicRangingTransmitter.send(G_Config.myRangingId,
					   batchNumber,
					   rangingSequenceNumber, 
					   FALSE); 
    }
  }
  
  void task signalRangingDone() {
    state = STATE_IDLE;
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
      call Timer.start(TIMER_ONE_SHOT,
		       G_Config.RangingStartDelay.rangingStartDelayBase);
    } else if(state == STATE_LISTEN) {
      state = STATE_RANGING;
      rangingSequenceNumber = 1;
      post range();
    } else if(state!=STATE_IDLE){ // in state STATE_RANGING or STATE_RANGE_ONCE
      post range();
    }
    return SUCCESS;
  }
  
  command ${Type} ${Attribute}Reflection.get( nodeID_t id ) {
    ${Neighborhood}_t* node = call ${Neighborhood}_private.getID( id );
    return node ? node->data_${Reflection} : G_default_node_${Neighborhood}.data_${Reflection};
  }
  
  event void UltrasonicRangingTransmitter.sendDone(result_t success) {
    //    call Leds.redToggle();
    if((++rangingSequenceNumber) <=
       G_Config.RangingParameters.numberOfRangingEstimates)
      call Timer.start(TIMER_ONE_SHOT,
		       G_Config.RangingParameters.successiveRangeDelay + (call Random.rand() & 127)) ;
    else
      post signalRangingDone();
  }

  event result_t UltrasonicRangingReceiver.receive(uint16_t actuator,
						   uint16_t receivedRangingId,
						   uint16_t sequenceNumber,
						   bool initiateRangingSchedule_) {
    if(state == STATE_LISTEN || state == STATE_RANGING) {
      state = STATE_BACKOFF;
      call UltrasonicRangingTransmitter.cancel();
      call Timer.stop();
      call Timer.start(TIMER_ONE_SHOT,
		       (G_Config.RangingParameters.numberOfRangingEstimates-
			sequenceNumber+1) *
		       (G_Config.RangingParameters.rangingPeriodEstimate + 64) + // 64 = half of randomness added to successive ranging delay
		       G_Config.RangingParameters.rangingPeriodFudgeFactor +
		       (call Random.rand() &
			G_Config.RangingStartDelay.rangingStartDelayMask));
    } 
    return SUCCESS;
  }


  /*  void swap(uint16_t *a, uint8_t i, uint8_t j) {
    uint16_t tmp = a[i];
    a[i] = a[j];
    a[j] = tmp;
  }
  
  uint8_t randomIndex(uint8_t i, uint8_t j) {
    return i + call Random.rand() % (j-i+1);
  }
  
  void quicksort(uint16_t *a, uint8_t left, uint8_t right) {
    uint8_t last = left, i;
    
    if (left >= right) return;
    
    swap(a,left,randomIndex(left,right));
    for (i = left + 1; i <= right; i++)
        if (a[i] < a[left])
      swap(a,++last,i);
    swap(a,left,last);
    quicksort(a,left,last-1);
    quicksort(a,last+1,right);
    }*/

void swap( uint16_t *x, uint16_t *y)
{
  uint16_t tmp;
  
  tmp = *x;
  *x = *y;
  *y = tmp;
}

void bubble(uint16_t a[], uint8_t n)
{
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
    
    //      quicksort(array, 0, len-1);
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

  uint16_t linearCalibration(uint16_t distance){
    /**  distance/scale - bias **/
    uint16_t scaledDistance = distance/G_Config.rangingScale;
    return scaledDistance>G_Config.rangingBias ? scaledDistance-G_Config.rangingBias : 0;
  }

  event void UltrasonicRangingReceiver.receiveDone(uint16_t actuator,
						   uint16_t receivedRangingId,
						   uint16_t distance) {
    ${Type} data;
    ${Neighborhood}_t* node;
    //    uint16_t i=0;

    //    call Leds.redToggle();
    if(distance > G_Config.UltrasoundFilterParameters.ultrasoundFilterLow &&
       distance < G_Config.UltrasoundFilterParameters.ultrasoundFilterHigh) { // filtering
      if(!call ${Neighborhood}.isNeighbor(actuator)){
	call addNeighbor(actuator);
	node = call ${Neighborhood}_private.getID(actuator );
	init_moving_window(&(node->data_RangingMovingWindowRefl), &(node->data_RangingWindowBufferRefl.buf[0]), &(node->data_RangingWindowBufferRefl.buf[RANGING_WINDOW_BUFFER_SIZE-1]));
      }
      node = call ${Neighborhood}_private.getID( actuator );
      if( node != 0 ) {
	distance = linearCalibration(distance);
	add_moving_window((moving_window_t*)&(node->data_RangingMovingWindowRefl), distance);
	data.distance=medianMinFilter((moving_window_t*)&(node->data_RangingMovingWindowRefl));
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
	//	addToEWMA(data.distance,&(node->data_EWMA${Reflection}));//added for EWMA
	//	node->data_${Reflection}.distance=node->data_EWMA${Reflection}.mean;//added for EWMA
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
    int i, recording;

    recording=0;
    /*    if( call DiagMsg.record() == SUCCESS ) { 
      call DiagMsg.uint8(TOS_LOCAL_ADDRESS);
      recording=1;
      } */
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
	//	addToEWMA(data.distance,&(node->data_EWMA${Reflection}));//added for EWMA
	//	node->data_${Reflection}.distance=data.distance;//added for EWMA
	node->data_RangingCountRefl = node->data_RangingCountRefl + 1;
	/*	if(recording){
	  call DiagMsg.uint8(args.neighbors[i].addr);
	  call DiagMsg.uint16(node->data_${Reflection}.distance);
	  }*/
      }
    }   
    /*    if(recording){
      call DiagMsg.send();
      }*/
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

    for(i=0;i<numberOfNeighbors;i++) {
      distance = report->neighbors[i].dist;
      if(report->neighbors[i].addr == ((uint8_t) TOS_LOCAL_ADDRESS) && distance > 0) {
	if(!call ${Neighborhood}.isNeighbor(sender)) {
	  call addNeighbor(sender);
	  node = call ${Neighborhood}_private.getID(sender);
	  init_moving_window(&(node->data_RangingMovingWindowRefl), &(node->data_RangingWindowBufferRefl.buf[0]), &(node->data_RangingWindowBufferRefl.buf[RANGING_WINDOW_BUFFER_SIZE-1]));
	  data.distance = distance;
	  data.stdv = G_Config.RangingParameters.rangingStdv;
	  if(call DiagMsg.record() == SUCCESS) {
	    call DiagMsg.str("new");
	    call DiagMsg.uint16(distance);
	    call DiagMsg.send();
	  }
	} else {
	  node = call ${Neighborhood}_private.getID(sender);
	  data = node->data_${Reflection};
	  if(node->data_RangingCountRefl < G_Config.rangingCountMin)
	    data.distance = distance;
	  else if(distance < data.distance)
	    data.distance = distance;
	  data.stdv = G_Config.RangingParameters.rangingStdv;
	  if(call DiagMsg.record() == SUCCESS) {
	    call DiagMsg.str("old");
	    call DiagMsg.uint16(distance);
	    call DiagMsg.uint16(node->data_RangingCountRefl);
	    call DiagMsg.send();
	  }
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
    rangingSequenceNumber = 1;
    batchNumber = 0;
    state = STATE_RANGING_ONCE;
    call Timer.start(TIMER_ONE_SHOT,
		     G_Config.RangingParameters.rangingPeriodEstimate);
    return SUCCESS;
  }

  command result_t RangingControl.range(uint8_t batchNumber_) {
    if(state == STATE_IDLE) {
      state = STATE_LISTEN;
      rangingSequenceNumber = 1;
      batchNumber = batchNumber_;
      call Timer.start(TIMER_ONE_SHOT,
		       G_Config.RangingStartDelay.rangingStartDelayBase
		       + (call Random.rand() &
		       G_Config.RangingStartDelay.rangingStartDelayMask));
    }
    return SUCCESS;
  }
  
  command result_t RangingControl.stop() {
    call Leds.redToggle();
    atomic{
      call Timer.stop();
      state=STATE_IDLE;
    }
    return SUCCESS;
  }

  command result_t RangingControl.reset() {
    call Timer.stop();
    state = STATE_IDLE;
    batchNumber = 0;
  }
}
