
/**
 * @author Robbie Adler
 **/

includes trace;
includes sensorboard;
#include "app.h"
//includes malloc;
includes profile;

module TestSensorboardM {
  provides {
    interface StdControl;
    
    interface BufferManagement;
    interface WriteData;
    
    interface BluSH_AppI as SleepApp;
    interface BluSH_AppI as GetData;    
    interface BluSH_AppI as AddTrigger;    
    interface BluSH_AppI as ClearTrigger;    
    interface BluSH_AppI as StartCollection;    
    interface BluSH_AppI as StopCollection;    
  }
  uses {
    //    interface Timer;
    interface Leds;
    interface Sleep;
    interface UID;
    //interface SendData as BulkSend;
#if USB_SEND_DATA
    interface SendJTPacket as USBSend;
#endif
    interface GenericSampling;
    interface DVFS;
    //interface ReceiveData;
  }
}
implementation {
#include "triggerFunctions.h"
#include "triggerOps.h"
#include "postprocessingFunctions.h"
#include "GenericSampling.h"
#include "sensorboard.h"
#include "sampleHeader.h"
#include "UOM.h"
#include "stdlib.h"
#include "PXA27XUSBClient.h"
#include "bufferManagementHelper.h"

#define TESTDATA 0
#define MAX_TOTAL_CHANNELS (4)

 /**
   * Initialize the component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  
  //I'm being lazy for now....UARTBUFFERLEN MUST BE 2x NUMSAMPLES

  //FROM_STRING_FUNC(UOM_t, UOM_TYPE);
  //AS_STRING_FUNC(UOM_t, UOM_TYPE);
  uint32_t gContinuousCollection = 0;
  
  uint32_t dataBufferPos = ~((uint32_t)0);
  
  uint8_t *gWriteProcessBuffer;
  uint32_t gWriteProcessBufferLength=0;

  bool gDoChannel[MAX_TOTAL_CHANNELS];
  bool gChannelDone[MAX_TOTAL_CHANNELS]; 
  
  
#if TESTDATA
  uint16_t gCurrentXCount, gCurrentYCount, gCurrentZCount;
  uint32_t gTotalXCount, gTotalYCount, gTotalZCount;
  
#endif  

  int32_t gXTotal=0, gYTotal=0, gZTotal=0;
  
  char testBuffer[] __attribute__((aligned(32))) = "DEADBEEF123456\r\n";
  
  command result_t StdControl.init() {
    
    return call Leds.init();
  }
    
  /**
   * Start things up.  This just sets the rate for the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.start() {
    call DVFS.SwitchCoreFreq(104,104);
    //return call Timer.start(TIMER_REPEAT, 500);
    return SUCCESS;
  }

  /**
   * Halt execution of the application.
   * This just disables the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.stop() {
    //return call Timer.stop();
    return SUCCESS;
  }


  /**
   * Toggle the red LED in response to the <code>Timer.fired</code> event.  
   *
   * @return Always returns <code>SUCCESS</code>
   **/  

#if 0
  event result_t Timer.fired()
  {
    //    call Leds.redToggle();
    return SUCCESS;
  }
#endif

  command BluSH_result_t GetData.getName(char *buff, uint8_t len){
    
    const char name[] = "GetData";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }
  
  command BluSH_result_t GetData.callApp(char *cmdBuff, uint8_t cmdLen,
					 char *resBuff, uint8_t resLen){
    uint32_t channel, numSamples, samplingRate, type,width, warmup;
    //Format = GetData channel numSamples samplingRate 
    
    TypeValItem tvi;
    functionInfo_t fis[1];
    
    fis[0].function = FI_FUNCTION_BOARD;
    fis[0].paramname =  FIF_BOARD_LOGICALNODEID;
    fis[0].paramval = call UID.getUID();

    tvi.functionInfo= fis;
    tvi.count=1;
    
    if(strlen(cmdBuff) > strlen("GetData ")){
      sscanf(cmdBuff,"GetData %d %d %d %d", &channel, &numSamples, &samplingRate, &warmup);
      trace(DBG_USR1,"Getting %d samples @ %dHz from channel %d w/warmup time = %d\r\n", numSamples, samplingRate,channel, warmup);
      
      //make sure that we get a valid sensortype ;o)
      type = channelCapabilitiesTable[channel].supportedSensorTypes->elements[0];
      width = channelCapabilitiesTable[channel].supportedSampleWidths->elements[0]; 
      
      if(call GenericSampling.prepare((uint8_t)channel, 
				      samplingRate, 
				      numSamples, 
				      width, 
				      FALSE, 
				      warmup,
				      type, 
				      0, 
				      &tvi) == FAIL){
	trace(DBG_USR1,"GenericSampling.prepare FAILED\r\n");
      }
    }
    else{
      trace(DBG_USR1,"GetData channel numSamples samplingRate warmup\r\n");
    }
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t AddTrigger.getName(char *buff, uint8_t len){
    
    const char name[] = "AddTrigger";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t AddTrigger.callApp(char *cmdBuff, uint8_t cmdLen,
					    char *resBuff, uint8_t resLen){
    
    uint32_t triggerChannel, targetChannel, triggerType, windowSize;
    float value;
    
    if(strlen(cmdBuff) > strlen("AddTrigger ")){
      sscanf(cmdBuff,"AddTrigger %d %d %d %d %f", &triggerChannel, &targetChannel, &triggerType, &windowSize, &value);
      
      if(call GenericSampling.AddTrigger(TRIGGER_OP_OR, 
					 triggerType,
					 value, 
					 windowSize,
					 triggerChannel,
					 targetChannel) == FAIL){
	trace(DBG_USR1,"GenericSampling.prepare FAILED\r\n");
      }
    }
    else{
      trace(DBG_USR1,"AddTrigger triggerChannel targetChannel type windowSize value\r\n");
    }
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t ClearTrigger.getName(char *buff, uint8_t len){
    
    const char name[] = "ClearTrigger";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t ClearTrigger.callApp(char *cmdBuff, uint8_t cmdLen,
					    char *resBuff, uint8_t resLen){
    
    uint32_t targetChannel;
    if(strlen(cmdBuff) > strlen("ClearTrigger ")){
      
      sscanf(cmdBuff,"ClearTrigger %d", &targetChannel);
      call GenericSampling.ClearTrigger(targetChannel);
      trace(DBG_USR1,"ClearTrigger(%d)\r\n", targetChannel);
    }
    else{
      trace(DBG_USR1,"ClearTrigger targetChannel\r\n");
    }


    
    return BLUSH_SUCCESS_DONE;
  }
  
  command BluSH_result_t StopCollection.getName(char *buff, uint8_t len){
    
    const char name[] = "StopCollection";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }
  
  void stopCollection(){
    uint8_t channelList[MAX_TOTAL_CHANNELS];
    uint8_t channelCount = 0;
    int i;
    
    for(i=0; i<MAX_TOTAL_CHANNELS; i++){
      if(gDoChannel[i]){
	gChannelDone[i] = FALSE;
	channelList[channelCount] = i;
	channelCount ++;
      }
    }
    
    trace(DBG_USR1,"Stopping acquisition\r\n");
    call GenericSampling.stop(channelCount, channelList);
  }
  
  command BluSH_result_t StopCollection.callApp(char *cmdBuff, uint8_t cmdLen,
						char *resBuff, uint8_t resLen){
    
    stopCollection();
    
    return BLUSH_SUCCESS_DONE;
  }
  
  command BluSH_result_t StartCollection.getName(char *buff, uint8_t len){
    
    const char name[] = "StartCollection";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }
    
  void startCollection(){
    
    uint8_t channelList[MAX_TOTAL_CHANNELS];
    uint8_t channelCount = 0;
    int i;
    static int startCount =0;
    
    for(i=0; i<MAX_TOTAL_CHANNELS; i++){
      if(gDoChannel[i]){
	gChannelDone[i] = FALSE;
	channelList[channelCount] = i;
	channelCount ++;
      }
    }
    //leak some memory for kicks
   
    trace(DBG_USR1,"Starting acquisition %d\r\n",startCount++);

    call GenericSampling.start(channelCount, channelList,0);
    
  }

  command BluSH_result_t StartCollection.callApp(char *cmdBuff, uint8_t cmdLen,
						 char *resBuff, uint8_t resLen){
         
    if(strlen(cmdBuff) > strlen("StartCollection")){
      sscanf(cmdBuff,"StartCollection %d",&gContinuousCollection);
    }
    
    if(gContinuousCollection){
      trace(DBG_USR1,"Starting Continuous Collection\r\n");
    }
    else{
      trace(DBG_USR1,"Starting One-shot Collection\r\n");
    }
    
#if TESTDATA
    gCurrentXCount = 1;
    gCurrentYCount = 1;
    gCurrentZCount = 1;
    
    gTotalXCount = 0;
    gTotalYCount = 0;
    gTotalZCount = 0;
#endif

    //startProfile();
    startCollection();

    return BLUSH_SUCCESS_DONE;
  }


  command BluSH_result_t SleepApp.getName(char *buff, uint8_t len){
    
    const char name[] = "Sleep";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t SleepApp.callApp(char *cmdBuff, uint8_t cmdLen,
					  char *resBuff, uint8_t resLen){
    call Sleep.goToDeepSleep(20);
    return BLUSH_SUCCESS_DONE;
  }

  
  /**
   * Allocate Buffer
   * @param numBytes Number of bytes in the buffer
   * @return NULL if the allocation fails, otherwise, return a buffer pointer
   */
  command uint8_t *BufferManagement.AllocBuffer(uint32_t numBytes){
    uint8_t *buffer = memalign(32,DMA_BUFFER_SIZE(numBytes));
    MALLOC_DBG(__FILE__,"BufferManagement.AllocBuffer",buffer,DMA_BUFFER_SIZE(numBytes));
    
    return buffer;
  }		
  
  command result_t BufferManagement.ReleaseBuffer(uint8_t *buffer){
    FREE_DBG(__FILE__,"BufferManagement.ReleaseBuffer",buffer);
    free(buffer);
    return SUCCESS;
  }
  
  
  /**
   * Write data.
   * @param offset Offset at which to write.
   * @param data data to write
   * @param numBytesWrite number of bytes to write
   * @return FAIL if the write request is refused. If the result is SUCCESS, 
   *   the <code>writeDone</code> event will be signaled.
   */
#define SEND_SAMPLEHEADER 0
#define SEND_DATA 1  
#define DO_RMS 1

  command result_t WriteData.write(uint32_t offset, uint8_t *data, uint32_t numBytesWrite){		
    int32_t numSamples;
    uint32_t *timestamp;

#if DO_RMS    
    int i;
#endif

#if TESTDATA
    uint16_t *pCurrentCount;
    uint32_t *pTotalCount;
    int16_t *pBuf16;
#else
    int16_t *pBuf16;
#endif
    
    sampleHeader_t *sh;
    uint8_t numBadPackets,numEntries;
    int16_t lastError;
    //    trace(DBG_USR1,"WriteData.write(%#x,%d)\r\n",(uint32_t)data,numBytesWrite);
    sh = (sampleHeader_t *)(data);
    
    numSamples = (int32_t)sh->numSamples;
    timestamp= &sh->microSecTimeStamp;
    numBadPackets = timestamp[1] >> 24;
    numEntries = timestamp[1] >> 16;
    lastError = (int16_t)(timestamp[1] & 0xffff);

    trace(DBG_TEMP," WriteData.write(%#x, %d) found a sampleRecord for channel %d w/outpUOM = %s containing %d samples captured at\r\n",	  
	  (uint32_t)data, 
	  numBytesWrite, 
	  sh->channelId, 
	  UOM_tasString(sh->outputUOM), 
	  numSamples);
    trace(DBG_TEMP,"%u:  last error = %d w/%d entries and %d bad packets}: Progress = %d/%d\r\n",
	  timestamp[0], 
	  lastError, 
	  numEntries,
	  numBadPackets,
	  sh->sampleOffset, 
	  sh->totalSamples);
   
#if TESTDATA
    switch(sh->channelId){
    case 1:
      pCurrentCount = &gCurrentXCount;
      pTotalCount = &gTotalXCount;
      break;
    case 2:
      pCurrentCount = &gCurrentYCount;
      pTotalCount = &gTotalYCount;
      break;
    case 3:
      pCurrentCount = &gCurrentZCount;
      pTotalCount = &gTotalZCount;
      break;
    default:
      trace(DBG_USR1,"FATAL ERROR:  unexpected data from channel %d\r\n", sh->channelId);
    }
    
    *pTotalCount += numSamples;
    if(((*pTotalCount)/numSamples % 100) == 0){
      trace(DBG_USR1,"Received %d Total Samples from channel %d\r\n",*pTotalCount, sh->channelId);
    }
    
    pBuf16 =(int16_t *)(data+sizeof(sampleHeader_t));
    for(i=0; i<numSamples; i++){
      if(*pCurrentCount != (uint16_t)(pBuf16[i] + 32768)){
	trace(DBG_USR1,"Missing value %d from datachannel %d..skipping to %d\r\n",*pCurrentCount, sh->channelId, (uint16_t)(pBuf16[i] + 32768));
	*pCurrentCount = (uint16_t)(pBuf16[i] + 32768);
      }
      (*pCurrentCount)++;
    }
#endif

#if DO_RMS
    if(sh->sampleWidth == 6){
      float x=0,y=0,z=0;
      float xrms=0,yrms=0,zrms=0;
      pBuf16 =(int16_t *)(data+sizeof(sampleHeader_t));
      
      for(i=0;i<numSamples;i++){
	xrms += (pBuf16[3*i]*sh->ADCScale + sh->ADCOffset)* (pBuf16[3*i]*sh->ADCScale + sh->ADCOffset);
	x += (pBuf16[3*i]*sh->ADCScale + sh->ADCOffset);
	
	yrms += (pBuf16[3*i + 1]*sh->ADCScale + sh->ADCOffset)* (pBuf16[3*i + 1]*sh->ADCScale + sh->ADCOffset);
	y += (pBuf16[3*i + 1]*sh->ADCScale + sh->ADCOffset);
	
	zrms += (pBuf16[3*i + 2]*sh->ADCScale + sh->ADCOffset)* (pBuf16[3*i + 2]*sh->ADCScale + sh->ADCOffset);
	z += (pBuf16[3*i + 2]*sh->ADCScale + sh->ADCOffset);
      }
      x = x/numSamples;
      y = y/numSamples;
      z = z/numSamples;
      xrms = sqrt(xrms/numSamples);
      yrms = sqrt(yrms/numSamples);
      zrms = sqrt(zrms/numSamples);
      trace(DBG_USR1,"Avg(x) = %f, RMS(x) = %f\r\n",x, xrms);
      trace(DBG_USR1,"Avg(y) = %f, RMS(y) = %f\r\n",y, yrms);
      trace(DBG_USR1,"Avg(z) = %f, RMS(z) = %f\r\n",z, zrms);

      
    }
    else{
      float x=0,xrms=0;
      pBuf16 =(int16_t *)(data+sizeof(sampleHeader_t));
      
      for(i=0;i<numSamples;i++){
	xrms += (pBuf16[i]*sh->ADCScale + sh->ADCOffset)* (pBuf16[i]*sh->ADCScale + sh->ADCOffset);
	x += (pBuf16[i]*sh->ADCScale + sh->ADCOffset);
      }
      x = x/numSamples;
      xrms = sqrt(xrms/numSamples);
      trace(DBG_USR1,"Avg(x) = %f, RMS(x) = %f\r\n",x, xrms);
    }
#endif

    
#if USB_SEND_DATA
    //call BulkSend.send(data,numBytesWrite);
    if(call USBSend.send(data,numBytesWrite, IMOTE_HID_TYPE_CL_GENERAL) == FAIL){
      trace(DBG_USR1,"ERROR:  Unable to send USB Data \r\n");
      signal WriteData.writeDone(data, numBytesWrite, SUCCESS);
    }
#else
    signal WriteData.writeDone(data, numBytesWrite, SUCCESS);
#endif
    return SUCCESS;
  }

  event result_t GenericSampling.prepareDone(uint8_t channel, result_t ok){
    
    if(ok){
      trace(DBG_USR1,"PrepareDone for channel %d succeeded\r\n",channel);
      gDoChannel[channel] = TRUE;
    }
    else{
      trace(DBG_USR1,"PrepareDone failed...aborting capture\r\n");
    }
    return ok;
  }
  
  task void startCollectionTask(){
    startCollection();
  }
  
  event result_t GenericSampling.samplingDone(uint8_t channel, result_t status, 
                              uint32_t numSamples){
    
    int i;
    bool startAgain = TRUE;
    
    if(status == SUCCESS){
      gChannelDone[channel] = TRUE;
        
    
      trace(DBG_USR1,"Sampling SUCCESS for channel %d\r\n",channel);
      //stopProfile();
      //printProfile(profilePrintAll);
      if(gContinuousCollection){
	for(i=0 ; i<MAX_TOTAL_CHANNELS; i++){
	  startAgain = startAgain & (gChannelDone[i] == gDoChannel[i]);
	}
	if(startAgain){
	  post startCollectionTask();
	}
      }
    }
    else{
      trace(DBG_USR1,"Sampling FAIL for channel %d\r\n",channel);
    }
    
    return SUCCESS;
  }

  event result_t GenericSampling.TargetChannelTriggered(uint8_t channel){
    
    return SUCCESS;
  }
#if USB_SEND_DATA
  event result_t USBSend.sendDone(uint8_t* packet, uint8_t type, result_t success){
    return signal WriteData.writeDone(packet, 320, success);
  }
#endif  

#if 0 
  event result_t BulkSend.sendDone(uint8_t* data, uint32_t numBytes, result_t success) {
    //signal WriteData.writeDone(data, numBytes, success);
    return success;
  }

  event result_t ReceiveData.receive(uint8_t* data, uint32_t length) {
    call BulkSend.send(data, length);
    return SUCCESS;
  }
#endif
}
