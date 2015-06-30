/* "Copyright (c) 2000-2002 The Regents of the University of California.  
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
// $Id: MagEstimationM.nc,v 1.1 2003/06/02 12:34:14 dlkiskis Exp $

includes common_structs;
includes MagHood;
includes TickSensor;
includes SensorDB;

//!! Neighbor 20 { MagHood_t mag; }

//!! Config 20 { uint16_t mag_threshold = 32; }
//!! Config 21 { uint16_t mag_movavg_timer_period = 64; }
//!! Config 22 { Ticks_t leader_quiet_ticks = 16; }
//!! Config 23 { Ticks_t reading_timeout_ticks = 16; }


module MagEstimationM
{
  provides
  {
    interface StdControl;
  }
  uses
  {
    interface U16Sensor;
    interface TickSensor;
    interface Timer;

    interface Config_mag_movavg_timer_period;
    interface Neighbor_mag;
    interface TupleStore;

    interface TimedLeds;
	interface Leds;

    interface EstimationComm;

	interface Pot;

	interface QueryProcessor;
#ifdef PC_DEBUG
	interface StdControl as UARTCommControl;
#endif
#ifdef PC_DEBUG_ME
	  interface Debug;
#endif
  }
}


#ifdef PC_DEBUG_ME
#ifndef PC
#define DEBUG(x)  \
   do {\
      call Debug.dbg8(0xa1);\
      call Debug.dbg8(x); \
   } while(0)
#define DEBUG2(x)  \
   do {\
      call Debug.dbg8(0xa2);\
      call Debug.dbg16(x); \
   } while(0)
#else
#define DEBUG(x) SDEBUG(x)
#define DEBUG2(x) SDEBUG(x)
#endif
#else
#define DEBUG(x)
#define DEBUG2(x)
#endif

implementation
{
  bool m_is_processing;    // TRUE if magnetometer is being processed
  uint16_t m_sensor_val;   // magnetometer sensor value

  typedef Pair_int16_t estimate_t;

  Ticks_t m_last_leader_time;
  TOS_Msg m_msg;
  bool m_is_sending;

  // The query that we use to initialize mag sensing
  ParsedQuery mag_query;
  ParsedQuery2 add_query;

  // Current query processing state
//  uint8_t mNodeState;

  //timer freq
  uint16_t mEpoch;
  uint16_t mTick;

  QueryResponse mQueryRsp;

#define  NUM_EPOCH_LEVEL 4

  uint8_t epoch_factor[NUM_EPOCH_LEVEL];


  Ticks_t backdate( Ticks_t now, Ticks_t delta )
  {
    return (now <= delta) ? 0 : (now - delta);
  }


  // This function is called when this node has read a sufficiently
  // high mag reading.  It checks with the other nodes in the
  // neighborhood to create an estimate.  It does an ad hoc leader
  // election based on who gets the highest reading, and that node
  // sends the estimate to the camera/base station.
  void check_estimate( Ticks_t now )
	{
	  const Neighbor_t* me = call TupleStore.getByAddress( TOS_LOCAL_ADDRESS );
	  TupleIterator_t ii = call TupleStore.initIterator();
	  int32_t x = 0;
	  int32_t y = 0;
	  int32_t mag_sum = 0;
	  Ticks_t oldest = backdate( now, G_Config.reading_timeout_ticks );

	  // quit if already sending
	  // quit if the bad bad bad happens
	  // quit if uninitialized location
	  // quit if our own reading has timed out
	  // quit if we've been the leader too recently
	  if( (m_is_sending == TRUE)
		  || (me == 0)
		  || (me->location.coordinate_system == 0)
		  || (me->mag.time < oldest)
		  || (backdate( now, G_Config.leader_quiet_ticks ) < m_last_leader_time)
		  )
		{
		  return;
		}

	  while( call TupleStore.getNext(&ii) == TRUE )
		{
		  // skip our own reading
		  if( ii.tuple->address == me->address )
			continue;

		  // do something if this neighbor has a valid location and mag val
		  if( (ii.tuple->location.coordinate_system != 0)
			  && (oldest <= ii.tuple->mag.time)
			  )
			{
			  // quit if this neighbor has a greater or eqivalent mag val as our own
			  if( me->mag.val <= ii.tuple->mag.val )
				return;
	
			  // val in the weighted location
			  x += ii.tuple->mag.val * ii.tuple->location.pos.x;
			  y += ii.tuple->mag.val * ii.tuple->location.pos.y;
			  mag_sum += ii.tuple->mag.val;
			}
		}

	  // if we got this far, incorporate our own mag val
	  x += me->mag.val * me->location.pos.x;
	  y += me->mag.val * me->location.pos.y;
	  mag_sum += me->mag.val;

	  // if we actually have a valid mag val, send out an estimate
	  if( mag_sum > 0 )
		{
		  Estimation_t estimate = {
		x : (x*256) / mag_sum,
		y : (y*256) / mag_sum,
		z : 0,
		  };
		  call EstimationComm.sendEstimation( &estimate );
		  m_last_leader_time = now;
		}
	}

  // This task is only spawned if a query is matched, i.e., if the
  // magnetometer reading exceeds the threshold.
  task void process_senses()
  {
    Ticks_t now = call TickSensor.get();
    MagHood_t mag = { val : m_sensor_val, time : now };

	call TimedLeds.redOn( 333 );
	call Neighbor_mag.set( TOS_LOCAL_ADDRESS, &mag );
	check_estimate( now );

    m_is_processing = FALSE;
  }


  command result_t StdControl.init()
  {
    m_is_processing = FALSE;
    m_last_leader_time = 0;
    m_is_sending = FALSE;
	//	mNodeState = MEMBER_IDLE;

	call Pot.set(0);
	call QueryProcessor.init(MEMBER);
#ifdef PC_DEBUG
	call UARTCommControl.init();
#endif

	mEpoch = 0;
	mTick = 0;
	epoch_factor[0] = 1;
	epoch_factor[1] = 4;
	epoch_factor[2] = 16;
	epoch_factor[3] = 64;


    return SUCCESS;
  }

  command result_t StdControl.start()
  {
	ConditionPtr conds_p = &mag_query.conds[0];

	mag_query.qtype = CT_QUERY;
	mag_query.qid =  1; 
	mag_query.qop =  QOP_SELECT;
	mag_query.epoch =  1;
	mag_query.qor = LOW;
	//	mag_query.qor_curv =  0;
	mag_query.attrib =  MAG;
	mag_query.aggOp =  NO;
	mag_query.numConds =  1;

	conds_p[0].attr = MAG;
	conds_p[0].op = GT;
	conds_p[0].val = 32;

	call Timer.start( TIMER_REPEAT, G_Config.mag_movavg_timer_period );

#ifdef PC_DEBUG
	call UARTCommControl.start();
#endif     

	DEBUG(0x01);
	call QueryProcessor.processQuery(&mag_query);

    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
	    call Timer.stop();
#ifdef PC_DEBUG
	call UARTCommControl.stop();
#endif

    return SUCCESS;
  }

  // This is where the magnetometer is read
  event result_t Timer.fired()
  {
	DEBUG(0x0f);
    return call U16Sensor.read();
  }

  // Process the magnetometer reading
//   event result_t U16Sensor.readDone( uint16_t val )
//   {
//     if( m_is_processing == FALSE )
//     {
//       m_is_processing = TRUE;
//       m_sensor_val = val;
//       post process_senses();
//     }
//     return SUCCESS;
//   }

  Tuple mTupleBuf;

  event result_t U16Sensor.readDone( uint16_t val )
	{
	  //	  uint8_t ii; 

	  if( m_is_processing == FALSE )
		{
		  m_is_processing = TRUE;
		  m_sensor_val = val;

		  // begin imported code
		  mTupleBuf.temp = val;

		  // Currently, we are ignoring the epochs.  This code needs
		  // to be put back in to handle different sampling
		  // frequencies.

		  mTick += epoch_factor[mEpoch]; //increase the minimum tick
		  //			  for(ii = NUM_EPOCH_LEVEL - 1; ii >= mEpoch; ii --) 
		  //				{
		  //				  if (mTick % epoch_factor[ii] == 0) 
		  //					{
		  //all queries in epoch of ii should be evaluated now
		  if (call QueryProcessor.processTuple(&mTupleBuf, 
											   1,
											   &mQueryRsp) 
			  == SUCCESS)
			{
			}
		  else
			{
			  m_is_processing = FALSE;
			  //			  DEBUG(0x43);
			}
		  //		  if (ii == (NUM_EPOCH_LEVEL - 1))
		  //			mTick = 0;

		  //no need to evaluate the queries at lower
		  //epoch, coz they are already included at higher
		  //level.
		  //					  break;
		  //					}
		  //		}
		}
	  else
		{
		  DEBUG(0x22);
		}
	  return SUCCESS;

	}


  event void Neighbor_mag.updatedFromRemote( uint16_t address )
  {
    Ticks_t now = call TickSensor.get();
    const Neighbor_t* nn = call TupleStore.getByAddress( address );
    if( nn != 0 )
    {
      MagHood_t mag = { val : nn->mag.val, time : now };
      call Neighbor_mag.set( address, &mag );
    }
  }


  event void Config_mag_movavg_timer_period.updated()
  {
    call Timer.stop();
    m_is_processing = FALSE;
	//	  DEBUG(0x55);
	//	  DEBUG(m_is_processing);
    call Timer.start( TIMER_REPEAT, G_Config.mag_movavg_timer_period );
  }

  //
  // Interaction with the Query Processor
  //

  event result_t QueryProcessor.processQueryComplete(ParsedQueryPtr query,
													 result_t result) 
	{

	  QueryResponse2 rsp2;
	  DEBUG(0x02);
	  // Currently, we're always using the MEMBER role.

	  // 	if(role == MEMBER) {
//  	  if(result == SUCCESS) {
//  		if(mNodeState == MEMBER_PROCESS_QUERY1)
//  		  mNodeState = MEMBER_IDLE;
//  	  }
	  // 	}
// 	else if(role == COOR) {
// 	  if(result == SUCCESS)
// 		call Network.sendParsedQuery(&mQueryMsgBuf, TOS_BCAST_ADDR);
// 	}

	// Send the type2 query that causes the previous query to be stored

	add_query.qtype = Q_QUERY;
	add_query.qid =  2; 
	add_query.qop =  QOP2_ADD_QUERY;
	add_query.qqid = 1;  // adding query 1

	DEBUG(0x03);
	if (call QueryProcessor.processQuery2(&add_query, &rsp2) == SUCCESS)
	  {
		DEBUG(0x04);
	  }
	else
	  {
		DEBUG(0x64);
	  }

	return SUCCESS;
  }

  event result_t QueryProcessor.processQuery2Complete(ParsedQuery2Ptr query2, 
													  QueryResponse2Ptr rsp2, 
													  result_t result) 
	{
	  // This old code sends the query response out over the network.
	  // We will need to add something like this back in as we add
	  // network transmission of queries.

// 	QueryResponse2Ptr qr;
// 	if(result == SUCCESS) {
// 	  if(mNodeState == MEMBER_PROCESS_QUERY2) {
// 		if(query2->qop == QOP2_ESTIMATE_OVERLAP) {
// 		  dbg(DBG_SDB, "type 2 query process complete, overlap = %d, nonoverlap = %d, about to send a response\n", rsp2->overlap, rsp2->nonoverlap);
// 		  qr = (QueryResponse2Ptr)&(mQuery2RspBuf.data);
// 		  dbg(DBG_SDB, "type 2 query process complete, overlap = %d, nonoverlap = %d, about to send a response\n", qr->overlap, qr->nonoverlap);
// 		  //DEBUG(qr->overlap);
// 		  //DEBUG(qr->nonoverlap);

// 		  call Network.sendQuery2Response(&mQuery2RspBuf);
// 		}
// 		else if(query2->qop == QOP2_ADD_QUERY) {
// 		  dbg(DBG_SDB, "type 2 query process complete, query %d added\n", query2->qqid);
		    
// 		  if(mEpoch == 0 || query2->new_epoch < mEpoch) {
// 			mEpoch = query2->new_epoch;
// 			if(mIsTimerOn) {
// 			  call Interrupt.disable();
// 			  call Timer.stop();
// 			  call Interrupt.enable();
// 			}
// 			call Timer.start(TIMER_REPEAT, epoch_factor[mEpoch] * 500);
// 			mIsTimerOn = TRUE;
// 		  }
		    
// 		  mNodeState = MEMBER_IDLE;
// 		}
// 		else if(query2->qop == QOP2_UPDATE_EPOCH) {
// 		  //DEBUG(18);
// 		  //DEBUG(18);
// 		  dbg(DBG_SDB, "type 2 query process complete, query %d updated\n", query2->qqid);
// 		  if(mEpoch == 0 || query2->new_epoch != mEpoch) {
// 			//DEBUG(66);
// 			//DEBUG(66);
// 			mEpoch = query2->new_epoch;
// 			if(mIsTimerOn) {
// 			  call Interrupt.disable();
// 			  call Timer.stop();
// 			  call Interrupt.enable();
// 			}
// 			call Timer.start(TIMER_REPEAT, epoch_factor[mEpoch] * 500);
// 			mIsTimerOn = TRUE;
// 			mTick = 0;
// 		  }
// 		  if(mMonitorState == NORMAL) 
// 			mMonitorState = AGILE;	
// 		  else if(mMonitorState = AGILE)
// 			mMonitorState = NORMAL;
// 		  mNodeState = MEMBER_IDLE;
// 		}
// 	  }
// 	}
//	  mNodeState = MEMBER_IDLE;
	  DEBUG(0x05);
	  return SUCCESS;
	}

  event result_t QueryProcessor.processTupleComplete(TuplePtr tuple, 
													 QueryResponsePtr rsp, 
													 result_t result) 
	{
	  // 	if(role == MEMBER) {

	  // If we matched 1 or more queries
	  if (rsp->numMatch > 0)
		{
		  // We should check the tuple and make sure it's a
		  // magnetometer reading, but since that's the only one we're
		  // processing, we don't bother.
		  m_sensor_val = rsp->data;
		  DEBUG(0x12);
		  DEBUG2(m_sensor_val);
		  post process_senses();
		}
	  else
		{
		  m_is_processing = FALSE;
		}
	  //		}
	  return SUCCESS;
	}


  event result_t QueryProcessor.postProcessQueryComplete(ParsedQuery2Ptr trigger) {
// 	if(role == COOR) {
// 	  if(mNodeState == COOR_POST_PROCESSQUERY1) {
// 		DEBUG(76);
// 		DEBUG(mMonitorState);
// 		DEBUG(76);
// 		if(trigger == 0) {
// 		  call Network.waitForQueryResponse();
// 		  mNodeState = COOR_IDLE;		  
// 		}
// 		else if(trigger->qop == QOP2_UPDATE_EPOCH) {
// 		  mNodeState = COOR_UPDATE_EPOCH;
// 		  //compose a type 2 query ask for estimate of overlap
// 		  dbg(DBG_SDB, "send type-2 query to update query epoch for query %d\n", trigger->qqid);
// 		  nmemcpy(&mQuery2MsgBuf.data, trigger, sizeof(ParsedQuery2));
// 		  mModQID = trigger->qqid;
// 		  call Network.sendQuery2(&mQuery2MsgBuf, TOS_BCAST_ADDR);
// 		}
// 		else if(trigger->qop == QOP2_ADD_TREND_QUERY && mMonitorState == AGILE) {
// 		  DEBUG(77);
// 		  DEBUG(mMonitorActiveCounter);
// 		  DEBUG(77);
// 		  mMonitorActiveCounter ++;
// 		  if(mMonitorActiveCounter > 10) {
// 			DEBUG(78);
// 			mNodeState = COOR_SEEK_TREND;
// 			mMonitorState = DETECTING;
// 			nmemcpy(&mQuery2MsgBuf.data, trigger, sizeof(ParsedQuery2));
// 			call Network.sendQuery2(&mQuery2MsgBuf, TOS_BCAST_ADDR);
// 		  }
// 		  else {
// 			mNodeState = COOR_IDLE;
// 			call Network.waitForQueryResponse(); //allow for response
// 		  }
// 		}
// 		else if(trigger->qop == QOP2_STOP_TREND_QUERY && mMonitorState == DETECTING) {
// 		  mNodeState = COOR_STOP_TREND;
// 		  mMonitorState = AGILE;
// 		  nmemcpy(&mQuery2MsgBuf.data, trigger, sizeof(ParsedQuery2));
// 		  call Network.sendQuery2(&mQuery2MsgBuf, TOS_BCAST_ADDR);
// 		}
// 		else { 
// 		  mNodeState = COOR_IDLE;
// 		  call Network.waitForQueryResponse();
// 		}

// 	  }
// 	}
	return SUCCESS;
  }



}

