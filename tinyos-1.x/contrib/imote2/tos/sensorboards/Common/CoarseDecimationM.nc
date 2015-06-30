module CoarseDecimationM{
  provides{
    interface SensorData as OutData[uint8_t dataChannel];
    
  }
  uses{
    interface SensorData as InData[uint8_t dataChannel];
  }
}

implementation{
#include "paramtask.h"
#include "bufferManagementHelper.h"

#ifndef MAX_COARSE_DECIMATION_CHANNELS
#define MAX_COARSE_DECIMATION_CHANNELS (4)
#endif
  
#define NUMBUFFERS (5)

  void processBuffer(uint32_t arg);
  DEFINE_PARAMTASK(processBuffer);
  
  void signalGetSensorDataStopped(uint32_t dataChannel);
  DEFINE_PARAMTASK(signalGetSensorDataStopped);

  typedef struct {
    uint32_t k;
    int outstandingCount;
    
    bool kValid;
    uint8_t width;
    bool widthValid;
    bool finished;
    bool producerStopped;
  }collectionInfo_t;

  typedef struct{
    uint8_t *buffer;
    uint32_t numSamples;
  } outDataBufferInfo_t;
  

  typedef struct{
    uint8_t *buffer;
    uint64_t timestamp;
    float ADCScale;
    float ADCOffset;
    uint32_t numSamples;
    uint8_t dataChannel;
    bool inuse;
  } inDataBufferInfo_t;

  typedef struct{
    uint8_t * buf;
    uint32_t inuse;
  } buffer_t;
  
  inDataBufferInfo_t gInDataBufferInfo[MAX_COARSE_DECIMATION_CHANNELS][NUMBUFFERS];
  buffer_t tempBuffers[MAX_COARSE_DECIMATION_CHANNELS][NUMBUFFERS];
  
  uint32_t gTotalBuffersProcessed = 0;
  
  bool areBuffersFree(uint8_t channel){
    
    int i;
    bool ret = TRUE;
    
    atomic{
      for(i=0;i<NUMBUFFERS; i++){
	if((tempBuffers[channel][i].inuse == TRUE) || (tempBuffers[channel][i].buf != NULL)){
	  ret = FALSE;
	}
      }
    }
    return ret;
  }
  
  uint32_t getBufferLevel(uint8_t channel){
    int i;
    uint32_t ret =0;
    atomic{
      for(i=0;i<NUMBUFFERS; i++){
	if(tempBuffers[channel][i].inuse == FALSE){
	  ret++;
	}
      }
    }
    return ret;
  }
  
  uint8_t *getNextBuffer(uint8_t channel){
    int i;
    uint8_t *ret = NULL;
    atomic{
      for(i=0;i<NUMBUFFERS; i++){
	if(tempBuffers[channel][i].inuse == FALSE){
	  tempBuffers[channel][i].inuse = TRUE;
	  ret = (uint8_t *)tempBuffers[channel][i].buf;
	  break;
	}
      }
    }
    return ret;
  }
  
  void returnBuffer(uint8_t channel,uint8_t *buf){
    int i;
    atomic{
      for(i=0;i<NUMBUFFERS; i++){
	if(tempBuffers[channel][i].buf == buf){
	  tempBuffers[channel][i].inuse = FALSE;
	  break;
	}
      }
    }
  }
  
  void releaseBuffers(uint8_t channel){
    int i;
    
    atomic{
      for(i=0;i<NUMBUFFERS; i++){
	assert(tempBuffers[channel][i].inuse == FALSE);
	
	FREE_DBG(__FILE__,"releaseBuffers",tempBuffers[channel][i].buf);
	free(tempBuffers[channel][i].buf);
	
	tempBuffers[channel][i].buf = NULL;
      }
    }
  }  
  
  void initBuffers(uint8_t channel, size_t size){
    int i;
    atomic{
      for(i=0;i<NUMBUFFERS; i++){
	assert(tempBuffers[channel][i].buf == NULL);
	tempBuffers[channel][i].inuse = FALSE;
	if(!(tempBuffers[channel][i].buf = memalign(32, DMA_BUFFER_SIZE(size))) ){
	  printFatalErrorMsg("Unable to Allocate memory for CoarseDecimation of size = ",1, DMA_BUFFER_SIZE(size));
	}
	MALLOC_DBG(__FILE__,"initBuffers",tempBuffers[channel][i].buf,DMA_BUFFER_SIZE(size)); 
      }
    }
  }
    
  uint32_t getBIBufferLevel(uint8_t dataChannel){
    int i;
    uint32_t ret = 0;
    atomic{
      for(i=0;i<NUMBUFFERS; i++){
	if(gInDataBufferInfo[dataChannel][i].inuse == FALSE){
	  ret++;
	}
      }
    }
    return ret;
  }
  
  inDataBufferInfo_t *getNextBIBuffer(uint8_t dataChannel){
    int i;
    inDataBufferInfo_t *ret = NULL;
    atomic{
      for(i=0;i<NUMBUFFERS; i++){
	if(gInDataBufferInfo[dataChannel][i].inuse == FALSE){
	  gInDataBufferInfo[dataChannel][i].inuse = TRUE;
	  ret = &gInDataBufferInfo[dataChannel][i];
	  break;
	}
      }
    }
    return ret;
  }
  
  void returnBIBuffer(uint8_t dataChannel, inDataBufferInfo_t *pBI){
    int i;
    atomic{
      for(i=0;i<NUMBUFFERS; i++){
	if(&gInDataBufferInfo[dataChannel][i] == pBI){
	  gInDataBufferInfo[dataChannel][i].inuse = FALSE;
	}
      }
    }
  }
  
  void initBIBuffer(uint8_t dataChannel){
    int i;
    atomic{
      for(i=0;i<NUMBUFFERS; i++){
	gInDataBufferInfo[dataChannel][i].inuse = FALSE;
      }
    }
  }

  
  outDataBufferInfo_t gOutDataInfo[MAX_COARSE_DECIMATION_CHANNELS];
 
  collectionInfo_t gCollectionInfo[MAX_COARSE_DECIMATION_CHANNELS];
  downsampleTempBuffer_t *downsampleTempBuffer[MAX_COARSE_DECIMATION_CHANNELS];
  downsampleStates_t gDownsampleStates[4];

  void signalGetSensorDataStopped(uint32_t dataChannel){
    
    assert(gCollectionInfo[dataChannel].finished);
    assert(gCollectionInfo[dataChannel].producerStopped);
    
    trace(DBG_USR1,"upper levels =  %d %d\r\n",getBufferLevel(dataChannel), getBIBufferLevel(dataChannel));
    
    if( (getBufferLevel(dataChannel) == NUMBUFFERS) && (getBIBufferLevel(dataChannel) == NUMBUFFERS)){
      //make sure we're not calling this twice
      assert(areBuffersFree(dataChannel) == FALSE);
      releaseBuffers(dataChannel);
      FREE_DBG(__FILE__,"signalGetSensorDataStopped",downsampleTempBuffer[dataChannel]);
      free(downsampleTempBuffer[dataChannel]);

      signal OutData.getSensorDataStopped[dataChannel]();
    }
  }
  
  void processBuffer(uint32_t arg){
    uint8_t *ret;
    inDataBufferInfo_t *pBI;
    int dsRet;
    uint8_t dataChannel;
    

    pBI = (inDataBufferInfo_t *)arg;
    
    if(pBI == NULL){
      trace(DBG_USR1,"FATAL ERROR:  CoarseDecimationM.processBuffer received NULL arg\r\n");
      return;
    }
    
    dataChannel  = pBI->dataChannel;
    
    gCollectionInfo[dataChannel].outstandingCount--;
    if(gCollectionInfo[dataChannel].finished){
      returnBuffer(dataChannel, pBI->buffer);
      returnBIBuffer(dataChannel,pBI);
      if(gCollectionInfo[dataChannel].producerStopped == TRUE){
	POST_PARAMTASK(signalGetSensorDataStopped, dataChannel);
      }
      return;
    }
    
    if(pBI->numSamples != (gOutDataInfo[dataChannel].numSamples * gCollectionInfo[dataChannel].k)){
      trace(DBG_USR1,"FATAL ERROR:  CoarseDecimationM received %d samples when it expected %d samples\r\n",
	    pBI->numSamples,
	    gOutDataInfo[dataChannel].numSamples*gCollectionInfo[dataChannel].k);
      return;
    }
    
    if((dsRet = downsample(&gDownsampleStates[dataChannel], 
			   (short int *)pBI->buffer, 
			   pBI->numSamples, 
			   (short int *)gOutDataInfo[dataChannel].buffer, 
			   gCollectionInfo[dataChannel].k)) != 1){
      
      trace(DBG_USR1,"FATAL ERROR:  downsampling failed with return code %d\r\n",dsRet);
      return;
    }
    //successful;
    ret = signal OutData.getSensorDataDone[dataChannel](gOutDataInfo[dataChannel].buffer, gOutDataInfo[dataChannel].numSamples, pBI->timestamp, pBI->ADCScale, pBI->ADCOffset);
    if(ret == NULL){
      //we're done!
      gCollectionInfo[dataChannel].kValid = FALSE;
      gCollectionInfo[dataChannel].widthValid = FALSE;
      gCollectionInfo[dataChannel].finished = TRUE;
    }
    else{
      gOutDataInfo[dataChannel].buffer = ret;
    }
    returnBuffer(dataChannel,pBI->buffer);
    returnBIBuffer(dataChannel,pBI);
    
    return;
  }
  
  
  command result_t OutData.getOutputUOM[uint8_t dataChannel](uint8_t *UOM){
    if(dataChannel < MAX_COARSE_DECIMATION_CHANNELS){
      return call InData.getOutputUOM[dataChannel](UOM);
    }
   else{
      return FAIL;
    }
  }


  command result_t OutData.setSensorType[uint8_t dataChannel](uint32_t sensorType){
    if(dataChannel < MAX_COARSE_DECIMATION_CHANNELS){
      return call InData.setSensorType[dataChannel](sensorType);
    }
    else{
      return FAIL;
    }
  }

  command result_t OutData.setSamplingRate[uint8_t dataChannel](uint32_t requestedSamplingRate, uint32_t *actualSamplingRate){
    if(dataChannel < MAX_COARSE_DECIMATION_CHANNELS){
      //see what the board will be returning us for this samplingRate
      if(call InData.setSamplingRate[dataChannel](requestedSamplingRate, actualSamplingRate) == SUCCESS){
	if((*actualSamplingRate) >= requestedSamplingRate){
	  gCollectionInfo[dataChannel].k = *actualSamplingRate/requestedSamplingRate;
	  gCollectionInfo[dataChannel].kValid = TRUE;
	  *actualSamplingRate = *actualSamplingRate/gCollectionInfo[dataChannel].k;
	}
	return SUCCESS;
      }
    }
    return FAIL;
  }
  
  command result_t OutData.setSampleWidth[uint8_t dataChannel](uint8_t requestedSampleWidth){
    if(dataChannel < MAX_COARSE_DECIMATION_CHANNELS){
      if(call InData.setSampleWidth[dataChannel](requestedSampleWidth)){
	gCollectionInfo[dataChannel].width = requestedSampleWidth;
	gCollectionInfo[dataChannel].widthValid = TRUE;
	return SUCCESS;
      }
      else{
	gCollectionInfo[dataChannel].widthValid = FALSE;
      }
    }
    return FAIL;
  }
  
  command result_t OutData.getSensorData[uint8_t dataChannel](uint8_t *buffer, uint32_t numSamples){
    uint8_t *newBuffer;
    uint32_t newNumSamples;
    
    if(dataChannel < MAX_COARSE_DECIMATION_CHANNELS){
      if(gCollectionInfo[dataChannel].kValid == FALSE){
	trace(DBG_USR1,"FATAL ERROR:  SensorData.setSamplingRate was not called on data channel %d\r\n",dataChannel);
	return FAIL;
      }
      if(gCollectionInfo[dataChannel].widthValid == FALSE){
	trace(DBG_USR1,"FATAL ERROR:  SensorData.setSampleWidth was not called on data channel %d\r\n",dataChannel);
	return FAIL;
      }
      
      if(gCollectionInfo[dataChannel].outstandingCount != 0){
		
	printFatalErrorMsg("CoarseDecimation found acquisition in progress while trying to start a new one: outstandingCount = ",1, gCollectionInfo[dataChannel].outstandingCount);
	return FAIL;
      }
      
      downsampleTempBuffer[dataChannel] = memalign(8,(numSamples*gCollectionInfo[dataChannel].width*gCollectionInfo[dataChannel].k)/4);
      MALLOC_DBG(__FILE__,"OutData.getSensorData",downsampleTempBuffer[dataChannel],(numSamples*gCollectionInfo[dataChannel].width*gCollectionInfo[dataChannel].k)/4); 
      assert(downsampleTempBuffer[dataChannel]);
      
      downsampleInit(&gDownsampleStates[dataChannel],downsampleTempBuffer[dataChannel]); 
      
      gOutDataInfo[dataChannel].buffer = buffer;
      gOutDataInfo[dataChannel].numSamples = numSamples;
      
      gCollectionInfo[dataChannel].producerStopped = FALSE;
      newNumSamples = numSamples * gCollectionInfo[dataChannel].k;
      initBuffers(dataChannel, newNumSamples * gCollectionInfo[dataChannel].width);
      
      newBuffer = getNextBuffer(dataChannel);
      
      assert(newBuffer);
      gCollectionInfo[dataChannel].finished = FALSE;
      gCollectionInfo[dataChannel].outstandingCount ++;
      return call InData.getSensorData[dataChannel](newBuffer, newNumSamples);
    }
    else{
      return FAIL;
    }
  }
  
  event uint8_t *InData.getSensorDataDone[uint8_t dataChannel](uint8_t *buffer, uint32_t numSamples, uint64_t timestamp, float ADCScale, float ADCOffset){
    
    inDataBufferInfo_t *pBI;
    uint8_t * newBuffer;
    
    pBI = getNextBIBuffer(dataChannel);
    
    assert(pBI);
    
    pBI->buffer = buffer;
    pBI->timestamp = timestamp;
    pBI->ADCScale = ADCScale;
    pBI->ADCOffset = ADCOffset;
    pBI->numSamples = numSamples;
    pBI->dataChannel = dataChannel;
    POST_PARAMTASK(processBuffer,pBI);
    
    if(gCollectionInfo[dataChannel].finished){
      return NULL;
    }
    
    newBuffer = getNextBuffer(dataChannel);
    
    assert(newBuffer);
    gCollectionInfo[dataChannel].outstandingCount++;
   
    return newBuffer;
    
  }

  event result_t InData.getSensorDataStopped[uint8_t dataChannel](){
        
    assert(gCollectionInfo[dataChannel].finished);
    gCollectionInfo[dataChannel].producerStopped = TRUE;
    trace(DBG_USR1,"CoarseDecimation notified that channel %d stopped\r\n",dataChannel);
    POST_PARAMTASK(signalGetSensorDataStopped, dataChannel);
    
    return SUCCESS;   
        
  }
  
  /****************************
DEFAULT COMMANDS
  *****************************/

  default command result_t InData.getOutputUOM[uint8_t dataChannel](uint8_t *UOM){
    return FAIL;
  }
  

  default command result_t InData.setSensorType[uint8_t dataChannel](uint32_t sensorType){
    return FAIL;
  }

  default command result_t InData.setSamplingRate[uint8_t dataChannel](uint32_t requestedSamplingRate, uint32_t *actualSamplingRate){
    return FAIL;
  }

  default command result_t InData.setSampleWidth[uint8_t dataChannel](uint8_t requestedSampleWidth){
    return FAIL;
  }
  
  default command result_t InData.getSensorData[uint8_t dataChannel](uint8_t *buffer, uint32_t numSamples){
    return FAIL;
  }
  
  default event uint8_t *OutData.getSensorDataDone[uint8_t dataChannel](uint8_t *buffer, uint32_t numSamples, uint64_t timestamp, float ADCScale, float ADCOffset){
    return NULL;
  }
  
  default event result_t OutData.getSensorDataStopped[uint8_t dataChannel](){
    return SUCCESS;
  }
  
  
}
