// $Id: TestBasicSensorboardDriverM.nc,v 1.1 2006/10/25 15:05:39 radler Exp $

/**
 * @author Robbie Adler
 **/

includes trace;
includes sensorboard;
#include "app.h"

module TestBasicSensorboardDriverM {
  provides {
    interface StdControl;
    
    interface BufferManagement;
    interface WriteData;
    
    interface BluSH_AppI as SleepApp;
    interface BluSH_AppI as GetData;    
  }
  uses {
    interface Timer;
    interface Leds;
    interface Sleep;
    interface HPLUART as UART;
    interface GenericSampling;
  }
}
implementation {
#include "triggerFunctions.h"
#include "triggerOps.h"
#include "postprocessingFunctions.h"
#include "GenericSampling.h"
#include "sensorboard.h"
#include "sampleHeader.h"

  /**
   * Initialize the component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  
  //I'm being lazy for now....UARTBUFFERLEN MUST BE 2x NUMSAMPLES
  
  uint32_t dataBufferPos = ~((uint32_t)0);
  
  uint8_t *gWriteProcessBuffer;
  uint32_t gWriteProcessBufferLength=0;

  uint8_t gPrepareDoneCount;
  uint8_t gChannelList[2];
  uint8_t gPrepareDoneTarget;
  
  
  int32_t gXTotal=0, gYTotal=0, gZTotal=0;
  
  bool gAddedTrigger = FALSE;
  
  command result_t StdControl.init() {

      return call Leds.init();
  }
    
  /**
   * Start things up.  This just sets the rate for the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.start() {
    return call Timer.start(TIMER_REPEAT, 500);
    return SUCCESS;
  }

  /**
   * Halt execution of the application.
   * This just disables the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.stop() {
    return call Timer.stop();
    return SUCCESS;
  }


  /**
   * Toggle the red LED in response to the <code>Timer.fired</code> event.  
   *
   * @return Always returns <code>SUCCESS</code>
   **/  

  event result_t Timer.fired()
  {
    int32_t localXTotal, localYTotal, localZTotal, localTotalSamples;
    atomic{
      localXTotal = gXTotal;
      localYTotal = gYTotal;
      localZTotal = gZTotal;
      localTotalSamples = 1;
      gXTotal = 0;
      gYTotal = 0;
      gZTotal = 0;
      // gTotalSamples = 0;
      
    }
    localXTotal = (localXTotal*4*1000)/(localTotalSamples*4096);
    localYTotal = (localYTotal*4*1000)/(localTotalSamples*4096);
    localZTotal = (localZTotal*4*1000)/(localTotalSamples*4096);
    
    //trace(DBG_USR1,"X=%d, Y=%d, Z=%d\r\n",localXTotal, localYTotal, localZTotal);
    call Leds.redToggle();
    return SUCCESS;
  }

  command BluSH_result_t GetData.getName(char *buff, uint8_t len){
    
    const char name[] = "GetData";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  task void putDataTask(){
    uint8_t * data8ptr = (uint8_t *)gWriteProcessBuffer;
    if(dataBufferPos < gWriteProcessBufferLength ){
      //call UART.put(data8ptr[dataBufferPos]);
      dataBufferPos++;
    }
    else{
      if(gWriteProcessBuffer > 0){
	signal WriteData.writeDone(gWriteProcessBuffer, gWriteProcessBufferLength, SUCCESS);
      }
    }
  }
  
  #define WARMUP (1500000)
  //#define WARMUP (00000)

  
  command BluSH_result_t GetData.callApp(char *cmdBuff, uint8_t cmdLen,
					 char *resBuff, uint8_t resLen){
    uint32_t channel, numSamples, samplingRate, type,width;
    //Format = GetData channel numSamples samplingRate 
    
    TypeValItem tvi;
    tvi.count=0;
    
    if(strlen(cmdBuff) > strlen("GetData ")){
      sscanf(cmdBuff,"GetData %d %d %d", &channel, &numSamples, &samplingRate);
      trace(DBG_USR1,"Getting %d samples @ %dHz from channel %d\r\n", numSamples, samplingRate,channel);
      
      gPrepareDoneCount=0;
      gPrepareDoneTarget=1;
      
      //make sure that we get a valid sensortype ;o)
      type = channelCapabilitiesTable[channel].supportedSensorTypes->elements[0];
      width = channelCapabilitiesTable[channel].supportedSampleWidths->elements[0]; 
      gAddedTrigger = FALSE;
      if(call GenericSampling.prepare((uint8_t)channel, 
				      samplingRate, 
				      numSamples, 
				      width, 
				      FALSE, 
				      WARMUP,
				      type, 
				      0, 
				      &tvi) == FAIL){
	trace(DBG_USR1,"GenericSampling.prepare FAILED\r\n");
      }
    }
    else{
      trace(DBG_USR1,"GetData channel numSamples samplingRate\r\n");
    }
    return BLUSH_SUCCESS_DONE;
  }


  async event result_t UART.get(uint8_t data){
    //don't care about the data
    return SUCCESS;
  }
  
 
  async event result_t UART.putDone(){
    post putDataTask();
    return SUCCESS;
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
    uint8_t *buffer = malloc(numBytes);
    trace(DBG_USR1,"BufferManagement.AllocBuffer allocated buffer %#x of %d bytes\r\n",(uint32_t)buffer, numBytes);
    
    return buffer;
  }		
  
  command result_t BufferManagement.ReleaseBuffer(uint8_t *buffer){
    trace(DBG_USR1,"BufferManagement.ReleaseBuffer passed allocated buffer %#x\r\n",(uint32_t)buffer);
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
  
  command result_t WriteData.write(uint32_t offset, uint8_t *data, uint32_t numBytesWrite){		
    int i;
    int16_t *pBuf16;
    int32_t numSamples;
    int32_t x,y,z;

    
    sampleHeader_t *sh;
    
    trace(DBG_USR1,"WriteData.write(%d,%#x,%d)\r\n",offset,(uint32_t)data,numBytesWrite);
    sh = (sampleHeader_t *)(data);
    
    numSamples = (int32_t)sh->numSamples;
    trace(DBG_USR1,"Found a sampleRecord for channel %d containing %d samples\r\n",sh->channelId,numSamples);
    
    x=y=z=0;
    pBuf16 =(int16_t *)(data+sizeof(sampleHeader_t));
    
    for(i=0;i<numSamples*3;i+=3){
      x += pBuf16[i];
      y += pBuf16[i+1];
      z += pBuf16[i+2];
    }
    x = (x*1000);
    x = x/numSamples;
    x = (x*4)/4096;
   
    y = (y*1000);
    y = y/numSamples;
    y = (y*4)/4096;
    
    z = (z*1000);
    z = z/numSamples;
    z = (z*4)/4096;
    
    trace(DBG_USR1,"Avg(x) = %dmg Avg(y) = %dmg Avg(z) = %dmg\r\n",x,y,z);
            
    signal WriteData.writeDone(data,numBytesWrite,SUCCESS);
    return SUCCESS;
#if 0
    //we successfully sampled...very cool!
#if SEND_SAMPLEHEADER
    dataBufferPos = 0;
    gWriteProcessBufferLength = numBytesWrite;
#else
    dataBufferPos = sizeof(sampleHeader_t)+12;
    gWriteProcessBufferLength = numBytesWrite;
#endif
    
    //let's print out the first sample of each buffer
    pBuf32 = (int32_t *)data;
    trace(DBG_USR1,"found %d sample records\r\n",pBuf32[0]);
    for(i=0; i<pBuf32[0]; i++){
      sampleHeader_t *sh = (sampleHeader_t *)(data + pBuf32[i+1]);
      int16_t *vals = (int16_t *)(data + pBuf32[i+1] + sizeof(sampleHeader_t));
      trace(DBG_USR1,"Found a sampleRecord with ADCScale = %E, ADCOffset = %E,\r\n first raw data = %#x, first converted value = %f\r\n",sh->ADCScale,sh->ADCOffset,vals[0], vals[0]*sh->ADCScale + sh->ADCOffset);
    }
    
    gWriteProcessBuffer=data;
    
    //hack to avoid sending out sampleheader...since I don't care about it for now
    
    
    return SUCCESS;
#endif
  }

  event result_t GenericSampling.prepareDone(uint8_t channel, result_t ok){
    
    
    if(ok){
      trace(DBG_USR1,"PrepareDone for channel %d succeeded\r\n",channel);
      gChannelList[gPrepareDoneCount] = channel;
      gPrepareDoneCount++;
#if 0
      if(gAddedTrigger == FALSE){
	call GenericSampling.ClearTrigger(channel);
	call GenericSampling.AddTrigger(TRIGGER_OP_OR, 
					TRIGGER_GT,
					1500, 
					1,
					channel,
					channel);
	gAddedTrigger = TRUE;
      }
#endif
      if(gPrepareDoneCount == gPrepareDoneTarget){
	trace(DBG_USR1,"Got all PrepareDone Events...starting sampling\r\n");
	call GenericSampling.start(gPrepareDoneCount, gChannelList,0);
      }
      else if(gPrepareDoneCount > gPrepareDoneTarget){
	trace(DBG_USR1,"ASSERT....too many prepareDones!!\r\n");
      }
    }
    else{
      trace(DBG_USR1,"PrepareDone failed...aborting capture\r\n");
    }
    return ok;
  }
  
  event result_t GenericSampling.samplingDone(uint8_t channel, result_t status, 
                              uint32_t numSamples){
    if(status == SUCCESS){
      trace(DBG_USR1,"Sampling SUCCESS for channel %d\r\n",channel);
      post putDataTask();
    }
    else{
      trace(DBG_USR1,"Sampling FAIL for channel %d\r\n",channel);
    }
        
    return SUCCESS;
  }

  event result_t GenericSampling.TargetChannelTriggered(uint8_t channel){
    
    return SUCCESS;
  }

}
