/**	
 * @author Robbie Adler	
 **/	
//includes profile;
includes queue;

module TriggerManagerM{
  provides{
    interface TriggerManager;
    interface StdControl;
#ifdef BLUSH_TRIGGER
    interface BluSH_AppI as ForceTrigger;
#endif
  
  }
  uses{
    interface SensorData as SensorData[uint8_t dataChannel];
    interface BufferManagement;
  }
}

implementation{
#include "frameworkconfig.h"
#include "triggerFunctions.h"
#include "triggerOps.h"
#include "paramtask.h"

  typedef struct{
    float triggerValue;
    uint32_t triggerFunction;
    uint32_t triggerWindowSamples;
    uint8_t triggerChannel;
    uint8_t boolOp;
    bool bInitialized;  //this field is for future support for optimizing trigger computation
  }triggerInfo_t;

  typedef struct{
    uint8_t numEntries;
    triggerInfo_t triggerInfo[TOTAL_DATA_CHANNELS];
  } triggerSet_t;
  
  typedef struct{
    uint8_t *dataBuffer;
    uint32_t totalAllocatedSize;
    uint32_t samplingRate; 
    uint32_t numSamples;
    int32_t numSamplesRemaining; //signed to avoid underflow
    uint32_t numBuffersNeeded;
    uint16_t headerSize; 
    uint16_t footerSize;
    uint8_t  sampleWidth;
    bool bDone;
    bool bStopped;
  }collectionInfo_t; 
  
  typedef struct{
    uint8_t *buffer;
    uint64_t timestamp;
    float ADCScale;
    float ADCOffset;
    uint32_t numSamples;
    uint8_t dataChannel;
  } bufferInfo_t;
  
  typedef struct{
    uint8_t dataChannelID;
    uint8_t *buffer;
  } triggerStatus_t; 
  
  typedef struct{
    bool bTriggered;
    bool bTriggerInstalled;
    uint8_t numStatusEntries;
    bufferInfo_t statusBufferInfo[TOTAL_DATA_CHANNELS]; //could be made more dynamic, but I'm going to be a little lazy
#ifdef DOPRETRIGGER
    uint8_t numPreTriggerEntries;
    bufferInfo_t preTriggerBufferInfo[TOTAL_DATA_CHANNELS]; //could be made more dynamic, but I'm going to be a little lazy
    bool bWrotePreTriggerBuffers;
#endif
    uint8_t numChannelEntries;
    uint8_t channelList[TOTAL_DATA_CHANNELS];
  } triggerWaitInfo_t;
  
  collectionInfo_t gCollectionInfo[TOTAL_DATA_CHANNELS];
  triggerSet_t gTriggerSet[TOTAL_DATA_CHANNELS];
  triggerWaitInfo_t *gTriggerWaitInfo[TOTAL_DATA_CHANNELS];
  queue_t bufferState[TOTAL_DATA_CHANNELS];
  
  uint8_t addToListNoDuplicates(uint8_t *list, uint8_t newEntry, uint8_t numCurrentEntries);
  uint8_t addToBufferInfoListNoDuplicates(bufferInfo_t *list, bufferInfo_t *pNewEntry, uint8_t numCurrentEntries);
  bool createBufferInfo(uint8_t dataChannel, bufferInfo_t *pBI);
  bool copyBufferInfo(bufferInfo_t *pDest, bufferInfo_t *pSrc);
  bool evalTrigger(triggerInfo_t *pTI, bufferInfo_t *pBI, bufferInfo_t *pBIPre);
  void clearOutWaitInfoBuffers(triggerWaitInfo_t *pTWI);
  void dispatchBufferInfo(uint8_t dataChannel, bufferInfo_t *pBI);  
  
  void processBuffer(uint32_t arg);
  DEFINE_PARAMTASK(processBuffer); 

  void printDataError(uint32_t arg);
  DEFINE_PARAMTASK(printDataError); 
  
  void printUnexpectedDataError(uint32_t arg);
  DEFINE_PARAMTASK(printUnexpectedDataError); 

  void CleanUpState(triggerWaitInfo_t *pTWI);
  void checkTrigger(triggerWaitInfo_t *pTWI);
  
  command result_t StdControl.init(){

    int i;
    
    for(i=0; i<TOTAL_DATA_CHANNELS; i++){
      initqueue(&(bufferState[i]), defaultQueueSize);
    }
        
    return SUCCESS;
  }
  
  command result_t StdControl.start(){
      
    return SUCCESS;
  }

  command result_t StdControl.stop(){
    
    return SUCCESS;
  }
  
  command result_t TriggerManager.addTrigger(uint8_t boolOp, 
					     uint32_t triggerFunction,
					     float triggerValue,
					     uint32_t triggerWindowSamples,
					     uint8_t triggerChannel,
					     uint8_t targetChannel){
    
    triggerSet_t *pts;
    int i;

    if (targetChannel >= TOTAL_DATA_CHANNELS){
      trace(DBG_USR1,"ERROR:  GenericSampling.AddTrigger passed targetChannel %d greater than NUMCHANNELS\r\n",targetChannel);
      return FAIL;
    }
    
    if (triggerChannel >= TOTAL_DATA_CHANNELS){
      trace(DBG_USR1,"ERROR:  GenericSampling.AddTrigger passed triggerChannel %d greater than NUMCHANNELS\r\n",triggerChannel);
      return FAIL;
    }

    trace(DBG_USR1,"INFO  GenericSampling.AddTrigger added channel %d (trigger channel) triggering channel %d (target channel)\r\n",triggerChannel, targetChannel);
    pts = &gTriggerSet[targetChannel];
   
    for(i=0;i<pts->numEntries; i++){
      //check to see if we already have an entry for this one and that the boolOp is the 
      //same for everything that we already know about
      if(pts->triggerInfo[i].boolOp != boolOp){
	trace(DBG_USR1,"ERROR:  GenericSampling.AddTrigger passed incosistent BoolOp value...ClearTrigger must be called first\r\n");
	return FAIL;
      }
      if(pts->triggerInfo[i].triggerChannel == triggerChannel){
	//if we already found an entry for this channel
	trace(DBG_USR1,"ERROR:  GenericSampling.AddTrigger passed redundant trigger channel %d\r\n", triggerChannel);
	return FAIL;
      }
      if((pts->numEntries + 1) > TOTAL_DATA_CHANNELS){
	//we will have too many entries if we add this one...
	trace(DBG_USR1,"FATAL ERROR:  GenericSampling.AddTrigger passed too many triggers\r\n");
	return FAIL;
      }
    }       

    pts->triggerInfo[pts->numEntries].triggerValue = triggerValue;
    pts->triggerInfo[pts->numEntries].triggerFunction = triggerFunction;
    pts->triggerInfo[pts->numEntries].triggerWindowSamples = triggerWindowSamples;
    pts->triggerInfo[pts->numEntries].triggerChannel = triggerChannel;
    pts->triggerInfo[pts->numEntries].boolOp = boolOp;
    pts->numEntries++;    
    
    return SUCCESS;
  }
  
  command void TriggerManager.clearTrigger(uint8_t targetChannel){
    gTriggerSet[targetChannel].numEntries = 0;
      
    return;
  }
  
  uint8_t addToBufferInfoListNoDuplicates(bufferInfo_t *list, bufferInfo_t *pNewEntry, uint8_t numCurrentEntries){
    int i;
    for(i=0; i<numCurrentEntries; i++){
	//brute force search for the newEntry;
      if(list[i].dataChannel == pNewEntry->dataChannel){
	break;
      }
    }
    if(i==numCurrentEntries){
      //didn't find the entry
      list[numCurrentEntries].dataChannel = pNewEntry->dataChannel;
      list[numCurrentEntries].timestamp = pNewEntry->timestamp;
      list[numCurrentEntries].buffer = pNewEntry->buffer;
      list[numCurrentEntries].numSamples = pNewEntry->numSamples;
      return (numCurrentEntries+1);
    }
    return numCurrentEntries;
  }

  uint8_t addToListNoDuplicates(uint8_t *list, uint8_t newEntry, uint8_t numCurrentEntries){
    int i;
    
    for(i=0; i<numCurrentEntries; i++){
	//brute force search for the newEntry;
      if(list[i] == newEntry){
	break;
      }
    }
    if(i==numCurrentEntries){
      //didn't find the entry
      list[numCurrentEntries] = newEntry;
      return (numCurrentEntries+1);
    }
    return numCurrentEntries;
  }

  bool copyBufferInfo(bufferInfo_t *pDest, bufferInfo_t *pSrc){
    if(!pDest){
      return FALSE;
    }
    if(!pSrc){
      return FALSE;
    }
    
    pDest->buffer = pSrc->buffer;
    pDest->timestamp = pSrc->timestamp;
    pDest->ADCScale = pSrc->ADCScale;
    pDest->ADCOffset = pSrc->ADCOffset;
    pDest->numSamples = pSrc->numSamples;
    pDest->dataChannel = pSrc->dataChannel;
 
    return TRUE;
  }

  bool createBufferInfo(uint8_t dataChannel, bufferInfo_t *pBI){
    if((dataChannel < TOTAL_DATA_CHANNELS) && (pBI != NULL)){
      collectionInfo_t *pCI= &gCollectionInfo[dataChannel];
      pBI->dataChannel = dataChannel;
      pBI->numSamples = pCI->numSamples;
      pBI->timestamp = 0; //initialize the timestamp to nothing
      pBI->buffer = NULL; //initialize the buffer to NULL
      return TRUE;
    }
    else{
      return FAIL;
    }
  }
  
  command result_t TriggerManager.getOutputUOM(uint8_t channel, uint8_t *pUOM){
    return call SensorData.getOutputUOM[channel](pUOM);
  }
  
  command result_t TriggerManager.waitForTrigger(uint8_t numChannels, 
						 uint8_t *targetChannels, 
						 uint32_t timeout){

    //we've received a list of triggers that we need to wait on as well as a timeout
    
    /**
     *
     * Steps:
     
     *  1.)  Loop:  {
     *      get target-
     *      -if target has triggers
     *      -add triggers to list if list doesn’t already have trigger
     *      -if target doesn’t have triggers
     *      -add target
     *      }
     *  2.) Start list
     *  3.) wait for all channels in list (this list must link back to actual wait list)
     *  4.) keep list of actual channels that are being waited on
     *  5.) eval trigger condition on each channel
     *      -request new data if necessary
     *  6.)if one trigger hits, write each one unless no writebit sit
     * 
     */
    
    int i;    
    triggerSet_t *pts;
    triggerWaitInfo_t * pTWI;
    bufferInfo_t BI;
    collectionInfo_t *pCI;
    
    //check to make sure that we don't have an outstanding entry on all of the channels that we're starting:
    for(i=0; i<numChannels; i++){
      if(gTriggerWaitInfo[targetChannels[i]]){
	trace(DBG_USR1,"FATAL ERROR:  Outstanding query remains on DATACHANNEL %d\r\n",targetChannels[i]);
	return FAIL;
      }
      assert(getCurrentQueueSize(&(bufferState[i])) == defaultQueueSize);
    }
    
    //allocate a new TriggerWaitInfo_t structure and store a pointer to it in each channel's entry;
    pTWI = calloc(1,sizeof(*pTWI));
    if(pTWI == NULL){
      trace(DBG_USR1,"FATAL ERROR:  TriggerManagerM unable to allocate memory for temp structure\r\n");
      return FAIL;
    }
    
    pTWI->numChannelEntries = numChannels;
    pTWI->bTriggered = TRUE;
    pTWI->bTriggerInstalled = FALSE;
#ifdef DOPRETRIGGER
    pTWI->bWrotePreTriggerBuffers = FALSE;
#endif
    
    for(i=0; i<numChannels; i++){
      gTriggerWaitInfo[targetChannels[i]] = pTWI; //keep a pointer to our allocated structure so that we can find it later
      pTWI->channelList[i] = targetChannels[i]; //copy the channel list so that we can use later
    }
       
    pTWI->numStatusEntries = 0;
    for(i=0; i<numChannels; i++){
      
      pts = &gTriggerSet[targetChannels[i]];
      
      if(pts->numEntries == 0){
	//we don't have triggers, so add this channel to the list so that we know to wait for it
	if(createBufferInfo(targetChannels[i], &BI)){
	  pTWI->numStatusEntries = addToBufferInfoListNoDuplicates(pTWI->statusBufferInfo,&BI,pTWI->numStatusEntries);
#ifdef DOPRETRIGGER
	  pTWI->numPreTriggerEntries = addToBufferInfoListNoDuplicates(pTWI->preTriggerBufferInfo,&BI,pTWI->numPreTriggerEntries);
#endif
	}
	else{
	  trace(DBG_USR1,"FATAL ERROR in TriggerManager.createBufferInfo\r\n");
	  CleanUpState(pTWI);
	  return FAIL;
	}
      }
      else{
	int j,k;
	//we have triggers...
	pTWI->bTriggered = FALSE;
	pTWI->bTriggerInstalled = TRUE;
	for(j=0;j<pts->numEntries; j++){
	  bool foundChannel=FALSE;
	  pts->triggerInfo[j].bInitialized = FALSE;
	  
	  //make sure that this triggers is part of our channel list
	  for (k=0; k<numChannels; k++){
	    if(pts->triggerInfo[j].triggerChannel == targetChannels[k]){
	      //we're starting this channel so it's ok to add the dependent channel to the list of channels to be started
	      foundChannel=TRUE;
	      if(createBufferInfo(pts->triggerInfo[j].triggerChannel, &BI)){
		pTWI->numStatusEntries = addToBufferInfoListNoDuplicates(pTWI->statusBufferInfo,&BI,pTWI->numStatusEntries);
#ifdef DOPRETRIGGER
		pTWI->numPreTriggerEntries = addToBufferInfoListNoDuplicates(pTWI->preTriggerBufferInfo,&BI,pTWI->numPreTriggerEntries);
#endif
		
	      }
	      else{
		trace(DBG_USR1,"FATAL ERROR in TriggerManager.createBufferInfo\r\n");
		CleanUpState(pTWI);
		return FAIL;
	      }
	    }
	  }
	  if(foundChannel == FALSE){
	    trace(DBG_USR1,"ERROR:  Channel %d depends on trigger channel that is not being started\r\n",targetChannels[i]);  
	    CleanUpState(pTWI);
	    return FAIL;
	  }
	}
      }
    }
    //we should now have a list of channels that should get started
       
    for(i=0;i<pTWI->numStatusEntries; i++){
      uint8_t *buffer;
      uint32_t numSamples;
      
      pCI= &gCollectionInfo[pTWI->statusBufferInfo[i].dataChannel];
      numSamples = pCI->numSamples;
      
#ifdef DOPRETRIGGER
      if(pTWI->bTriggered == TRUE){
	//implies that we don't have any triggers installed, so we can fix up our total samples required
	//and some other state
	
	//since we don't have any triggers installed, we should record that we already wrote the pretrigger buffers
	//since they won't actually exist as well as set the numPreTriggerEntries to zero just for housekeeping reasons

	//NOTE:  the pTWI entries just need to be done once. However, it's here just for convenience and code clarity.
	//compiler optimizations should correct later on if really necessary anyway
	pTWI->numPreTriggerEntries = 0;
	pTWI->bWrotePreTriggerBuffers = TRUE;

	if(pCI->numBuffersNeeded > 0){
	  pCI->numSamplesRemaining = (pCI->numBuffersNeeded)*pCI->numSamples;
	  pCI->numBuffersNeeded--;
	}
	else{
	  trace(DBG_USR1,"WARNING:  TriggerManager found unexpected number of buffersNeeded for PreTriggered query\r\n");
	}
      }
#endif
      
      buffer = call BufferManagement.AllocBuffer(pCI->totalAllocatedSize);
      if(buffer == NULL){
	trace(DBG_USR1,"FATAL ERROR:  Unable to allocate required buffer of size %d bytes\r\n", pCI->totalAllocatedSize);
	CleanUpState(pTWI);
	return FAIL;
      }
      
      pushqueue(&bufferState[pTWI->statusBufferInfo[i].dataChannel],(uint32_t) (buffer+pCI->headerSize));
      
      call SensorData.getSensorData[pTWI->statusBufferInfo[i].dataChannel](buffer+pCI->headerSize,pCI->numSamples);
    }
    return SUCCESS;
    
  }
  
  default event result_t TriggerManager.waitForTriggerDone(uint8_t numChannels, uint8_t *targetChannels, result_t status){
    return FAIL;
  }
  
  result_t isTriggered(uint8_t targetChannel){
    triggerWaitInfo_t *pTWI = gTriggerWaitInfo[targetChannel];
    
    if(pTWI == NULL){
      //if this check fails, it implies that we recently cleaned up state
      //of our collection, which implies that we had previously triggered
      return SUCCESS;
    }
    
    if(pTWI->bTriggered == TRUE){
      return SUCCESS;
    }
    else{
      return FAIL;
    }
  }
    
  bool storeBufferInfoAndCheckWaitInfo(triggerWaitInfo_t *pTWI, bufferInfo_t *pBI){
    int i;
    bool gotAllBuffers = TRUE;
    //find the buffer
    
//#ifdef DOPRETRIGGER
#if 0
    //rotate statusBuffer to PreTrigger
    if(pTWI->numStatusEntries != pTWI->numPreTriggerEntries){
      trace(DBG_USR1,"FATAL ERROR:  TriggerManager.storeBufferInfoAndCheckWaitInfo found inconsistent pretrigger/posttrigger buffer entry state\r\n");
      return FALSE;
    }
    
    for(i=0; i<pTWI->numStatusEntries; i++){
      if(pTWI->statusBufferInfo[i].dataChannel != pTWI->preTriggerBufferInfo[i].dataChannel){
      	trace(DBG_USR1,"FATAL ERROR:  TriggerManager.storeBufferInfoAndCheckWaitInfo found inconsistent pretrigger/posttrigger buffer channel state\r\n");
	return FALSE;
      }
      gotAllBuffers = gotAllBuffers & (pTWI->preTriggerBufferInfo[i].buffer != NULL);
    }
    
#endif
    
    for(i=0; i<pTWI->numStatusEntries; i++){
      if(pTWI->statusBufferInfo[i].dataChannel == pBI->dataChannel){
	//found our channel
	if(pTWI->statusBufferInfo[i].buffer == NULL){
	  if(copyBufferInfo(&pTWI->statusBufferInfo[i], pBI) == FALSE){
	    trace(DBG_USR1,"FATAL ERROR:  TriggerManager.copyBufferInfo failed\r\n");
	    return FALSE;
	  }
	}
	else{
	  trace(DBG_USR1,"FATAL ERROR:  TriggerManager.checkWaitInfo found an existing buffer where none was expected\r\n");
	}
      }
      gotAllBuffers = gotAllBuffers & (pTWI->statusBufferInfo[i].buffer != NULL);
    } 
        
    return gotAllBuffers;
  }
  
  void clearOutWaitInfoBuffers(triggerWaitInfo_t *pTWI){
    int i;
    
    for(i=0; i<pTWI->numStatusEntries; i++){
      pTWI->statusBufferInfo[i].buffer = NULL;
    }

    return;
  }
  
  void CleanUpState(triggerWaitInfo_t *pTWI){
    int i;
    
    for(i=0; i<pTWI->numChannelEntries; i++){
      gTriggerWaitInfo[pTWI->channelList[i]] = NULL;
    }
    FREE_DBG(__FILE__, "CleanUpState",pTWI);
    free(pTWI);
  }
  
  void checkCompletionAndCleanUpState(triggerWaitInfo_t *pTWI){
    int i;
    collectionInfo_t *pCI;
    bool bDone = TRUE;
    bool bStopped = TRUE;

    for(i=0; i<pTWI->numChannelEntries; i++){
      pCI = &gCollectionInfo[pTWI->channelList[i]];
      bDone &= (pCI->bDone);
    }

    for(i=0; i<pTWI->numChannelEntries; i++){
      pCI = &gCollectionInfo[pTWI->channelList[i]];
      bStopped &= (pCI->bStopped);
    }
    
    if( (bDone == TRUE)  && (bStopped == TRUE) ){
      
      for(i=0; i<pTWI->numChannelEntries; i++){
	signal TriggerManager.CollectionDone(pTWI->channelList[i]);
	trace(DBG_USR1,"TriggerManager:  signaling collectionDone for dataChannel %d\r\n", pTWI->channelList[i]);
      }
      
      trace(DBG_USR1,"TriggerManager:  Collection is finished and stopped...cleaning Up State\r\n");
      CleanUpState(pTWI);
    }
    return;
  }
 
  void processBuffer(uint32_t arg){
    bufferInfo_t *pBI = (bufferInfo_t *)arg;
    triggerWaitInfo_t *pTWI = gTriggerWaitInfo[pBI->dataChannel];
        
    //trace(DBG_USR1,"TriggerManager got Data from channel %d!\r\n",pBI->dataChannel);
    
    if(pTWI == NULL){
      collectionInfo_t *pCI = &gCollectionInfo[pBI->dataChannel];
      //this shouldn't happen...implies that we have inconsistent state in the system.
      trace(DBG_USR1,"WARNING:  processBuffer found NULL TWI pointer.  numBuffers needed = %d\r\n",pCI->numBuffersNeeded);
      pCI->numBuffersNeeded = 0;
      call BufferManagement.ReleaseBuffer(pBI->buffer - pCI->headerSize);
    }
    else{
      if(storeBufferInfoAndCheckWaitInfo(pTWI,pBI) == TRUE){
	//got all buffers that we need!!!
	//trace(DBG_USR1,"TriggerManager got Data from all waiting channels!\r\n");
	checkTrigger(pTWI);
	clearOutWaitInfoBuffers(pTWI);
	checkCompletionAndCleanUpState(pTWI);
      }
    }
    FREE_DBG(__FILE__,"processBuffer",pBI);
    free(pBI);
    return;
  }
  
  bool findStatusBufferInfo(triggerWaitInfo_t *pTWI, uint8_t dataChannel, bufferInfo_t **pBI){
    int i;

    for(i=0; i<pTWI->numStatusEntries; i++){
      if(pTWI->statusBufferInfo[i].dataChannel == dataChannel){
	*pBI = &(pTWI->statusBufferInfo[i]);
	return TRUE;
      }
    }
    return FALSE;
  }

#ifdef DOPRETRIGGER
  bool findPreTriggerBufferInfo(triggerWaitInfo_t *pTWI, uint8_t dataChannel, bufferInfo_t **pBIpre){
    int i;

    for(i=0; i<pTWI->numPreTriggerEntries; i++){
      if(pTWI->preTriggerBufferInfo[i].dataChannel == dataChannel){
	*pBIpre = &(pTWI->preTriggerBufferInfo[i]);
	return TRUE;
      }
    }
    return FALSE;
  }
#endif
  bool evalRMSPreTrigger8Int(triggerInfo_t *pTI, bufferInfo_t *pBI, bufferInfo_t *pBIpre);

  bool evalRMSPreTrigger8(triggerInfo_t *pTI, bufferInfo_t *pBI, bufferInfo_t *pBIpre){
    if( (pBI->ADCOffset == 0) && pBIpre->ADCOffset == 0){
      return evalRMSPreTrigger8Int(pTI, pBI, pBIpre);
    } 
    else{
      trace(DBG_USR1,"FATAL ERROR:  TriggerManager.evalRMS currently does not supported ADCOffset != 0 data\r\n");
      return FAIL;
    }
  }

  bool evalRMSPreTrigger8Int(triggerInfo_t *pTI, bufferInfo_t *pBI, bufferInfo_t *pBIpre){
    
    int32_t value32 = (int32_t)(pTI->triggerValue / pBI->ADCScale); 
    uint32_t windowLen = pTI->triggerWindowSamples;
    uint64_t targetValue = ((uint64_t)(value32 * value32)) * windowLen;

    int8_t *buffer8 = (int8_t *)pBI->buffer;
    int8_t *prebuffer8 = (int8_t *)pBIpre->buffer;
    

    uint64_t rmsTemp = 0;
    
    int i; 

#ifdef TRIGGER_DEBUG
    static int totalCount = 0;
    totalCount++;
#endif

    for(i=0; i<windowLen; i++){
      if(i < pBIpre->numSamples){
	rmsTemp += prebuffer8[i]*prebuffer8[i]; 
      }
      else{
	rmsTemp += buffer8[i-pBIpre->numSamples]*buffer8[i-pBIpre->numSamples]; 
      }
    }
    
    do{
      switch(pTI->triggerFunction){
      case TRIGGER_RMS_GT:
	if(rmsTemp > targetValue){
#ifdef TRIGGER_DEBUG
	  trace(DBG_USR1,"TriggerManager.evalTrigger found trigger condition at sample %d of acquisition for TRIGGER_RMS_GT query\r\n",((totalCount-1) * pBI->numSamples) + i-1);
	  totalCount = 0;
#endif
	  //we have evaluated WindowSamples worth of data and we've triggered
	  return TRUE;
	}
	break;
      case TRIGGER_RMS_LT:
	if(rmsTemp < targetValue){
#ifdef TRIGGER_DEBUG
	  trace(DBG_USR1,"TriggerManager.evalTrigger found trigger condition at sample %d of acquisition for TRIGGER_RMS_LT query\r\n",((totalCount-1) * pBI->numSamples) + i-1);
	  totalCount = 0;
#endif
	  //we have evaluated WindowSamples worth of data and we've triggered
	  return TRUE;
	}
	break;
      default:
	trace(DBG_USR1,"FATAL ERROR:  TriggerManager.evalRMS16 asked to evaluate unsupported trigger function %d\r\n",pTI->triggerFunction);
	return FALSE;
      }
      if((i-windowLen) < pBIpre->numSamples){
	rmsTemp -= prebuffer8[i-windowLen]*prebuffer8[i-windowLen];
      }
      else{
	rmsTemp -= buffer8[i-windowLen-pBIpre->numSamples]*buffer8[i-windowLen-pBIpre->numSamples];
      }
      if(i<pBIpre->numSamples){
	rmsTemp += prebuffer8[i]*prebuffer8[i];
      }
      else{
	rmsTemp += buffer8[i-pBIpre->numSamples]*buffer8[i-pBIpre->numSamples];
      }
      i++;
    }
    while(i<(pBI->numSamples + pBIpre->numSamples));
    return FALSE;
  }

  bool evalRMS8Int(triggerInfo_t *pTI, bufferInfo_t *pBI);
  bool evalRMS8(triggerInfo_t *pTI, bufferInfo_t *pBI){
    if(pBI->ADCOffset == 0){
      return evalRMS8Int(pTI, pBI);
    } 
    else{
      trace(DBG_USR1,"FATAL ERROR:  TriggerManager.evalRMS currently does not supported ADCOffset != 0 data\r\n");
      return FAIL;
    }
  }


  bool evalRMS8Int(triggerInfo_t *pTI, bufferInfo_t *pBI){
     int32_t value32 = (int32_t)(pTI->triggerValue / pBI->ADCScale);
     uint32_t windowLen = pTI->triggerWindowSamples;
     uint64_t targetValue = ((uint64_t)(value32 * value32)) *windowLen;
     
     int8_t *buffer8 = (int8_t *)pBI->buffer;
     uint64_t rmsTemp = 0;
     
     int i;
     
#ifdef TRIGGER_DEBUG
     static int totalCount = 0;
     totalCount++;
#endif


     for(i=0; i<windowLen; i++){
       rmsTemp += buffer8[i]*buffer8[i]; 
    }
    
     do{
      switch(pTI->triggerFunction){
      case TRIGGER_RMS_GT:
	if(rmsTemp > targetValue){
#ifdef TRIGGER_DEBUG
	  trace(DBG_USR1,"TriggerManager.evalTrigger found trigger condition at sample %d of acqusition for TRIGGER_RMS_GT query\r\n",((totalCount-1) *pBI->numSamples) + i-1);
	  totalCount = 0;
#endif
	  //we have evaluated WindowSamples worth of data and we've triggered
	  return TRUE;
	}
	break;
      case TRIGGER_RMS_LT:
	if(rmsTemp < targetValue){
#ifdef TRIGGER_DEBUG
	  trace(DBG_USR1,"TriggerManager.evalTrigger found trigger condition at sample %d of acquisition for TRIGGER_RMS_LT query\r\n",((totalCount-1) * pBI->numSamples) + i-1);
	  totalCount = 0;
#endif
	  //we have evaluated WindowSamples worth of data and we've triggered
	  return TRUE;
	}
	break;
      default:
	trace(DBG_USR1,"FATAL ERROR:  TriggerManager.evalRMS8 asked to evaluate unsupported trigger function %d\r\n",pTI->triggerFunction);
	return FALSE;
      }
      
      rmsTemp -= buffer8[i-windowLen]*buffer8[i-windowLen];
      rmsTemp += buffer8[i]*buffer8[i];
      i++;
     }
     while(i<pBI->numSamples);
    return FALSE;
  }

  bool evalRMSPreTrigger16Int(triggerInfo_t *pTI, bufferInfo_t *pBI, bufferInfo_t *pBIpre);
  bool evalRMSPreTrigger16(triggerInfo_t *pTI, bufferInfo_t *pBI, bufferInfo_t *pBIpre){
    if( (pBI->ADCOffset == 0) && pBIpre->ADCOffset == 0){
      return evalRMSPreTrigger16Int(pTI, pBI, pBIpre);
    } 
    else{
      trace(DBG_USR1,"FATAL ERROR:  TriggerManager.evalRMS currently does not supported ADCOffset != 0 data\r\n");
      return FAIL;
    }
  }

  bool evalRMSPreTrigger16Int(triggerInfo_t *pTI, bufferInfo_t *pBI, bufferInfo_t *pBIpre){
    int32_t value32 = (int32_t)(pTI->triggerValue / pBI->ADCScale); 
    uint32_t windowLen = pTI->triggerWindowSamples;
    uint64_t targetValue =  ((uint64_t)(value32 * value32)) * windowLen;

    int16_t *buffer16 = (int16_t *)pBI->buffer; 
    int16_t *prebuffer16 = (int16_t *)pBIpre->buffer; 
    
    
    static uint64_t rmsTemp = 0;
    
    int i;  
    
#ifdef TRIGGER_DEBUG
    static int totalCount = 0;
    totalCount++;
#endif
    
    rmsTemp = 0;
    for(i=0; i<windowLen; i++){
      if(i < pBIpre->numSamples){
	rmsTemp += prebuffer16[i]*prebuffer16[i]; 
      }
      else{
	  rmsTemp += buffer16[i-pBIpre->numSamples]*buffer16[i-pBIpre->numSamples]; 
      }
    }
      
    do{
      switch(pTI->triggerFunction){
      case TRIGGER_RMS_GT:
	if(rmsTemp > targetValue){
#ifdef TRIGGER_DEBUG
	  trace(DBG_USR1,"TriggerManager.evalTrigger found trigger condition at sample %d of acquisition for TRIGGER_RMS_GT query\r\n",((totalCount-1) *pBI->numSamples) + i-1);
	  totalCount = 0;
#endif
	  //we have evaluated WindowSamples worth of data and we've triggered
	  return TRUE;
	}
	break;
      case TRIGGER_RMS_LT:
	if(rmsTemp < targetValue){
#ifdef TRIGGER_DEBUG
	  trace(DBG_USR1,"TriggerManager.evalTrigger found trigger condition at sample %d of acquisition for TRIGGER_RMS_LT query\r\n",((totalCount-1) * pBI->numSamples) + i-1);
	  totalCount = 0;
#endif
	  //we have evaluated WindowSamples worth of data and we've triggered
	  return TRUE;
	}
	break;
      default:
	trace(DBG_USR1,"FATAL ERROR:  TriggerManager.evalRMS16 asked to evaluate unsupported trigger function %d\r\n",pTI->triggerFunction);
	return FALSE;
      }
      if((i-windowLen) < pBIpre->numSamples){
	rmsTemp -= prebuffer16[i-windowLen]*prebuffer16[i-windowLen];
      }
      else{
	rmsTemp -= buffer16[i-windowLen-pBIpre->numSamples]*buffer16[i-windowLen-pBIpre->numSamples];
      }
      if(i<pBIpre->numSamples){
	rmsTemp += prebuffer16[i]*prebuffer16[i];
      }
      else{
	rmsTemp += buffer16[i-pBIpre->numSamples]*buffer16[i-pBIpre->numSamples];
      }
      i++;
    }
    while(i<(pBI->numSamples + pBIpre->numSamples));
    return FALSE;
  }
  
  
  bool evalRMS16Int(triggerInfo_t *pTI, bufferInfo_t *pBI);
  bool evalRMS16(triggerInfo_t *pTI, bufferInfo_t *pBI){
    if(pBI->ADCOffset == 0){
      return evalRMS16Int(pTI, pBI);
    } 
    else{
      trace(DBG_USR1,"FATAL ERROR:  TriggerManager.evalRMS currently does not supported ADCOffset != 0 data\r\n");
      return FAIL;
    }
  }

  bool evalRMS16Int(triggerInfo_t *pTI, bufferInfo_t *pBI){
    int32_t value32 = (int32_t)(pTI->triggerValue / pBI->ADCScale); 
    uint32_t windowLen = pTI->triggerWindowSamples;
    uint64_t targetValue = ((uint64_t)(value32 * value32)) * windowLen;

    int16_t *buffer16 = (int16_t *)pBI->buffer; 

    uint64_t rmsTemp = 0;
    int i;
    
#ifdef TRIGGER_DEBUG
    static int totalCount = 0;
    totalCount++;
#endif
    
    //initialize our calculation
    for(i=0; i<windowLen; i++){
      rmsTemp += buffer16[i]*buffer16[i]; 
    }
    
    do{
      switch(pTI->triggerFunction){
      case TRIGGER_RMS_GT:
	if(rmsTemp > targetValue){
#ifdef TRIGGER_DEBUG
	  trace(DBG_USR1,"TriggerManager.evalTrigger found trigger condition at sample %d of acquisition for TRIGGER_RMS_GT query\r\n",((totalCount-1) * pBI->numSamples) + i-1);
	  totalCount = 0;
#endif
	  //we have evaluated WindowSamples worth of data and we've triggered
	  return TRUE;
	}
	break;
      case TRIGGER_RMS_LT:
	if(rmsTemp < targetValue){
#ifdef TRIGGER_DEBUG
	  trace(DBG_USR1,"TriggerManager.evalTrigger found trigger condition at sample %d of acquisition for TRIGGER_RMS_LT query\r\n",((totalCount-1) * pBI->numSamples) + i-1);
	  totalCount = 0;
#endif
	  //we have evaluated WindowSamples worth of data and we've triggered
	  return TRUE;
	}
	break;
      default:
	trace(DBG_USR1,"FATAL ERROR:  TriggerManager.evalRMS16 asked to evaluate unsupported trigger function %d\r\n",pTI->triggerFunction);
	return FALSE;
      }
      
      rmsTemp -= buffer16[i-windowLen]*buffer16[i-windowLen];
      rmsTemp += buffer16[i]*buffer16[i];
      i++;
    }
    while(i<pBI->numSamples);
    return FALSE;
  }


  bool evalTrigger(triggerInfo_t *pTI, bufferInfo_t *pBI, bufferInfo_t *pBIpre){
    int i, windowCount = 0;
    collectionInfo_t *pCI = &(gCollectionInfo[pBI->dataChannel]);
    uint8_t width = pCI->sampleWidth;
    
    //needs to be f(ADCScale, ADCOffset)
    int8_t value8 = (int8_t)(pTI->triggerValue / pBI->ADCScale);
    int16_t value16 = (int16_t)(pTI->triggerValue / pBI->ADCScale); 
    
    int8_t *buffer8 = (int8_t *)pBI->buffer;
    int16_t *buffer16 = (int16_t *)pBI->buffer; 
 
#ifdef DOPRETRIGGER   
    int8_t *prebuffer8;
    int16_t *prebuffer16;
#endif
    
    uint32_t windowLen = pTI->triggerWindowSamples;
    
#ifdef TRIGGER_DEBUG
    static int totalCount = 0;
#endif


#ifdef DOPRETRIGGER
    if(pBIpre->buffer == NULL){
      //don't even bother evaluating if we're in pretrigger mode but haven't gotten our pretrigger buffer yet
      return FALSE;
    }
    
    prebuffer8 = (int8_t *)pBIpre->buffer;
    prebuffer16 = (int16_t *)pBIpre->buffer; 

    if(windowLen > pBIpre->numSamples){
      trace(DBG_USR1,"FATAL ERROR in TriggerManager.evalTrigger:  triggerWindowSamples > preTrigger numSamples\r\n");
      return FALSE;
    }
	
#endif

#ifdef TRIGGER_DEBUG
    //increment here to make sure that we don't accidentlally increment 1 extra time due to pretrigger initialization condition
    totalCount++;
#endif

    
#ifndef DOPRETRIGGER
    if(windowLen > pBI->numSamples){
      trace(DBG_USR1,"FATAL ERROR in TriggerManager.evalTrigger:  triggerWindowSamples > numSamples\r\n");
      return FALSE;
    }
#endif

    switch(width){
    case 1:
      break;
    case 2:
      break;
    case 6:
      break;
    default:
      trace(DBG_USR1,"FATAL ERROR in TriggerManager.evalTrigger:  Unknown sample width %d\r\n",width);
      return FALSE;
    }
        
    switch(pTI->triggerFunction){
    case TRIGGER_GT:
#ifdef DOPRETRIGGER
      for(i=0; i<pBIpre->numSamples; i++){
	switch(width){
	case 1:
	  if(prebuffer8[i] > value8){
	    windowCount++;
	  }
	  else{
	    windowCount=0;
	  }
	  break;  
	case 2:
	  if(prebuffer16[i] > value16){
	    windowCount++;
	  }
	  else{
	    windowCount=0;
	  }
	  break;
	case 6:
	  if(prebuffer16[i] > value16){
	    windowCount++;
	  }
	  else{
	    windowCount=0;
	  }
	  break;
	}
	if(windowCount >= windowLen){
#ifdef TRIGGER_DEBUG
	  trace(DBG_USR1,"TriggerManager.evalTrigger found trigger condition at sample %d of acqusition for TRIGGER_GT query\r\n",((totalCount-1) *pBI->numSamples) + i);
	  totalCount = 0;
#endif
	  return TRUE;
	}
      }
#endif
      for(i=0; i<pBI->numSamples; i++){
	switch(width){
	case 1:
	  if(buffer8[i] > value8){
	    windowCount++;
	  }
	  else{
	    windowCount=0;
	  }
	  break;  
	case 2:
	  if(buffer16[i] > value16){
	    windowCount++;
	  }
	  else{
	    windowCount=0;
	  }
	  break;
	case 6:
	  if(buffer16[i] > value16){
	    windowCount++;
	  }
	  else{
	    windowCount=0;
	  }
	  break;
	}
	if(windowCount >= windowLen){
#ifdef TRIGGER_DEBUG
	  trace(DBG_USR1,"TriggerManager.evalTrigger found trigger condition at sample %d of acqusition for TRIGGER_GT query\r\n",((totalCount) *pBI->numSamples) + i);
	  totalCount = 0;
#endif
	  return TRUE;
	}
      }
      break;
    case TRIGGER_LT:
#ifdef DOPRETRIGGER
      for(i=0; i<pBIpre->numSamples; i++){
	switch(width){
	case 1:
	  if(prebuffer8[i] < value8){
	    windowCount++;
	  }
	  else{
	    windowCount=0;
	  }
	  break;  
	case 2:
	  if(prebuffer16[i] < value16){
	    windowCount++;
	  }
	  else{
	    windowCount=0;
	  }
	  break;
	case 6:
	  if(prebuffer16[i] < value16){
	    windowCount++;
	  }
	  else{
	    windowCount=0;
	  }
	  break;
	}
	
	if(windowCount >= windowLen){
#ifdef TRIGGER_DEBUG
	  trace(DBG_USR1,"TriggerManager.evalTrigger found trigger condition at sample %d of acqusition for TRIGGER_LT query\r\n",((totalCount-1) *pBI->numSamples) + i);
	  totalCount = 0;
#endif
	  return TRUE;
	}
      }
#endif
      for(i=0; i<pBI->numSamples; i++){
	switch(width){
	case 1:
	  if(buffer8[i] < value8){
	    windowCount++;
	  }
	  else{
	    windowCount=0;
	  }
	  break;  
	case 2:
	  if(buffer16[i] < value16){
	    windowCount++;
	  }
	  else{
	    windowCount=0;
	  }
	  break;
	case 6:
	  if(buffer16[i] < value16){
	    windowCount++;
	  }
	  else{
	    windowCount=0;
	  }
	  break;
	}
	
	if(windowCount >= windowLen){
#ifdef TRIGGER_DEBUG
	  trace(DBG_USR1,"TriggerManager.evalTrigger found trigger condition at sample %d of acqusition for TRIGGER_LT query\r\n",((totalCount) *pBI->numSamples) + i);
	  totalCount = 0;
#endif
	  return TRUE;
	}
      }
      break;
    case TRIGGER_ABSOLUTE_GT:
#ifdef DOPRETRIGGER
      for(i=0; i<pBIpre->numSamples; i++){
	switch(width){
	case 1:
	  if(abs(prebuffer8[i]) > value8){
	    windowCount++;
	  }
	  else{
	    windowCount=0;
	  }
	  break;  
	case 2:
	  if(abs(prebuffer16[i]) > value16){
	    windowCount++;
	  }
	  else{
	    windowCount=0;
	  }
	  break;
	case 6:
	  if(abs(prebuffer16[i]) > value16){
	    windowCount++;
	  }
	  else{
	    windowCount=0;
	  }
	  break;
	}
	
	if(windowCount >= windowLen){
#ifdef TRIGGER_DEBUG
	  trace(DBG_USR1,"TriggerManager.evalTrigger found trigger condition at sample %d of acqusition for TRIGGER_ABS_GT query\r\n",((totalCount-1) *pBI->numSamples) + i);
	  totalCount = 0;
#endif
	  return TRUE;
	}
      }
#endif
      for(i=0; i<pBI->numSamples; i++){
	switch(width){
	case 1:
	  if(abs(buffer8[i]) > value8){
	    windowCount++;
	  }
	  else{
	    windowCount=0;
	  }
	  break;  
	case 2:
	  if(abs(buffer16[i]) > value16){
	    windowCount++;
	  }
	  else{
	    windowCount=0;
	  }
	  break;
	case 6:
	  if(abs(buffer16[i]) > value16){
	    windowCount++;
	  }
	  else{
	    windowCount=0;
	  }
	  break;
	}
	
	if(windowCount >= windowLen){
#ifdef TRIGGER_DEBUG
	  trace(DBG_USR1,"TriggerManager.evalTrigger found trigger condition at sample %d of acqusition for TRIGGER_ABS_GT query\r\n",((totalCount) *pBI->numSamples) + i);
	  totalCount = 0;
#endif
	  return TRUE;
	}
      }
      break;
    case TRIGGER_ABSOLUTE_LT:
#ifdef DOPRETRIGGER
      for(i=0; i<pBIpre->numSamples; i++){
	switch(width){
	case 1:
	  if(abs(prebuffer8[i]) < value8){
	    windowCount++;
	  }
	  else{
	    windowCount=0;
	  }
	  break;  
	case 2:
	  if(abs(prebuffer16[i]) < value16){
	    windowCount++;
	  }
	  else{
	    windowCount=0;
	  }
	  break;
	case 6:
	  if(abs(prebuffer16[i]) < value16){
	    windowCount++;
	  }
	  else{
	    windowCount=0;
	  }
	  break;
	}
	
	if(windowCount >= windowLen){
#ifdef TRIGGER_DEBUG
	  trace(DBG_USR1,"TriggerManager.evalTrigger found trigger condition at sample %d of acqusition for TRIGGER_ABS_LT query\r\n",((totalCount-1) *pBI->numSamples) + i);
	  totalCount = 0;
#endif
	  return TRUE;
	}
      }
#endif
      for(i=0; i<pBI->numSamples; i++){
	switch(width){
	case 1:
	  if(abs(buffer8[i]) < value8){
	    windowCount++;
	  }
	  else{
	    windowCount=0;
	  }
	  break;  
	case 2:
	  if(abs(buffer16[i]) < value16){
	    windowCount++;
	  }
	  else{
	    windowCount=0;
	  }
	  break;
	case 6:
	  if(abs(buffer16[i])< value16){
	    windowCount++;
	  }
	  else{
	    windowCount=0;
	  }
	  break;
	}
	
	if(windowCount >= windowLen){
#ifdef TRIGGER_DEBUG
	  trace(DBG_USR1,"TriggerManager.evalTrigger found trigger condition at sample %d of acqusition for TRIGGER_ABS_LT query\r\n",((totalCount) *pBI->numSamples) + i);
	  totalCount = 0;
#endif
	  return TRUE;
	}
      }
      break;
    case TRIGGER_RMS_GT:
         //initialize the loop
#ifdef DOPRETRIGGER
      switch(width){
      case 1:
	return evalRMSPreTrigger8(pTI, pBI, pBIpre);
	break;
      case 2:
	return evalRMSPreTrigger16(pTI, pBI, pBIpre);
	break;
      case 6:
	return evalRMSPreTrigger16(pTI, pBI, pBIpre);
	break;
      default:
	trace(DBG_USR1,"TriggerManager.evalTrigger found invalid sample width of %d when evaluating TRIGGER_RMS_GT\r\n",width);
	return FALSE;
      }
#else
      switch(width){
      case 1:
	return evalRMS8(pTI, pBI);
	break;
      case 2:
	return evalRMS16(pTI, pBI);
	break;
      case 6:
	return evalRMS16(pTI, pBI);
	break;
      default:
	trace(DBG_USR1,"TriggerManager.evalTrigger found invalid sample width of %d when evaluating TRIGGER_RMS_GT\r\n",width);
	return FALSE;
      }
#endif
      break;
    case TRIGGER_RMS_LT:
               //initialize the loop
#ifdef DOPRETRIGGER
      switch(width){
      case 1:
	return evalRMSPreTrigger8(pTI, pBI, pBIpre);
	break;
      case 2:
	return evalRMSPreTrigger16(pTI, pBI, pBIpre);
	break;
      case 6:
	return evalRMSPreTrigger16(pTI, pBI, pBIpre);
	break;
      default:
	trace(DBG_USR1,"TriggerManager.evalTrigger found invalid sample width of %d when evaluating TRIGGER_RMS_GT\r\n",width);
	return FALSE;
      }
#else
      switch(width){
      case 1:
	return evalRMS8(pTI, pBI);
	break;
      case 2:
	return evalRMS16(pTI, pBI);
	break;
      case 6:
	return evalRMS16(pTI, pBI);
	break;
      default:
	trace(DBG_USR1,"TriggerManager.evalTrigger found invalid sample width of %d when evaluating TRIGGER_RMS_GT\r\n",width);
	return FALSE;
      }
#endif
      break;
    default:
      trace(DBG_USR1,"FATAL ERROR:  TriggerManager.evalTrigger encountered unknown trigger function\r\n");
    }
    
    return FALSE;
  }
  
  void checkTrigger(triggerWaitInfo_t *pTWI){
    int i,j;
    bool bTriggered=FALSE;
    
    if(pTWI==NULL){
      trace(DBG_USR1,"FATAL ERROR:  TriggerManager.checkTrigger received a NULL pTWI pointer\r\n");
      return;
    }
    
    if(pTWI->bTriggered == TRUE){
#ifdef DOPRETRIGGER
      if( (pTWI->numPreTriggerEntries != 0) && (pTWI->bWrotePreTriggerBuffers == FALSE)){
	//this will be false if we haven't written our pretrigger buffers iff we were forcefully triggered
	trace(DBG_USR1,"Writing Pretrigger Buffers\r\n");
	  for(i=0; i<pTWI->numChannelEntries; i++){
	    bufferInfo_t *pBI;
	    uint8_t dataChannel = pTWI->channelList[i];
	    if(findPreTriggerBufferInfo(pTWI,dataChannel,&pBI) == TRUE){
	      dispatchBufferInfo(dataChannel, pBI);
	    }
	    else{
	      trace(DBG_USR1,"KNOWN ISSUE:  Missing preTrigger Buffer for channel %d despite being triggered...\r\n",
		    pTWI->channelList[i]);
	    }
	  }
	  pTWI->bWrotePreTriggerBuffers = TRUE;
      }
#endif
      
      //already triggered...write each entry in our channelList 
      for(i=0; i<pTWI->numChannelEntries; i++){
	bufferInfo_t *pBI;
	uint8_t dataChannel = pTWI->channelList[i];
	if(findStatusBufferInfo(pTWI,dataChannel,&pBI) == TRUE){
	  //got our buffer...write it out and see if we're
	  dispatchBufferInfo(dataChannel, pBI);
	}
	else{
	  if(pTWI->bTriggerInstalled){
	    trace(DBG_USR1,"KNOWN ISSUE:  Missing dataBuffer for channel %d despite being triggered...\r\n",
		  pTWI->channelList[i]);
	  }
	  else{
	    trace(DBG_USR1,"FATAL ERROR:  Missing dataBuffer for channel %d despite being triggered\r\n",
		  pTWI->channelList[i]);
	    
	  }
	}
      }
    }
    else{ //pTWI->bTriggered == FALSE
      //we haven't triggered yet
      for(i=0; (i<pTWI->numChannelEntries) && (bTriggered == FALSE) ; i++){
	//check the trigger conditions installed on each entry in the list.  If one trigger evals to true, write all buffers
	triggerSet_t *pts =  &gTriggerSet[pTWI->channelList[i]]; 
	uint8_t boolOp = TRIGGER_OP_NONE;
	
	if(pts->numEntries>0){
	  boolOp = pts->triggerInfo[0].boolOp;  
	  switch(boolOp){
	  case TRIGGER_OP_OR:
	    bTriggered = FALSE;
	    break;
	  case TRIGGER_OP_AND:
	    bTriggered = TRUE;
	    break;
	  }
	}
	for(j=0;j<pts->numEntries;j++){
	  bool bResult;
	  bufferInfo_t *pBI, *pBIpre=NULL;
	  
	  triggerInfo_t *pTI = &(pts->triggerInfo[j]);
	  if(findStatusBufferInfo(pTWI,pTI->triggerChannel,&pBI) == TRUE){
#ifdef DOPRETRIGGER
	    if(findPreTriggerBufferInfo(pTWI,pTI->triggerChannel, &pBIpre) == FALSE){
	      trace(DBG_USR1,"FATAL ERROR:  Missing preTrigger dataBuffer for channel %d required to evaluate trigger for channel %d\r\n", pTI->triggerChannel, pTWI->channelList[i]);
	      return;
	    }
#endif
	    bResult = evalTrigger(pTI,pBI, pBIpre);
	    switch(boolOp){
	    case TRIGGER_OP_NONE:
	      bTriggered = TRUE;
	      break;
	    case TRIGGER_OP_OR:
	      bTriggered |= bResult;  //equivalent to just setting, but done this way for consistency
		break;
	      case TRIGGER_OP_AND:
		bTriggered &= bResult;
		break;
	    default:
	    }
	  }
	  else{
	    trace(DBG_USR1,"FATAL ERROR:  Missing dataBuffer for channel %d required to evaluate trigger for channel %d\r\n", pTI->triggerChannel, pTWI->channelList[i]);
	    return;
	  }
	}
      }
      if(bTriggered == TRUE){
	pTWI->bTriggered = TRUE;
	
#ifdef DOPRETRIGGER
	trace(DBG_USR1,"Writing Pretrigger Buffers\r\n");
	if(pTWI->bWrotePreTriggerBuffers == FALSE){
	  //this should always be false here, but just in case something is screwey
	  for(i=0; i<pTWI->numChannelEntries; i++){
	    bufferInfo_t *pBI;
	    uint8_t dataChannel = pTWI->channelList[i];
	    if(findPreTriggerBufferInfo(pTWI,dataChannel,&pBI) == TRUE){
	      dispatchBufferInfo(dataChannel, pBI);
	    }
	    else{
	      trace(DBG_USR1,"KNOWN ISSUE:  Missing preTrigger Buffer for channel %d despite being triggered...\r\n",
		    pTWI->channelList[i]);
	    }
	  }
	  pTWI->bWrotePreTriggerBuffers = TRUE;
	}
	else{
	  trace(DBG_USR1,"WARNING:  TriggerManager.checkTrigger found unexpected bWrotePreTriggerBuffers==TRUE\r\n");
	}
#endif
	for(i=0; i<pTWI->numChannelEntries; i++){
	  bufferInfo_t *pBI;
	  uint8_t dataChannel = pTWI->channelList[i];
	  if(findStatusBufferInfo(pTWI,dataChannel,&pBI) == TRUE){
	    dispatchBufferInfo(dataChannel, pBI);
	  }
	  else{
	    trace(DBG_USR1,"KNOWN ISSUE:  Missing dataBuffer for channel %d despite being triggered...\r\n",
		  pTWI->channelList[i]);
	  }
	}
      }
      else{
	//did not trigger
	//might need to rotate buffers here if we're keeping a pre-trigger buffer lying around
	collectionInfo_t *pCI; 
	
#ifdef DOPRETRIGGER
	//rotate statusBuffer to PreTrigger and release memory
	if(pTWI->numStatusEntries != pTWI->numPreTriggerEntries){
	  trace(DBG_USR1,"FATAL ERROR:  TriggerManager.clearOutWaitInfoBuffers found inconsistent pretrigger/posttrigger buffer entry state\r\n");
	  return;
	}
	
	for(i=0; i<pTWI->numStatusEntries; i++){
	  //get the pretrigger buffer pointer
	  pCI = &gCollectionInfo[pTWI->preTriggerBufferInfo[i].dataChannel];
	  	  
	  if(pTWI->statusBufferInfo[i].dataChannel == pTWI->preTriggerBufferInfo[i].dataChannel){
	    if(pTWI->preTriggerBufferInfo[i].buffer){
	      call BufferManagement.ReleaseBuffer(pTWI->preTriggerBufferInfo[i].buffer - pCI->headerSize);
	      pTWI->preTriggerBufferInfo[i].buffer = NULL;
	    }
	    if(copyBufferInfo(&pTWI->preTriggerBufferInfo[i], &pTWI->statusBufferInfo[i]) == FALSE){
	      trace(DBG_USR1,"FATAL ERROR:  TriggerManager.copyBufferInfo failed\r\n");
	      return;
	    }
	  }
	  else{
	    trace(DBG_USR1,"FATAL ERROR:  TriggerManager.checkTrigger found inconsistent pretrigger/posttrigger buffer channel state\r\n");
	    return;
	  }
	}
#else
	for(i=0; i<pTWI->numStatusEntries; i++){
	  pCI = &gCollectionInfo[pTWI->statusBufferInfo[i].dataChannel];
	  call BufferManagement.ReleaseBuffer(pTWI->statusBufferInfo[i].buffer - pCI->headerSize);
	}
#endif
      }
    }
    return;
  }
  
  void dispatchBufferInfo(uint8_t dataChannel, bufferInfo_t *pBI){
#ifdef FAKE_DATA
    int i;
#endif
    //got our buffer...write it out
    uint16_t numBytesWrite, numBytesTotal;
    collectionInfo_t *pCI = &gCollectionInfo[dataChannel]; 
    
    if(pBI==NULL){
      trace(DBG_USR1,"ERROR:  TriggerManager.dispatchBufferInfo passed null bufferInfo_t pointer\r\n");
      return;
    }
    
    pCI->numSamplesRemaining -= pBI->numSamples;
    numBytesWrite = pBI->numSamples*pCI->sampleWidth + pCI->headerSize;
    numBytesTotal = numBytesWrite + pCI->footerSize;
    

#ifdef FAKE_DATA
    for(i=0; i<pBI->numSamples; i++){
      uint8_t *buffer8 = (uint8_t*)pBI->buffer;
      uint16_t *buffer16 = (uint16_t*)pBI->buffer;
      
      switch(pCI->sampleWidth){
      case 1:
	buffer8[i] = i;
	break;
      default:
	buffer16[i] = i;
      }
    }
#endif
    
    if(pCI->numSamplesRemaining == 0){
      pCI->bDone = TRUE;
      signal TriggerManager.TriggeredData(dataChannel, 
					  pBI->buffer - pCI->headerSize, 
					  pBI->ADCScale,
					  pBI->ADCOffset,
					  numBytesWrite,
					  numBytesTotal,
					  pBI->numSamples,
					  pBI->timestamp);
    }
    else if(pCI->numSamplesRemaining > 0){
      signal TriggerManager.TriggeredData(dataChannel, 
					  pBI->buffer - pCI->headerSize, 
					  pBI->ADCScale,
					  pBI->ADCOffset,
					  numBytesWrite,
					  numBytesTotal,
					  pBI->numSamples,
					  pBI->timestamp);
    }
    else{
      pCI->bDone = TRUE;
      trace(DBG_USR1,"TriggerManager dropping excess dataBuffer for channel %d\r\n", dataChannel);
      call BufferManagement.ReleaseBuffer(pBI->buffer - pCI->headerSize);
    }
  }
  

  void printDataError(uint32_t arg){
    uint8_t dataChannel  = (uint8_t) arg;
    trace(DBG_USR1,"FATAL ERROR:  Received incorrect number of samples from channel %d\r\n",dataChannel);
    return;
  }

  void printUnexpectedDataError(uint32_t arg){
    uint8_t dataChannel  = (uint8_t) arg;
    trace(DBG_USR1,"ERROR:  Received unexpected data from channel %d\r\n",dataChannel);
    return;
  }
  
  event result_t SensorData.getSensorDataStopped[uint8_t dataChannel](){
    collectionInfo_t *pCI = &gCollectionInfo[dataChannel]; 
    triggerWaitInfo_t *pTWI = gTriggerWaitInfo[dataChannel];
    pCI->bStopped = TRUE;
    checkCompletionAndCleanUpState(pTWI);
    
    return SUCCESS;
  }
  
  event uint8_t *SensorData.getSensorDataDone[uint8_t dataChannel](uint8_t *buffer, 
								   uint32_t numSamples, 
								   uint64_t timestamp,
								   float ADCScale,
								   float ADCOffset){
        
    /***
     *Pseudo-code
     *
     *Keep track of the total number of buffers that we need to allocate
     *keep handing buffers until we reach 0 buffers needed
     *
     *
     *
     **/
    collectionInfo_t *pCI = &gCollectionInfo[dataChannel]; 
    bufferInfo_t *pBI;
    uint8_t *newBuffer;
    uint32_t oldvalue;
    
    popqueue(&bufferState[dataChannel],&oldvalue);
    assert(oldvalue == (uint32_t)buffer);  //make sure that we're getting back the last thing that we pushed in
    
    if(numSamples != pCI->numSamples){
      //didn't get everything that we wanted
      POST_PARAMTASK(printDataError,dataChannel);
      return NULL;
    }
    
    if(numSamples == 0){
      POST_PARAMTASK(printUnexpectedDataError,dataChannel);
      return NULL;
    }
    
    pBI = malloc(sizeof(*pBI));
    MALLOC_DBG(__FILE__,"getSensorDataDone",pBI, sizeof(*pBI));
    if(pBI){
      pBI->buffer=buffer;
      pBI->timestamp = timestamp;
      pBI->numSamples = numSamples;
      pBI->dataChannel = dataChannel;
      pBI->ADCScale = ADCScale;
      pBI->ADCOffset = ADCOffset;
    }
    else{
      trace(DBG_USR1,"FATAL ERROR...TriggerManager unable to allocate memory for temp structure\r\n"); 
      return NULL;
    }
    
    POST_PARAMTASK(processBuffer,pBI);
    
    if(isTriggered(dataChannel)){
      if(pCI->numBuffersNeeded > 0){
	//we need more buffers...allocate it and send it down
	newBuffer = call BufferManagement.AllocBuffer(pCI->totalAllocatedSize);
	
	pCI->numBuffersNeeded--;
	pushqueue(&bufferState[dataChannel],(uint32_t)( newBuffer+pCI->headerSize));
	return newBuffer+pCI->headerSize; 
      }
      else{
	return NULL;
      }
    }
    else{
      //we need more buffers...allocate it and send it down
      newBuffer = call BufferManagement.AllocBuffer(pCI->totalAllocatedSize);
      
      pushqueue(&bufferState[dataChannel], (uint32_t) (newBuffer+pCI->headerSize));
      
      return newBuffer+pCI->headerSize; 
    }
  }
  
  command result_t TriggerManager.cancelWaitForTrigger(uint8_t numChannels, 
						       uint8_t *targetChannels){
    
    //in order to gracefully, cancel the acqusition, we need to:
    // 1.) indicate that the acquisition has been triggered
    // 2.) set numBuffersNeeded in the collectioninfo structure to 0;
    int i;
    triggerWaitInfo_t *pTWI;
    collectionInfo_t *pCI;
    
    for(i=0; i<numChannels; i++){
      pCI = &gCollectionInfo[targetChannels[i]];
      pTWI = gTriggerWaitInfo[targetChannels[i]];
      
      pCI->bDone = TRUE;
      pCI->numBuffersNeeded = 0;
      
      if(pTWI != NULL){
	pTWI->bTriggered = TRUE;
      }
    }
    
    return SUCCESS;
  }

  command result_t TriggerManager.setWarmupInfo(uint8_t channel, 
						uint32_t type){
    
    if(channel > TOTAL_DATA_CHANNELS){
      return FAIL;
    }
    
    if(call SensorData.setSensorType[channel](type) == FAIL){
      trace(DBG_USR1,"FATAL ERROR:  SensorData.setSensorType failed for channel %d\r\n",channel);
      return FAIL;
    }
    return SUCCESS;
  } 
  
  command result_t TriggerManager.setCollectionInfo(uint8_t channel, 
						    uint32_t samplingRate, 
						    uint32_t numSamples,
						    uint8_t  sampleWidth,
						    uint16_t headerSize, 
						    uint16_t footerSize){
    
    collectionInfo_t *pCI;
    uint32_t totalAllocatedSize;
    uint32_t actualSamplingRate;
    
    if(channel > TOTAL_DATA_CHANNELS){
      return FAIL;
    }
    else{
      pCI = &gCollectionInfo[channel];
    }
    
    pCI->samplingRate = samplingRate;
    pCI->numSamples = numSamples;
    pCI->numSamplesRemaining = numSamples;
    pCI->sampleWidth = sampleWidth;
    pCI->headerSize = headerSize;
    pCI->footerSize = footerSize;
    pCI->bDone = FALSE;
    pCI->bStopped = FALSE;
#ifdef DOPRETRIGGER
    pCI->numBuffersNeeded = 1;
#else
    pCI->numBuffersNeeded = 0;
#endif
    
    //set the actual sampling rate check sampling rate
    if(call SensorData.setSamplingRate[channel](samplingRate, &actualSamplingRate) == FAIL){
      trace(DBG_USR1,"FATAL ERROR:  SensorData.setSamplingRate failed for channel %d\r\n",channel);
      return FAIL;
    }
   
    if(samplingRate != actualSamplingRate){
      trace(DBG_USR1,"FATAL ERROR:  SensorData channel %d can sample only at %d Hz and not at requested %d Hz\r\n",channel, actualSamplingRate, samplingRate);
      return FAIL;
    }
    
    //set the actual sampling rate check sampling rate
    if(call SensorData.setSampleWidth[channel](sampleWidth) == FAIL){
      trace(DBG_USR1,"FATAL ERROR:  SensorData.setSampleWidth failed for channel %d\r\n",channel);
      return FAIL;
    }

    
#ifdef DOCHUNKING
    if(DOCHUNKING){
      uint16_t newNumSamples;
      uint16_t numBuffers;
      
      newNumSamples = CHUNKSIZE;
      trace(DBG_USR1,"Info:  Chunking enabled...buffer size = %d samples\r\n",CHUNKSIZE);
      numBuffers = numSamples/newNumSamples;
      
      if((numBuffers*newNumSamples) != numSamples){
	trace(DBG_USR1,"WARNING:  Chunking option requires an integer number of sample buffers.  Total Samples rounded up to %d\r\n",
	      (numBuffers+1)*newNumSamples);
	numBuffers++;
      }
      pCI->numSamples = newNumSamples;

#ifdef DOPRETRIGGER
      pCI->numBuffersNeeded = numBuffers;
      pCI->numSamplesRemaining = (numBuffers+1)*newNumSamples;
#else
      pCI->numBuffersNeeded = numBuffers-1;
      pCI->numSamplesRemaining = numBuffers*newNumSamples;
	    
#endif


      
      numSamples = CHUNKSIZE;
    }
#endif
    totalAllocatedSize = numSamples*sampleWidth + headerSize + footerSize;
    pCI->totalAllocatedSize = totalAllocatedSize;
        
    return SUCCESS;
  }

  default command result_t SensorData.getSensorData[uint8_t dataChannel](uint8_t *buffer, uint32_t numSamples){
    trace(DBG_USR1,"FATAL ERROR IN SENSORDRIVER FRAMEWORK CONFIGURATION:  data channel%d not connected\r\n", dataChannel); 
    return FAIL;
  }

  default command result_t SensorData.getOutputUOM[uint8_t dataChannel](uint8_t *pUOM){
    trace(DBG_USR1,"FATAL ERROR IN SENSORDRIVER FRAMEWORK CONFIGURATION:  data channel%d not connected\r\n", dataChannel); 
    return FAIL;
  }

  default command result_t SensorData.setSensorType[uint8_t dataChannel](uint32_t sensorType){
    trace(DBG_USR1,"FATAL ERROR IN SENSORDRIVER FRAMEWORK CONFIGURATION:  data channel%d not connected\r\n", dataChannel); 
    return FAIL;
  }

  default command result_t SensorData.setSamplingRate[uint8_t dataChannel](uint32_t requestedSamplingRate, uint32_t *actualSamplingRate){
    trace(DBG_USR1,"FATAL ERROR IN SENSORDRIVER FRAMEWORK CONFIGURATION:  data channel%d not connected\r\n", dataChannel); 
    return FAIL;
  }

  default command result_t SensorData.setSampleWidth[uint8_t dataChannel](uint8_t requestedSampleWidth){
    trace(DBG_USR1,"FATAL ERROR IN SENSORDRIVER FRAMEWORK CONFIGURATION:  data channel%d not connected\r\n", dataChannel); 
    return FAIL;
  }
  

  
#ifdef BLUSH_TRIGGER

  command BluSH_result_t ForceTrigger.getName(char *buff, uint8_t len){
    
    const char name[] = "ForceTrigger";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }
  
  command BluSH_result_t ForceTrigger.callApp(char *cmdBuff, uint8_t cmdLen,
					 char *resBuff, uint8_t resLen){
    uint32_t channel;
    
    if(strlen(cmdBuff) > strlen("ForceTrigger ")){
      sscanf(cmdBuff,"ForceTrigger %d", &channel);
      if(channel < TOTAL_DATA_CHANNELS){
	if(gTriggerWaitInfo[channel]){
	  gTriggerWaitInfo[channel]->bTriggered = TRUE;
	}
	else{
	  trace(DBG_USR1,"Error: ForceTrigger encounted unstarted data channel \r\n");
	}
      }
      else{
	trace(DBG_USR1,"ForceTrigger received invalid target data channel = %d\r\n",channel);
      } 
    }
    else{
      trace(DBG_USR1,"ForceTrigger targetDataChannel\r\n");
    }
    return BLUSH_SUCCESS_DONE;
  }
  
#endif
}
