/**
 * @author Robbie Adler
 **/

includes queue;

module ChannelManagerM{
  provides {
    interface ChannelManager;
    interface StdControl;
  }
  uses {
    interface ChannelParamsManager[uint8_t instance];
    interface DSPManager[uint8_t instance];
    interface BufferManagement;
    interface BoardManager;
    interface TriggerManager;
    interface Timer as ADCWarmupTimer;
    interface WriteData;
    interface WallClock;
#ifdef USE_UNIQUE_SEQUENCE_ID
    interface UniqueSequenceID;
    interface StdControl as UniqueSequenceIDControl;
#endif  
  }
}
implementation {

#include "frameworkconfig.h"
#include "sensorboard.h"
#include "paramtask.h"
  
#define WRAPPERHEADER_FIRSTOFFSET (12)
  
  typedef struct{
    uint32_t warmupTime;
    uint32_t requiredSize;
    uint32_t requestedSize;
    uint32_t samplingRate;
    uint32_t numSamples;
    uint8_t sampleWidth;
  }sampleInfo_t __attribute__((packed));

  typedef struct{
    uint32_t warmup;
    uint8_t *channelList;
    uint8_t numChannels;
  }channelList_t;
  
  sampleInfo_t gSampleInfo[TOTAL_DATA_CHANNELS];
  bool gPreparedChannelState[TOTAL_CHANNELS];
  bool bWarmupTimerRunning = FALSE;
  bool channelInProgress[TOTAL_DATA_CHANNELS];
  uint8_t gDataChannelPreparedChannel[TOTAL_DATA_CHANNELS];
  ptrqueue_t warmupTimeQueue;
  //we store a redundant copy of the sensor type in order to help keep the line between dependent and independent 
  //sampleHeader representations
  uint32_t gSensorTypes[TOTAL_DATA_CHANNELS];

  uint32_t gSequenceID;

  void signalDataReady(uint32_t arg);
  DEFINE_PARAMTASK(signalDataReady); 
  
  
  command result_t StdControl.init(){
    int i;
    
    //make sure that all of these ID's are initialized to FALSE
    for(i=0; i<TOTAL_DATA_CHANNELS; i++){
      channelInProgress[i] = FALSE;
      gDataChannelPreparedChannel[i] = INVALID_CHANNEL_ID;
    }
    
    initptrqueue(&warmupTimeQueue, defaultQueueSize);
#ifdef USE_UNIQUE_SEQUENCE_ID
    call UniqueSequenceIDControl.init();
#endif
    return SUCCESS;
  }
  
  command result_t StdControl.start(){
#ifdef USE_UNIQUE_SEQUENCE_ID
    call UniqueSequenceIDControl.start();
    if( (gSequenceID = call UniqueSequenceID.GetNextSequenceID()) == 0){
      trace(DBG_USR1,"ERROR:  UniqueSequenceID.GetNextSequenceID returned 0...sequences number is most likely not unique!!!\r\n");
    }
#else    
    gSequenceID = 0; //initialize just to make sure
#endif

    return SUCCESS;
  }

  command result_t StdControl.stop(){
    
    return SUCCESS;
  }
  
  /***********************************
this module is intended to manage the current set of channels.  It contains state information
that indicates whether a channel is ready to be run.
   
other purposes of this module:
-manage the sample header for the sensorboard.  It provide functions for a using module to determine
 the size of the sampleheader as well as function to write the sampleheader into a provided buffer
 the intent here is for the using module to never be aware of the implementation of the of the sampleheader
 so that we can minimize the dependence on the specific structure to allow for future modifications

  ***************/  
  
  bool isSamplingInProgress(uint8_t channel);
  result_t getDataChannelFromChannel(uint8_t channel, uint8_t *dataChannel);
  result_t getChannelFromDataChannel(uint8_t dataChannel, uint8_t *channel);
  result_t isSupportedSamplingRate(uint8_t channel, uint32_t samplingRate);  
  result_t isSupportedNumSamples(uint8_t channel, uint32_t numSamples);
  result_t isSupportedSampleWidth(uint8_t channel, uint8_t sampleWidth);
  result_t isSupportedStreaming(uint8_t channel, bool streaming);
  result_t isSupportedSensorType(uint8_t channel, uint32_t type);
  result_t isSupportedFunction(uint8_t channel, uint32_t function);

  command result_t ChannelManager.stopChannels(uint8_t numChannels, 
						uint8_t *channelList){
    
    uint32_t i;
    uint8_t *translatedChannelList;
    
    if(channelList == NULL){
      trace(DBG_USR1,"ChannelManager.stopChannels passed NULL channelList\r\n");
      return FAIL;
    }
    
    //check to make sure that all of the channels listed are a part of the same simultaneous sampling group
    //if our board's capabilities table is configured correctly and this function is used correctly, the
    //simulChannelGroup for all of the channels in our list should be the same
    for(i=1; i<numChannels; i++){
      if(dataChannelCapabilitiesTable[channelList[0]].simulChannelGroup != dataChannelCapabilitiesTable[channelList[i]].simulChannelGroup){
	trace(DBG_USR1,"FAIL:  GenericSampling.start requires that all started channels be a member of the same simultaneous sampling group\r\n");
	return FAIL;
      }
    }
    //all of the channels are part of the same simultaneous sampling group.
    
      //translate this list of channels to a list of data channels for the triggermanager!!!
    
    if((translatedChannelList = malloc(numChannels*sizeof(*translatedChannelList))) == NULL){
      trace(DBG_USR1,"ChannelManager.waitForData unable to allocate translated channel array\r\n");
      return FAIL;
    }
    MALLOC_DBG(__FILE__,"stopChannels",translatedChannelList,numChannels*sizeof(*translatedChannelList));
    
    for(i=0; i<numChannels; i++){
      getDataChannelFromChannel(channelList[i], &(translatedChannelList[i]));
    }
    
    call TriggerManager.cancelWaitForTrigger(numChannels, translatedChannelList);
      
    FREE_DBG(__FILE__,"stopChannel",translatedChannelList);
    free(translatedChannelList);
    return SUCCESS;
  }
  
  command result_t ChannelManager.startChannels(uint8_t numChannels, 
					uint8_t *channelList){
    
    
    uint32_t i,j;
#ifdef USE_UNIQUE_SEQUENCE_ID
    uint32_t nextUID;
#endif

    if(numChannels == 0){
      //this is an error
      trace(DBG_USR1,"FAIL:  GenericSamplng.start requires numChannels > 0\r\n");
      return FAIL;
    }
    
    if(channelList == NULL){
      trace(DBG_USR1,"ASSERT:  GenericSamplng.start passed NULL channelList\r\n");
    }
    
    //check to make sure that all of the channels listed are a part of the same simultaneous sampling group
    //if our board's capabilities table is configured correctly and this function is used correctly, the
    //simulChannelGroup for all of the channels in our list should be the same
    for(i=1; i<numChannels; i++){
      if(dataChannelCapabilitiesTable[channelList[0]].simulChannelGroup != dataChannelCapabilitiesTable[channelList[i]].simulChannelGroup){
	trace(DBG_USR1,"FAIL:  GenericSampling.start requires that all started channels be a member of the same simultaneous sampling group\r\n");
	return FAIL;
      }
    }
    //all of the channels are part of the same simultaneous sampling group.
    
    //Now, make sure that all of the channels have been prepared and that we're only starting a channel once
    for(i=0;i<numChannels; i++){
      uint8_t dataChannel;
      if(getDataChannelFromChannel(channelList[i], &dataChannel) == FAIL){
	trace(DBG_USR1,"FAIL:  GenericSampling.start unable to lookup dataChannel from sensor channel\r\n");
	return FAIL;
      }
      //now that we have the dataChannel, we need to set the warmup info for this datachannel
      if(call TriggerManager.setWarmupInfo(dataChannel,gSensorTypes[dataChannel]) == FAIL){
	trace(DBG_USR1,"FAIL:  GenericSampling.start unable to set Warmup Info for dataChannel %d\r\n",dataChannel);
	return FAIL;
      }
      
      if(gDataChannelPreparedChannel[dataChannel] != channelList[i]){
	//this channel was not actually prepared
	trace(DBG_USR1,"FAIL:  GenericSampling.start attempted to start unprepared channel %d\r\n",channelList[i]);
      }
      //make sure that we're only starting a channel once..should only have to look forward in the array
      for(j=i+1; j<numChannels; j++){
	if(channelList[i] == channelList[j]){
	  //we have a duplicate!
	  trace(DBG_USR1,"FAIL:  GenericSamplng.start attempting to start channel %d more than once\r\n", channelList[i]);
	  return FAIL;
	}
      }
    }
    
    //turn on the channels that we need to turn on...
    //this function operates on the original channel list instead of a translated list because the boardmanager
    //has intimate knowledge of the board and its channel mapping anyway
    if(call BoardManager.enableChannelsToBeSampled(numChannels, channelList) == FAIL){
      trace(DBG_USR1,"FAIL:  GenericSamplng.start unable to enable channel list to be sampled\r\n");
      return FAIL;
    }

#ifdef USE_UNIQUE_SEQUENCE_ID
    if( (nextUID = call UniqueSequenceID.GetNextSequenceID()) == 0){
      trace(DBG_USR1,"ERROR:  UniqueSequenceID.GetNextSequenceID returned 0...sequences number is not unique!!!\r\n");
      gSequenceID++;
    }
    else{
      gSequenceID = nextUID;
    }
#else    
    gSequenceID++;
#endif

    return SUCCESS;
  }
  
  event result_t BoardManager.enableChannelsToBeSampledDone(uint8_t numChannels,uint8_t *channelList){
    return signal ChannelManager.startChannelsDone(numChannels, channelList);
  }
  
  task void warmupTimerExpiredTask(){
    
    channelList_t *list;
    int status;

    //get the entry at the top of queue
    list = popptrqueue(&warmupTimeQueue,&status);
    if(status == 0){
      printFatalErrorMsg("ChannelManager:  Missing channelList in warmupTimerExpiredTask\r\n",0);
    }
        
    signal ChannelManager.warmupChannelsDone(list->numChannels, list->channelList);
    
    
    FREE_DBG(__FILE__,"warmupTimerExpiredTask",list->channelList);
    free(list->channelList);
    FREE_DBG(__FILE__,"warmupTimerExpiredTask",list);
    free(list);
    
    list = peekptrqueue(&warmupTimeQueue,&status);
    if(status == 1){
      trace(DBG_USR1,"Info:  warmupTimerExpiredTask found a concurrent warmup request\r\n");
      call ADCWarmupTimer.start(TIMER_ONE_SHOT,list->warmup/1000);
    }
  }
  
  event result_t ADCWarmupTimer.fired(){
    
    trace(DBG_USR1,"ADC Warmup timer expired...\r\n");
    bWarmupTimerRunning= FALSE;
    
    //not sure what happens if we request another one shot in the event for the previous 1
    post warmupTimerExpiredTask();
    
    return SUCCESS;
  }
  
  
  
  command result_t ChannelManager.warmupChannels(uint8_t numChannels, 
						 uint8_t *channelList){
    
    /********
     *This function needs to take the list of channels, calculate the
     * max warmup time required across all channels, start a timer 
     * for this warmup, and signal the warmupChannelsDone event when 
     * the timer has expired.
     *
     *********/
    int i;
    uint8_t dataChannel;
    uint32_t time, totalTime=0;
    channelList_t *newList;
    
    if(channelList == NULL){
      return FAIL;
    }
    
    for (i=0; i<numChannels; i++){
      if(getDataChannelFromChannel(channelList[i], &dataChannel) == FAIL){
	return FAIL;
      }
      time = gSampleInfo[dataChannel].warmupTime;
      if(time > totalTime){
	// this implies that we have a new max...store it
	totalTime = time;
      } 
      else{
	//ignore it...we already found our max
      }
    }
    trace(DBG_USR1,"INFO:  Total warmup time requested = %dms\r\n",totalTime/1000);
    
    
    
    assert((newList = malloc(sizeof(channelList_t))));
    MALLOC_DBG(__FILE__,"warmupChannels",newList,sizeof(channelList_t));
	   
    //got enough memory, now allocate the internal array so that we can copy state
    if( (newList->channelList = malloc(numChannels)) == NULL){
      //we didn't get the memory we need...deallocate and FAIL
      free(newList);
      FREE_DBG(__FILE__,"warmupChannels",newList);
      trace(DBG_USR1,"FATAL ERROR:  unable to allocate enough memory in warmupChannels\r\n");
      return FAIL;
    }
    MALLOC_DBG(__FILE__,"warmupChannels",newList->channelList,numChannels);
    //got our memory
    newList->warmup = totalTime;
    memcpy(newList->channelList,channelList,numChannels);
    newList->numChannels = numChannels;
    pushptrqueue(&warmupTimeQueue,newList);
    
    if(totalTime > 0){
      if(bWarmupTimerRunning){
	//already have a warmupTimer running...don't do anything.  We'll pull out the next
	//time request from the queue once the time hits
      }
      else{
	bWarmupTimerRunning = TRUE;
	call ADCWarmupTimer.start(TIMER_ONE_SHOT,totalTime/1000);
      } 
    }
    else{
      //no warmup time is requested:
      post warmupTimerExpiredTask();
    }
    return SUCCESS;
  }
  
  command result_t ChannelManager.prepareChannel(uint8_t channel, 
						 uint32_t samplingRate, 
						 uint32_t numSamples, 
						 uint8_t sampleWidth, 
						 bool streaming, 
						 uint32_t warmup, 
						 uint32_t type, 
						 uint32_t function, 
						 TypeValItem *other){
    
    
    uint32_t requiredSize, requestedSize, numRecords;
    size_t headerSize;
    uint8_t dataChannel;
    sampleInfo_t *pSi;

    if(isSamplingInProgress(channel)){
      trace(DBG_USR1,"FAIL:  GenericSampling.prepare called while sampling in progress for channel %d channel group\r\n",
	    channel);
      return FAIL;
    }
    
    //check out the supported sampling rates if we need to
    if(isSupportedSamplingRate(channel, samplingRate) == FAIL){
      trace(DBG_USR1,"Unsupported Sampling rate %d passed in\r\n",samplingRate);
      return FAIL;
    }
       
    if(isSupportedNumSamples(channel, numSamples) == FAIL){
      trace(DBG_USR1,"Unsupported Number of Samples %d passed in\r\n",numSamples);
      return FAIL;
    }
    
    if(isSupportedSampleWidth(channel, sampleWidth) == FAIL){
      trace(DBG_USR1,"Unsupported Sample Width %d passed in\r\n",sampleWidth);
      return FAIL;
    }
    
    //HACK!!  need to properly differentiate between the bit width of the sample and the bit width of the sample's storage
    sampleWidth = sampleWidth/8;
    
    if(isSupportedStreaming(channel, streaming)== FAIL){
      trace(DBG_USR1,"Streaming is not currently supported\r\n");
      return FAIL;
    }
    
    if(isSupportedSensorType(channel, type)== FAIL){
      trace(DBG_USR1,"Unsupported Sensor Type %d passed in\r\n",type);
      //print an error meesage here saying that we failed the sampling rate test
      return FAIL;
    }       
    
    if(isSupportedFunction(channel, function)==FAIL){
      trace(DBG_USR1,"Unsupported Post Processing Function %#x passed in\r\n",function);
      return FAIL;
    }
    
    if(getDataChannelFromChannel(channel, &dataChannel) == FAIL){
      return FAIL;
    }
    //make sure that this is a legit channel before we start using it
    assert(dataChannel < TOTAL_DATA_CHANNELS);
    
    //store the sensor type locally so that we can more easily retrieve it later
    gSensorTypes[dataChannel] = type;
    
    pSi = &gSampleInfo[dataChannel];

#ifdef DOCHUNKING
    if(DOCHUNKING){
      uint16_t numBuffers;
      
      numBuffers = numSamples/CHUNKSIZE;
      
      if((numBuffers*CHUNKSIZE) != numSamples){
	numBuffers++;
      }
      numSamples = numBuffers * CHUNKSIZE;
    }
#endif

    if(call ChannelParamsManager.storeParams[dataChannel](channel,
							  samplingRate, 
							  numSamples, 
							  sampleWidth, 
							  streaming, 
							  type, 
							  function, 
							  other) == FAIL){
      return FAIL;
    }
    
    if(call DSPManager.initPostProcessing[dataChannel](samplingRate, 
						       numSamples, 
						       sampleWidth, 
						       streaming, 
						       warmup, 
						       type, 
						       function, 
						       other) == FAIL){
      return FAIL;
    }
    //store warmuptime and get a buffer
    pSi->warmupTime = warmup;
    //now, get a dataBuffer for this acquisition
    headerSize = call ChannelParamsManager.getHeaderSize[dataChannel]();
    if(call DSPManager.getDataStorageSize[dataChannel](&requestedSize, &requiredSize, &numRecords) == SUCCESS){
       //DSPManager is alive and can give us some idea of how many bytes we need.
      //Now, we can adjust this paramater based on what our needs are 
      
      requestedSize += (numRecords * headerSize) + WRAPPERHEADER_FIRSTOFFSET; 
      requiredSize += (numRecords * headerSize) + WRAPPERHEADER_FIRSTOFFSET;  
    }
    else{
      //DSPManager for this channel doesn't do anything.  We need to estimate how much storage we need:
      
      //this is the size that we'd like the allocator to give us
      requestedSize = headerSize + WRAPPERHEADER_FIRSTOFFSET  + sampleWidth*numSamples;
      //this is the minimum size that the allocator can return to us
      requiredSize = headerSize + WRAPPERHEADER_FIRSTOFFSET  + sampleWidth;  
    }
    
    pSi->requestedSize = requestedSize;
    pSi->requiredSize = requiredSize;

    pSi->samplingRate = samplingRate;
    pSi->numSamples = numSamples;
    pSi->sampleWidth = sampleWidth;
    
    //mark the data channel as having been prepared with this external channel Id.
    //Note:  this is redundant information as the same exact piece of info should be
    //stored in the ChannelParamsManager.  However, we want to store this piece of
    //information here because it helps keep the line drawn between the "generic"
    //ChannelManager and the "sampleHeader specific ChannelParamsManager
    gDataChannelPreparedChannel[dataChannel] = channel;
    
    return SUCCESS;
  }

  command result_t ChannelManager.addTrigger(uint8_t boolOp, 
					     uint32_t triggerFunction,
					     float triggerValue, 
					     uint32_t triggerWindowSamples,
					     uint8_t triggerChannel,
					     uint8_t targetChannel){
    //translate channel id's...call TriggerManager
    uint8_t translatedTriggerChannel, translatedTargetChannel;

    getDataChannelFromChannel(targetChannel,&translatedTargetChannel);
    getDataChannelFromChannel(triggerChannel,&translatedTriggerChannel);
    
    return call TriggerManager.addTrigger(boolOp, 
					  triggerFunction, 
					  triggerValue,
					  triggerWindowSamples,
					  translatedTriggerChannel, 
					  translatedTargetChannel);
  }
  
  command void ChannelManager.clearTrigger(uint8_t targetChannel){
    //translate id..call TriggerManager
    uint8_t translatedTargetChannel;
    getDataChannelFromChannel(targetChannel,&translatedTargetChannel);
    
    return call TriggerManager.clearTrigger(translatedTargetChannel);
  }
    
  bool isSamplingInProgress(uint8_t channel){
    return (channelInProgress[channel]);
  }
      
  result_t getDataChannelFromChannel(uint8_t channel,uint8_t *dataChannel){
    const supportedCommonFeatureList32_t *feature;
    
    if(channel >= TOTAL_CHANNELS){
      return FAIL;
    }
               
    feature = channelCapabilitiesTable[channel].supportedSensorTypes;
    if((feature != NULL) && (dataChannel != NULL)){
      *dataChannel=feature->commonFeature;
      return SUCCESS;
    }
    else{
      return FAIL;
    }
  }
  
  result_t getChannelFromDataChannel(uint8_t dataChannel, uint8_t *channel){
    if(channel){
      *channel = gDataChannelPreparedChannel[dataChannel];
      return SUCCESS;
    }
    else{
      return FAIL;
    }
  }

  result_t isSupportedSamplingRate(uint8_t channel, uint32_t samplingRate){
    
    const supportedFeatureList32_t *feature;
    uint32_t i;
    
    feature = channelCapabilitiesTable[channel].supportedSamplingRates;
    if(feature != NULL){
      //channel only has has specific sampling rates that it supports
      //find if the support sampling rate is there
      for(i=0; i<feature->numElements; i++){
	if(feature->elements[i] == samplingRate){
	  return SUCCESS;
	}
      }
    }
    else{
      //we support all sampling rates
      return SUCCESS;
    }
    return FAIL;
  }
  
  result_t isSupportedNumSamples(uint8_t channel, uint32_t numSamples){
     return SUCCESS;
  }
      
  result_t isSupportedSampleWidth(uint8_t channel, uint8_t sampleWidth){
    const supportedFeatureList8_t *feature;
    uint32_t i;
    
    feature = channelCapabilitiesTable[channel].supportedSampleWidths;
    if(feature != NULL){
      //channel only has has specific sampling rates that it supports
      //find if the supported sampling width
      for(i=0; i<feature->numElements; i++){
	if(feature->elements[i] == sampleWidth){
	  return SUCCESS;
	}
      }
    }
    else{
      //we support all sampling widths
      return SUCCESS;
    }
    return FAIL;
  }
  
  result_t isSupportedStreaming(uint8_t channel, bool streaming){
    if(streaming == FALSE){
      return SUCCESS;
    }
    return FAIL;
  }
    
  result_t isSupportedSensorType(uint8_t channel, uint32_t type)  {
    const supportedCommonFeatureList32_t *feature;
    uint32_t i,element;
    
    
    feature = channelCapabilitiesTable[channel].supportedSensorTypes;
    if(feature != NULL){
      if(feature->numElements == 0){
	//special case to indicate that anything is supported
	return SUCCESS;
      }
      
      for(i=0; i<feature->numElements; i++){
	element = feature->elements[i];
	switch(GET_SENSOR_TYPE(element)){
	case SENSOR_ANALOG:
	  { 

	    uint32_t coupling, phytype, inputtype, range;
	    coupling = GET_ANALOG_COUPLING(type) & GET_ANALOG_COUPLING(element);
	    phytype = GET_ANALOG_PHYSICAL_TYPE(type) & GET_ANALOG_PHYSICAL_TYPE(element);
	    inputtype = GET_ANALOG_INPUT_TYPE(type) & GET_ANALOG_INPUT_TYPE(element);
	    range = GET_ANALOG_INPUT_RANGE(type) & GET_ANALOG_INPUT_RANGE(element);
	    if(coupling && phytype && inputtype && range){
	      return SUCCESS;
	    }
	  }
	  break;
	case SENSOR_DIGITAL:
	  {
	    uint32_t dtype;
	    dtype = GET_DIGITAL_TYPE(type) & GET_DIGITAL_TYPE(element);
	    if(dtype){
	      return SUCCESS;
	    }
	  }
	  return SUCCESS;
	  
	  break;
	default:
	  //unknown type:
	  break;
	}
      }
    }
    else{
      //FATAL ERROR!!
      return FAIL;
    }

    return FAIL;
  }  
  
  result_t isSupportedFunction(uint8_t channel, uint32_t function){
    uint8_t dataChannel;
    getDataChannelFromChannel(channel, &dataChannel);
    return call DSPManager.isSupportedFunction[dataChannel](function);
  }
    
  
  
#if 0
  void combineChannelMaps(channelMap_t *output, uint8_t mapindex){
    uint8_t temp;
    //selects just get or'd together
    output->selects = output->selects | channelIdMapOnTable[mapindex].selects;
    
    //enables get or'd togher except for VCC3_SENSOR_EN which is active low and needs to be and'd 
    temp = eGET(output->enables, VCC3_SENSOR_EN); 
    temp &= eGET(channelIdMapOnTable[mapindex].enables, VCC3_SENSOR_EN);   
    temp |= ~(1<<VCC3_SENSOR_EN);  //temp now has it's low bit the and of the two signals and all other bits 1's
    output->enables |= (channelIdMapOnTable[mapindex].enables & ~(1<<VCC3_SENSOR_EN));
    output->enables &= temp;
    
    return;
  }
  
  void copyChannelMap(channelMap_t *output, uint8_t mapindex){
    output->selects = channelIdMapOnTable[mapindex].selects; 
    output->enables = channelIdMapOnTable[mapindex].enables; 
  }
#endif 

  
  default command result_t DSPManager.initPostProcessing[uint8_t instance](uint32_t samplingRate, 
									   uint32_t numSamples, 
									   uint8_t sampleWidth, 
									   bool streaming, 
									   uint32_t warmup, 
									   uint32_t type, 
									   uint32_t function, 
									   TypeValItem *other){
    trace(DBG_USR1,"WARNING:  No DSPManager instance installed on datachannel %d\r\n",instance);
    return SUCCESS;
  }

  default command result_t DSPManager.isSupportedFunction[uint8_t instance](uint32_t function){
    if(function){
      return FAIL;
    }
    else{
      return SUCCESS;
    }
  }
  
  default command result_t DSPManager.getDataStorageSize[uint8_t instance](uint32_t *requestedSize, 
									   uint32_t *requiredSize,
									   uint32_t *numRecords){
    *requestedSize = 0;
    *requiredSize = 0;
    return FAIL;
  }

  event result_t TriggerManager.TriggeredData(uint8_t dataChannel,
					      uint8_t *buffer, 
					      float ADCScale,
					      float ADCOffset,
					      uint16_t numBytesWrite, 
					      uint16_t numBytesTotal, 
					      uint16_t numSamples,
					      uint64_t timestamp){
    
        
    call ChannelParamsManager.setNumSamples[dataChannel](numSamples);
    if( ((timestamp >> 32) & 0xFFFFFFFF) == 0xFFFFFFFF){
      //if upper 32 bits of the timetamps are all 1's, print an error
      trace(DBG_USR1,"ERROR:  Upper 32 bits of microsecond timestamp are all 1's\r\n");
    }
       
    call ChannelParamsManager.setMicroTimestamp[dataChannel](timestamp);
    call ChannelParamsManager.setWallTimestamp[dataChannel](call WallClock.getWallClock());
    call ChannelParamsManager.setADCScale[dataChannel](ADCScale);
    call ChannelParamsManager.setADCOffset[dataChannel](ADCOffset);
    call ChannelParamsManager.setSequenceID[dataChannel](gSequenceID);
    
    call ChannelParamsManager.writeSampleHeader[dataChannel](buffer);
    call ChannelParamsManager.incrementSampleOffset[dataChannel](numSamples);
        
    call WriteData.write(0, 
			 buffer, 
			 numBytesWrite);
      
    return SUCCESS;
  }
  
  event result_t TriggerManager.CollectionDone(uint8_t dataChannel){
    
    POST_PARAMTASK(signalDataReady, dataChannel);
    return SUCCESS;
  }
  
  void signalDataReady(uint32_t dataChannel){
    
    uint8_t channel;
    sampleInfo_t *pSi = &gSampleInfo[dataChannel];
    
    getChannelFromDataChannel(dataChannel,&channel);
    
    signal ChannelManager.DataReady(channel, pSi->numSamples, TRUE);
    
    return;
    
  }

  
  command result_t ChannelManager.waitForData(uint8_t numChannels, uint8_t *targetChannels){
    //translate this list of channels to a list of data channels for the triggermanager!!!
    uint8_t *translatedChannelList;
    int i;
    
    if(targetChannels == NULL){
      trace(DBG_USR1,"ChannelManager.waitForData passed NULL targetChannels pointer\r\n");
    }
    
    if((translatedChannelList = malloc(numChannels*sizeof(*translatedChannelList))) == NULL){
      trace(DBG_USR1,"ChannelManager.waitForData unable to allocate translated channel array\r\n");
      return FAIL;
    }
    MALLOC_DBG(__FILE__,"waitForData",translatedChannelList,numChannels*sizeof(*translatedChannelList));
    
    for(i=0; i<numChannels; i++){
      sampleInfo_t *pSi;
      uint8_t UOM;
      
      getDataChannelFromChannel(targetChannels[i], &(translatedChannelList[i]));
      pSi = &gSampleInfo[translatedChannelList[i]];
      call ChannelParamsManager.setSampleOffset[translatedChannelList[i]](0);
      if(call TriggerManager.setCollectionInfo(translatedChannelList[i], 
					    pSi->samplingRate, 
					    pSi->numSamples,
					    pSi->sampleWidth,
					    call ChannelParamsManager.getHeaderSize[translatedChannelList[i]](), 
						0) == FAIL){
	return FAIL;
      }
      
      if(call TriggerManager.getOutputUOM(translatedChannelList[i], &UOM) == SUCCESS){
	call ChannelParamsManager.setOutputUOM[translatedChannelList[i]](UOM);
      }
      else{
	return FAIL;
      }
    }
    
    if(call TriggerManager.waitForTrigger(numChannels, translatedChannelList,0) == FAIL){
      trace(DBG_USR1,"FATAL ERROR:  TriggerManger.waitForTrigger failed\r\n");
      return FAIL;
    }
    
    if(call BoardManager.startDataChannels(numChannels, translatedChannelList) == FAIL){
      trace(DBG_USR1,"FATAL ERROR:  TriggerManger.startDataChannels failed\r\n");
      return FAIL;
    }    
    
    FREE_DBG(__FILE__,"waitForData",translatedChannelList);
    free(translatedChannelList);
    return SUCCESS;
    
  }
  
  event result_t TriggerManager.waitForTriggerDone(uint8_t numChannels, 
						   uint8_t *targetChannels, 
						   result_t status){
    
    return SUCCESS;
  }

  event result_t WriteData.writeDone(uint8_t *data, uint32_t numBytesWrote, result_t status){
    
    //writedata completed
    //trace(DBG_USR1,"WriteData.write completed successfully..returning buffer!\r\n");
    call BufferManagement.ReleaseBuffer(data);
    //we are now officially done with our sampling activity...need to clean up state...
    
    return SUCCESS;
  }

}
