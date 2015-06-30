includes Ext_AM;
includes NeighborStore;
module NeighborBeaconM {
  provides {
    interface StdControl;
    interface NeighborBeaconControl;
  }
  uses {
    interface Timer as BeaconTimer;
    interface Timer as TxManTimer;
    interface TxManControl;
    interface Enqueue;
    interface ReceiveMsg;
    interface ReadNeighborStore;
    interface WriteNeighborStore;
    interface Random;
    interface Leds;
  }
}
implementation
{
  /* description of module functions:
   *  - parse beacons from neighbors
   *  - write received metrics from neighbors to the NeighborStore
   *  - send beacons that contain neighbors and their relevant metrics
   *  - timeout neighbors' loss values and finally remove unresponsive ones
   */

  /* optimizations:
   * - start sending beacons after a random delay
   */
 
  #include "BeaconPacket.h"
  #include "NeighborBeacon.h"
  #include "msg_types.h"

  #undef NB_TESTING
  //#define NB_TESTING 

  struct LossData 
  {
    uint16_t neighborId;
    uint8_t numSilentPeriods;
  }  neighborCache[MAX_NUM_NEIGHBORS];

  typedef struct 
  {
    uint32_t lossBitmap;// 31 bits are used in this bitmap... the highest
			// bit is used to indicate if the window is full or
			// not; this is done to avoid the need for a
			// bitCount
    uint16_t endSeq;
    uint8_t incarnation;
  } __attribute__ ((packed))ExportedLossData; // packed to save space...
					      // alignment issues taken
					      // care of by the ordering
  
  ExportedLossData exportedData;
   
  uint8_t savedMsgInUse;
  uint8_t sendInProgress;
  uint8_t alpha; // expressed in percentage => 2bits of decimal
  uint8_t myIncarnation;
  uint8_t lossCalcIntervalCount;
  uint8_t length;
  NeighborIterator iterator;
  uint16_t mySeq;
  uint16_t beaconInterval;
  Ext_TOS_MsgPtr savedMsg;
  Ext_TOS_Msg recvBuffer;
  Ext_TOS_Msg sendBuffer;

  //uint16_t stopCount;

  command result_t StdControl.init()
  {
    //stopCount = 0;

    savedMsg = &recvBuffer;
    savedMsgInUse = 0;
    sendInProgress = 0;
    memset((char *)neighborCache, 0, sizeof(neighborCache));
    mySeq = 0;
    beaconInterval = BEACON_INTERVAL;
    alpha = DEFAULT_ALPHA;
    lossCalcIntervalCount = 0;
    iterator = 0;
    // set my incarnation to 0 always in case we don't want to take
    // advantage of the "incarnation" support... and just depend upon the
    // handling of sequence numbers outside the window...
    myIncarnation = 0;

#ifdef NB_TESTING
    call Random.init();
#endif
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    dbg(DBG_USR1, "NeighborBeaconM: starting timer with interval %d\n",
	beaconInterval);
    // for "nido"
    if (TOS_LOCAL_ADDRESS != 0)
    {
      call BeaconTimer.start(TIMER_REPEAT, beaconInterval);
    }
    call TxManTimer.start(TIMER_REPEAT, TXMAN_TICK_INTERVAL);
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call BeaconTimer.stop();
    return SUCCESS;
  }
 
  command result_t NeighborBeaconControl.setIncarnation(uint8_t incarnation)
  {
    myIncarnation = incarnation;
    return SUCCESS;
  }
  
  command result_t NeighborBeaconControl.setAlpha(uint8_t a)
  {
    alpha = a;
    return SUCCESS;
  }
  
  command result_t NeighborBeaconControl.setBeaconInterval(uint16_t period)
  {
    beaconInterval = period;
    call BeaconTimer.stop();
    call BeaconTimer.start(TIMER_REPEAT, beaconInterval);
    return SUCCESS;
  }
  
  // calculate total number of valid bits in the bitmap;
  // NOTE: the highest order bit is used to indicate whether or not the
  // bitmap is "full"... if it is 0 (meaning the bitmap is not full), the
  // bitmap is as long as position of the highest order bit set.  
  // NOTE: The maximum size of the bitmap is therefore 31 and not 32
  uint8_t bitmapSize(uint32_t bitmap)
  {
    uint8_t i;

    if (bitmap == 0)
    {
      return 0; // watch out for this case
    }

    if (bitmap & MS_BIT) // highest bit set
    {
      return BITMAP_SIZE; // read note above
    }
    else // the highest order bit is not set
    {
      // find the position of the highest one and return it
      bitmap <<= 1;
      for (i = 1; i < BITMAP_SIZE; i++)
      {
	if (bitmap & MS_BIT)
	{
	  return (BITMAP_SIZE + 1 - i);
	}
	bitmap <<= 1;
      }
    }
    return 0; // should never come here...
  }
  
  void calculateLossRate(uint16_t id)
  {
    result_t retVal;
    uint8_t i;
    uint8_t count;
    uint8_t numBits;
    uint16_t loss;
    uint16_t currLoss; 
    uint32_t bitmap;

    count = 0;

    if (id == 0)
    {
      // dbg();
      return;
    }

    length = sizeof(ExportedLossData);
    retVal = call ReadNeighborStore.getNeighborBlob(id, 
						    NS_BLOB_LOSS_STRUCT, 
						    (char *)&exportedData, 
						    &length);

    if (retVal == FAIL)
    {
      dbg(DBG_ERROR, "calculateLossRate: getNeighborBlob failed!\n");
      return;
    }
    
    // NOTE: the way the bitmap is used is thus: the highest bit indicates
    // if the window is "full" or not. 1 indicates that the bitmap window
    // is full -- meaning 31 bits.  0 indicates that the window is not yet
    // full and its length is given by the position of the highest 1
    bitmap = exportedData.lossBitmap;
    for (i = 0, numBits = 0; i < BITMAP_SIZE + 1; i++)
    {
      if (bitmap & 0x01)
      {
	count++;
	numBits = i + 1; // to count the highest 1 position
      }
      bitmap >>= 1; // right-shift by 1
    }
    if (numBits > BITMAP_SIZE)
    {
      numBits = BITMAP_SIZE; // due to the way the bitmap is used.
      count--; // to not count the "full" bit
    }
    if (numBits == 0) // sanity check
    {
      return;
    }

    currLoss = (uint16_t)(1000 - (((uint32_t)count * (uint32_t)1000) / 
			  (uint32_t)numBits));

    if (SUCCESS == call 
	ReadNeighborStore.getNeighborMetric16(id, NS_16BIT_IN_LOSS, &loss))
    {
      int16_t oldLoss;

      oldLoss = loss;
      loss = (uint16_t) (((uint32_t)currLoss * (uint32_t)alpha) / (uint32_t)100 + 
			 ((((uint32_t)loss) * (uint32_t)(100 - alpha)) / 
			  (uint32_t)100)); 
      dbg(DBG_USR3, "calcLoss: neighbor: %d, count: %d, numBits: %d, "
	  "currLoss: %d, oldLoss: %d, loss: %d\n", id, count, numBits,
	  currLoss, oldLoss, loss);
    }
    else
    {
      dbg(DBG_ERROR, "calculateLossRate: getNeighborMetric16 for "
	  "NS_16BIT_IN_LOSS failed!\n");
      loss = currLoss;
    }

    call WriteNeighborStore.setNeighborMetric16(id, NS_16BIT_IN_LOSS, loss);

    // important: reset bitmap
    exportedData.lossBitmap = 0;
    retVal = call WriteNeighborStore.setNeighborBlob(id, 
						     NS_BLOB_LOSS_STRUCT, 
						     (char *)&exportedData, 
						     length);

    if (retVal == FAIL)
    {
      dbg(DBG_ERROR, "calculateLossRate: setNeighborBlob failed!\n");
      return;
    }
  }
  
#if defined(PLATFORM_PC) && !defined(NDEBUG)
  char *intToBitmap(uint32_t num)
  {
    int i;
    static char numStr[33];

    for (i = 0; i < 32; i++)
    {
      if (num & MS_BIT)
      {
	numStr[i] = '1';
      }
      else
      {
	numStr[i] = '0';
      }
      num <<= 1;
    }
    numStr[32] = 0;

    return numStr;
  }
#else
  char * intToBitmap(uint32_t num);
#endif
  
  void updateNeighborSeq(uint16_t id, uint16_t seq, uint8_t incarnation)
  {
    uint8_t i;
    uint16_t diff;
    uint8_t bitmapFull;
    uint8_t retVal;
    
    // Find matching cache entry
    for (i = 0; i < MAX_NUM_NEIGHBORS; i++)
    {
      if (neighborCache[i].neighborId == id)
      {
	break;
      }
    }

    // coundn't find one..
    if (i == MAX_NUM_NEIGHBORS)
    {
      // is one free?
      dbg(DBG_USR2, "updateNeighbor: neighbor %d NOT found in cache\n", id);
      for (i = 0; i < MAX_NUM_NEIGHBORS; i++)
      {
	if (neighborCache[i].neighborId == 0)
	{

	  // to keep the table here and the table in the NeighborStore
	  // consistent...
	  exportedData.lossBitmap = 0x01;
	  exportedData.endSeq = seq;
	  exportedData.incarnation = incarnation;

	  dbg(DBG_USR2, "updateNeighbor: writing info about node %d to "
	      "store\n", id);
	  retVal = call 
		   WriteNeighborStore.setNeighborBlob(id, NS_BLOB_LOSS_STRUCT, 
						      (char *)&exportedData, 
						      sizeof(ExportedLossData));
	  if (retVal == SUCCESS)
	  {
	    // Yes... set the field in the array element
	    neighborCache[i].neighborId = id;
	    neighborCache[i].numSilentPeriods = 0;
	  }
	  else
	  {
	    dbg(DBG_USR1, "updateNeighbor: write to store failed\n");
	  }

	  return;
	}
      }
    }
    // none free, so bail out
    if (i == MAX_NUM_NEIGHBORS)
    {
      call WriteNeighborStore.removeNeighbor(id); // just in case...
      return;
    }

    // now, note that i points to a valid record for this neighbor

    length = sizeof(ExportedLossData);
    retVal = call ReadNeighborStore.getNeighborBlob(id, 
						    NS_BLOB_LOSS_STRUCT, 
						    (char *)&exportedData, 
						    &length);

    if (retVal == FAIL)
    {
      // to keep the table here and the table in the NeighborStore
      // consistent...
      dbg(DBG_ERROR, "updateNeighbor: getNeighborBlob FAILED 1!\n");
      exportedData.lossBitmap = 0x01;
      exportedData.endSeq = seq;
      exportedData.incarnation = incarnation;

      retVal = call 
		WriteNeighborStore.setNeighborBlob(id, NS_BLOB_LOSS_STRUCT, 
						  (char *)&exportedData, 
						  sizeof(ExportedLossData));

      neighborCache[i].numSilentPeriods = 0;

      // dbg...
      return;
    }
    else
    {
      dbg(DBG_USR2, "updateNeighbor: getNeighborBlob: bmp = %s, endSeq = %d"
	  " inc = %d\n", intToBitmap(exportedData.lossBitmap), 
	  exportedData.endSeq, exportedData.incarnation);
    }

    // is the seq number more recent? 
    if (SEQ_GT(seq, exportedData.endSeq) || 
        (incarnation > exportedData.incarnation) ||
        SEQ_ABS_DIFF(seq, exportedData.endSeq) >= SEQ_GAP_TOLERANCE)
    {
      if (incarnation > exportedData.incarnation)
      {
	// flush bitmap
	neighborCache[i].numSilentPeriods = 0;

	exportedData.incarnation = incarnation;
	exportedData.lossBitmap = 0x01;
	exportedData.endSeq = seq;

	length = sizeof(ExportedLossData);
	retVal = call WriteNeighborStore.setNeighborBlob(id,
						    NS_BLOB_LOSS_STRUCT,
						    (char *)&exportedData,
						    length);
	// check for retVal being FAIL...
	return;
      }

      // reset idle count
      neighborCache[i].numSilentPeriods = 0;

      diff = SEQ_ABS_DIFF(seq, exportedData.endSeq);

      if (diff > MIN(SEQ_GAP_TOLERANCE, BITMAP_SIZE))
      // this means that it is a (1) reboot  (2) or a long loss of
      // connectivity.. if it was the former, there is no loss penalty...
      // if it's the latter, ageing anyway would have taken care of it...
      // so be a little lax. 
      {
	exportedData.lossBitmap = 0; // flush the bitmap, effectively
        exportedData.endSeq = seq;

        dbg(DBG_USR1, "updateNeighbor: diff (%d) > SEQ_GAP_INTERVAL!! "
            "resetting\n", diff);
      }
      // usual case...
      else if (SEQ_GT(seq, exportedData.endSeq))
      {
	// update lossBitmap
	bitmapFull = 0;

	if (bitmapSize(exportedData.lossBitmap) + diff  >= BITMAP_SIZE)
	{
          dbg(DBG_USR1, "updateNeighbor: bitmap overflowed! bitmapSize = %d; diff = %d\n", bitmapSize(exportedData.lossBitmap), diff);
	  bitmapFull = 1;
	}
	exportedData.lossBitmap = exportedData.lossBitmap << diff | 0x01;
	if (bitmapFull)
	{
	  exportedData.lossBitmap |= MS_BIT;
	}
        exportedData.endSeq = seq;
      }
      // the other case that remains is if the seqNum rolled back
      // by less than SEQ_GAP_TOLERANCE... if so, we can't say if it's an
      // old beacon or a reboot... so, we just have to wait till the seq
      // num catches up... and we'll ignore it => a certain penalty is
      // paid through ageing, although it shouldn't be too much

    }
    retVal = call WriteNeighborStore.setNeighborBlob(id,
						     NS_BLOB_LOSS_STRUCT,
						     (char *)&exportedData,
						     length);
    dbg(DBG_USR2, "updateNeighbor: setNeighborBlob: bmp = %s, endSeq = %d"
	" inc = %d\n", intToBitmap(exportedData.lossBitmap), exportedData.endSeq,
	exportedData.incarnation);
    // check for retVal being zero...
    return;
  }

  void task processSavedMsg()
  {
    BeaconPacket *beacon;
    uint8_t itemCount;
    uint8_t dataOffset;
    uint16_t neighborId;
    uint16_t reportedLoss;
    result_t retVal;

    beacon = (BeaconPacket *)savedMsg->data;

    if (beacon->source == 0)
    {
      return;
    }
    
    dbg(DBG_USR1, "processSavedMsg: received msg from %d (%d); seq = %d; "
	"numRecords = %d\n", 
	beacon->source, savedMsg->saddr, beacon->seq, beacon->numRecords);

    updateNeighborSeq(beacon->source, beacon->seq, beacon->incarnation);
    
    dataOffset = sizeof(BeaconPacket);
    itemCount = 0;
    while ((itemCount < beacon->numRecords) && 
	   // sanity check to see if we are going to fall off 
	   // the data part of Ext_TOS_Msg
	   // 2 bytes for neighborId and 2 for metric
	   (dataOffset + 4 < savedMsg->length))
    {
      // 2 bytes for neighborId and 2 for metric
      // memcpy below is crucial
      memcpy((char *)&neighborId, &beacon->data[itemCount * 4], 2);
      memcpy((char *)&reportedLoss, &beacon->data[itemCount * 4 + 2], 2);

      dbg(DBG_USR1, "                 nId = %d loss = %d\n", 
	  neighborId, reportedLoss);
     
      // we care only about what that neighbor says about us 
      if (neighborId == TOS_LOCAL_ADDRESS)
      {
	retVal = call WriteNeighborStore.setNeighborMetric16(beacon->source, 
						  NS_16BIT_OUT_LOSS, 
						  reportedLoss);
	if (retVal == FAIL)
	{
	  dbg(DBG_ERROR, "processSavedMsg: setNeighborMetric16 FAILED for "
	      "neighbor %d\n", beacon->source);
	}
      }

      dataOffset += 4;
      itemCount++;
    }

    savedMsgInUse = 0;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr msg)
  {
    Ext_TOS_MsgPtr tmp;

    // for "nido" testing and debugging...
    if (0 == TOS_LOCAL_ADDRESS)
    {
      return msg;
    }

    dbg(DBG_USR1, "NeighborBeaconM.receive: received msg\n");
    tmp = (Ext_TOS_MsgPtr)msg;

    call Leds.greenToggle();
    if (! savedMsgInUse)
    {
      tmp = savedMsg;
      savedMsg = (Ext_TOS_MsgPtr)msg;
      savedMsgInUse = 1;
      post processSavedMsg();
    }

    return (TOS_MsgPtr)tmp;
  }

  // try just once more...
  void task resendBeacon()
  {
    if (FAIL == call Enqueue.enqueue(&sendBuffer))
    {
      dbg(DBG_ERROR, "resendBeacon: unable to send message\n");
      // beware: this can cause looping if TxMan is loaded...
      //post resendBeacon();
    }
    else
    {
      dbg(DBG_USR1, "resendBeacon: send succeeded\n");
    }

    call Leds.redToggle();
    sendInProgress = 0;
  }
  
  void task sendBeacon()
  {
    Ext_TOS_MsgPtr msgPtr;
    BeaconPacket *beacon;
    uint8_t offset;
    uint16_t id;
    uint16_t loss;
    uint8_t numNeighbors;

    // if buffer is being used down below, don't lose track of the fact
    // that it's time to send a beacon... so post myself...
    if (sendInProgress)
    {
      // dbg
      post sendBeacon();
      return;
    }
    
  #ifdef NB_TESTING
    // TODO: XXX REMOVE!!! random drops to aid testing.
    if (((call Random.rand()) & 0x0000000f) > 8) 
    // roughly 1/2 probability of drop
    {
      // effectively not send a beacon...
      dbg(DBG_USR1, "sendBeacon: not sending beacon %d\n", mySeq);
      mySeq++;
      return;
    }
  #endif

    msgPtr = &sendBuffer;
    beacon = (BeaconPacket *)(msgPtr->data);
    msgPtr->saddr = TOS_LOCAL_ADDRESS;
    msgPtr->addr = TOS_BCAST_ADDR; // broadcast
    msgPtr->group = NB_AM_GROUP;
    msgPtr->length = NB_MAX_PKT_SIZE; 
    msgPtr->type = MSG_NEIGHBOR_BEACON;
    // type will be set as in the configuration file...

    beacon->source = TOS_LOCAL_ADDRESS;
    beacon->seq = mySeq++;
    beacon->incarnation = myIncarnation;
    beacon->numRecords = 0;
    
    dbg(DBG_USR1, "sendBeacon: sending: myId = %d (%d), seq = %d\n", 
	beacon->source, msgPtr->saddr, mySeq);
    numNeighbors = call ReadNeighborStore.getNumNeighbors();
    offset = 0;
    while (sizeof(BeaconPacket) + offset + 4 < NB_MAX_PKT_SIZE &&
	   // this would make sure we don't add a neighbor more than once
	   beacon->numRecords < numNeighbors)
    {
      id = call ReadNeighborStore.getNextNeighbor(&iterator);
      if (id == 0)
      {
	// meaning there are no neighbors!!
	dbg(DBG_USR1, "sendBeacon: no neighbors\n");
	break;
      }

      if (FAIL == call ReadNeighborStore.getNeighborMetric16(id, 
							     NS_16BIT_IN_LOSS, 
							     &loss))
      {
	// shouldn't happen... since there was a preceding call to
	// getNextNeighbor...
	dbg(DBG_USR1, "sendBeacon: getNeighborMetric16 failed!\n");
	break;
      }

      // TODO: the real safe way of making sure that there are no duplicate
      // neighbor records in the beacon packet is to check if the records
      // so far don't already include the neighbor returned by
      // getNextNeighbor();

      // memcpy below is very important
      dbg(DBG_USR1, "            nId = %d, loss = %d\n", id, loss);
      memcpy(&beacon->data[offset], (char *)&id, 2);
      memcpy(&beacon->data[offset + 2], (char *)&loss, 2);
      offset += 4;
      beacon->numRecords++;
    }

    sendInProgress = 1;
    if (FAIL == call Enqueue.enqueue(msgPtr))
    {
      post resendBeacon();
    }
    else
    {
      call Leds.redToggle();
      sendInProgress = 0;
    }
    dbg(DBG_USR1, "sendBeacon: send succeeded\n");
  }

  void task ageNeighbors()
  {
    uint8_t i;
    uint16_t loss = 0;

    // increment numSilentPeriods
    for (i = 0; i < MAX_NUM_NEIGHBORS; i++)
    {
      if (neighborCache[i].neighborId == 0)
      {
	continue;
      }

      // increment number of silent periods for all... this will be reset
      // upon packet arrival 
      neighborCache[i].numSilentPeriods++;

      if (FAIL == 
	  call ReadNeighborStore.getNeighborMetric16(neighborCache[i].neighborId,
						     NS_16BIT_IN_LOSS, &loss))
      {
	// if no corresponding entry in the NeighborStore, remove cache
	// entry... readdition would anyway take care of adding in both the
	// cache and the NeighborStore
	memset((char *)&neighborCache[i], 0, sizeof(struct LossData));
	continue;
      }

      // if loss value is the limit... remove neighbor... the below code
      // would mean one time period of delay between hitting LOSS_MAX and
      // removing of the neighbor from cache and from store.
      if (loss >= LOSS_MAX)
      {
	// simple invalidation
	dbg(DBG_USR2, "ageNeighbors: removing neighbor = %d\n",
	    neighborCache[i].neighborId);
	call WriteNeighborStore.removeNeighbor(neighborCache[i].neighborId);
	memset((char *)&neighborCache[i], 0, sizeof(struct LossData));
	continue;
      }

      // if the neighbor hasn't responded in the last so many time periods
      // the ">" below is important... because if numSilentPeriods is 2, it
      // guarantees that there's only 1 period where nothing was heard.
      if (neighborCache[i].numSilentPeriods > AGE_SILENT_PERIOD_THRESHOLD)
      {
	// increment loss rate
	loss += AGE_LOSS_INCREMENT;
	if (loss > LOSS_MAX)
	{
	  loss = LOSS_MAX;
	}
	dbg(DBG_USR2, "ageNeighbors: incrementing loss for %d; new loss = %d\n",
	    neighborCache[i].neighborId, loss);
	// write it to store...
	call WriteNeighborStore.setNeighborMetric16(neighborCache[i].neighborId,
					     NS_16BIT_IN_LOSS, loss);
      }
    }
    
  }

  void task calculateAllLossRates()
  {
    int i;
    
    for (i = 0; i < MAX_NUM_NEIGHBORS; i++)
    {
      if ((neighborCache[i].neighborId != 0) &&
	  (neighborCache[i].numSilentPeriods <= LOSS_CALC_INTERVAL))
      // the second condition is to make sure that we have at least some
      // new packets and are not calculating the loss on previous data that
      // we've already used to calculate loss rate
      {
	{
	  ExportedLossData data;
	  uint8_t len;

	  call ReadNeighborStore.getNeighborBlob(neighborCache[i].neighborId, 
							  NS_BLOB_LOSS_STRUCT, 
							  (char *)&data, 
							  &len);
	  dbg(DBG_USR3, "calcLoss: neighbor: %d bmp: %s, endseq: %d, inc: %d\n",
	      neighborCache[i].neighborId, intToBitmap(data.lossBitmap), 
	      data.endSeq, data.incarnation);

	}

	calculateLossRate(neighborCache[i].neighborId);

	{
	  uint16_t in, out;
	  
	  call ReadNeighborStore.getNeighborMetric16(neighborCache[i].neighborId, 
						    NS_16BIT_IN_LOSS, &in);
	  call ReadNeighborStore.getNeighborMetric16(neighborCache[i].neighborId, 
						    NS_16BIT_OUT_LOSS, &out);
	  dbg(DBG_USR3, "          inLoss: %d, outLoss: %d\n",
	      in, out);
	}
      }
    }
  }
  
  // making sure that if TxManControl is not connected, it still compiles 
  // (as in the case where NeighborBeacon) is being used in an application 
  // that supplies its own TxManControl.tick(), you may not want to wire
  // the TxManControl of NeighborBeacon
  default command void TxManControl.tick()
  {
  }

  
  event result_t TxManTimer.fired()
  {
    call TxManControl.tick();
    return SUCCESS;
  }

  event result_t BeaconTimer.fired()
  {
    dbg(DBG_USR1, "BeaconTimer fired for node %d\n", TOS_LOCAL_ADDRESS);

#ifdef NB_TESTING
    //stopCount++;
    //TODO: remove
    /*
    if (stopCount == 28 && TOS_LOCAL_ADDRESS == 1)
    {
      mySeq = 0;
    }
    if (stopCount < 28 || stopCount > 30 || TOS_LOCAL_ADDRESS >= 2)
    */
#endif

    post sendBeacon();

    lossCalcIntervalCount++;
    if (lossCalcIntervalCount == LOSS_CALC_INTERVAL)
    {
      lossCalcIntervalCount = 0;
      post calculateAllLossRates();
    }
    post ageNeighbors();
    return SUCCESS;
  }
}
