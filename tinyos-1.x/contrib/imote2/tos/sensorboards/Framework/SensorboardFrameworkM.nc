includes downsample;
includes sensorboard;

module SensorboardFrameworkM{
  provides {
    interface StdControl;
    interface GenericSampling;
  }
  uses {
    interface SSP;
    interface Timer as AcquisitionTimeout;
    interface ChannelManager;
    
    interface StdControl as DependentControl;
  }
}
implementation {

#include "frameworkconfig.h"
#include "paramtask.h"

  result_t acquisitionDone(float scale);
  result_t triggerADCAcquisition();
  result_t doADCAcquisition();
  result_t cleanupSamplingState();
  result_t cleanupTimers();
 
  // paramaterized tasks
  
  void postPrepareDone(uint32_t arg);
  DEFINE_PARAMTASK(postPrepareDone);

  void postPrepareDoneFail(uint32_t arg);
  DEFINE_PARAMTASK(postPrepareDoneFail);

  void printList(char *header, uint8_t numItems, uint8_t* list) __attribute__ ((C,spontaneous));
  
  void printList(char *header, uint8_t numItems, uint8_t* list){
    char *buffer, tempBuf[8];
    buffer = malloc(256);
    
    if(buffer){
      int i, currentPos, currentCount;
      if(strlen(header) < 256){
	memcpy(buffer, header, strlen(header));
      }
      else{
	return;
      }
      currentPos = strlen(header);
      for(i=0; i<numItems; i++){
	currentCount = snprintf(tempBuf,8,"%d ",list[i]);
	if((currentCount > 0) && ((currentCount + currentPos) < 255)){
	  memcpy(buffer+currentPos,tempBuf, currentCount);
	  currentPos += currentCount;
	}
      }
      buffer[currentPos] = 0;
      trace(DBG_USR1,"%s\r\n",buffer);
      free(buffer);
    }
  }
  

#if 0   
  uint8_t *getNextBuffer(){
    int i;
    uint8_t *ret = NULL;
    atomic{
      for(i=0;i<NUMBUFFERS; i++){
	if(tempBuffers[i].inuse == FALSE){
	  tempBuffers[i].inuse = TRUE;
	  ret = (uint8_t *)tempBuffers[i].buf;
	  break;
	}
      }
    }
    return ret;
  }

  void returnBuffer(short *buf){
    int i;
    atomic{
      for(i=0;i<NUMBUFFERS; i++){
	if(tempBuffers[i].buf == buf){
	  tempBuffers[i].inuse = FALSE;
	}
      }
    }
  }
  
  void initBuffer(){
    int i;
    atomic{
      for(i=0;i<NUMBUFFERS; i++){
	tempBuffers[i].inuse = FALSE;
      }
    }
  }
#endif
    
  command result_t StdControl.init(){
      
    //    int i;

    trace(DBG_USR1,"\r\nInitializing %s\r\n", mySensorboardName);

#if 0
    initBuffer();
    atomic{
      //init global state that needs to be init'd
      gTotalTachTime=0;
      gTotalTachSamples=0;
      gLastTachValue=0;
      gSamplingInProgress = FALSE;
      for(i=0;i<MAX_SIMUL_CHANNELS;i++){
	gSampleInfo[i].sampleHeader.channelId = INVALID_CHANNEL_ID;
      }
      for(i=0;i<TOTAL_CHANNELS;i++){
	call GenericSampling.ClearTrigger(i);
      }
      
    }

    //SSP must be told whether it's Master or Slave to SCLK or SFRM and then
    //it can be inited.  All other parameters must be set after init is
    // called
    
    //read in our calibration values
#if EEPROM_PRESENT
    //read gVREFCal and gACCELCal out of the EEPROM
    //    call EEPROM.read(  );
    gVREFCal = 2.5;
    gACCELCal = 10.025;
#else
    gVREFCal = 2.5;
    gACCELCal = 10.025;
#endif
    
    //currently, this means that the board is not present
      
    gADCOffsetInt =0;
    gADCOffset = 0;
    gADCScale = 7.8920e-5;
    gADCAccelScale = 1.9e-4;
    gADCAccelDCScale = 5.024;
#endif

    call DependentControl.init();
    
    return SUCCESS;
  }
  
  command result_t StdControl.start(){
    
    call DependentControl.start();
    return SUCCESS;
  };

  command result_t StdControl.stop(){
    
    call DependentControl.stop();
    return SUCCESS;
  };
  
  event result_t AcquisitionTimeout.fired(){
    
    trace(DBG_USR1,"Acquisition Timeout\r\n");
    //we've timed out....
#if 0
    int i;
    bool samplingInProgress;
    
    atomic{
      samplingInProgress = gSamplingInProgress;
    }
    if(samplingInProgress == TRUE){
      
      //stop timers ASAP!!!
      cleanupTimers();
      
      trace(DBG_USR1,"ERROR:  GenericSampling Acquisition Timeout\r\n");
      
      //if we're still sampling....need to cleanup and notify
      for(i=0; i<MAX_SIMUL_CHANNELS; i++){
	if(gSampleInfo[i].sampleHeader.channelId!= INVALID_CHANNEL_ID){
	  //write the wrapperHeader and the sampleheader for this acquisitions
	  WRITEHEADER(gSampleInfo[i].dataBuffer,0,1);
	  WRITEHEADER(gSampleInfo[i].dataBuffer,4,WRAPPERHEADER_FIRSTOFFSET);
	  //set numSamples to 0 so that the sampleHeader is consistent with sampleBody.
	  gSampleInfo[i].sampleHeader.numSamples = 0;
	  memcpy(gSampleInfo[i].dataBuffer+WRAPPERHEADER_FIRSTOFFSET,
		 &(gSampleInfo[i].sampleHeader),
		 sizeof(sampleHeader_t));
	  	  
	  //do not support partial acquisitions because we have extremely
	  //limited insight into where we are at in the acquisition
	  
	  /*call WriteData.write(0, 
			       gSampleInfo[i].dataBuffer, 
			       sizeof(sampleHeader_t)+WRAPPERHEADER_FIRSTOFFSET);	
	  */
	  signal GenericSampling.samplingDone(gSampleInfo[i].sampleHeader.channelId,FAIL,0);  
	}
      }
      
      cleanupSamplingState();
      
    }
#endif
    return SUCCESS;
  }
  
  result_t cleanupTimers(){
    //this should work regardless of whether we have a timeout or not
    call AcquisitionTimeout.stop();
    return SUCCESS;
  }
  
  result_t cleanupSamplingState(){
    //sampling has now been officially concluded...need to clean up state
    int i;
    
#if 0
    atomic{
      gSamplingInProgress=FALSE;
      gGse=FALSE;
      gGseCal=FALSE;
    }
    
    cleanupTimers();
    for(i=0; i<MAX_SIMUL_CHANNELS; i++){
      gSampleInfo[i].sampleHeader.channelId = INVALID_CHANNEL_ID;
    } 
      
    //turn off the board...select channel 0
#endif
    return SUCCESS;
  }

  
  void postPrepareDone(uint32_t arg){
    uint8_t channelID = (uint32_t)arg;
    //TODO:  do some checking here based on the arguments
    signal GenericSampling.prepareDone(channelID,SUCCESS);
  }

  void postPrepareDoneFail(uint32_t arg){
    uint8_t channelID = (uint32_t)arg;
    //TODO:  do some checking here based on the arguments
    signal GenericSampling.prepareDone(channelID,FAIL);
  }
  

  /**
   * Prepare to peform sampling. 
   * @param channel The sensor channel id
   * @param samplingRate The sampling rate specified in Hz
   * @param numSamples The number of samples to collect
   * @param sampleWidth The number of bits per sample 
   * @param streaming TRUE for streaming (sampling will only
   *   end when stop is called.
   * @param warmup The sensor warmup time in microseconds, this will imply
   *   that once the start function is called, the sensor will turn on and 
   *   the samples will be dropped for at least warmup microseconds
   * @param type The sensor type to be sampled.  Some boards might expose 
   *   multiple type sensors on one channel.  The value is an enum that is 
   *   sensor board specific
   * @param function The sensor driver can support some form of post 
   *   processing capability (e.g. average, FFT, etc).  This supported values
   *   in this field will be sensor board specfic. Note that the meaning 
   *   of the numSamples parameter will be dependent on the post processing 
   *   function.
   * @param other this is an array of type value pairs that will capture
   *   board specific parameters that don't need to be applied to all boards
   *   The last item in the array will have a type 0 to indidate end of list
   * @return If the result is SUCCESS, <code>ready</code> will be signaled
   *   If the result is FAIL, no sampling will happen.
   */  

  command result_t GenericSampling.prepare(uint8_t channel, 
					     uint32_t samplingRate, 
					     uint32_t numSamples, 
					     uint8_t sampleWidth, 
					     bool streaming, 
					     uint32_t warmup, 
					     uint32_t type, 
					     uint32_t function, 
					     TypeValItem *other){
    
    /***************
cases that need to be watched out for:
    
1.) preparing the same channel multiple times....error or override?
2.) We currently allow at most 2 simul channels of which 1 can be a data channel and 1 can be a tach
3.) Must check that we have at most 1 data channel
4.) Must check that we have at most 1 tach channel

    *************/
    if(channel > LAST_CHANNEL){
      trace(DBG_USR1,"FAIL:  GenericSampling.prepare called with invalid channelId\r\n");
      return FAIL;
    }
    
    if(call ChannelManager.prepareChannel(channel, 
					  samplingRate, 
					  numSamples, 
					  sampleWidth,
					  streaming, 
					  warmup, 
					  type, 
					  function, 
					  other) == SUCCESS){
      
      POST_PARAMTASK(postPrepareDone,channel);
      return SUCCESS;
    }
    else{
      return FAIL;
    }
  }
  
  
  /**
   * Prepare a trigger channel
   * @param channel The sensor channel id
   * @param samplingRate The sampling rate specified in Hz
   * @param numSamples The number of samples to collect
   * @param sampleWidth The number of bits per sample 
   * @param streaming TRUE for streaming (sampling will only
   *   end when stop is called.
   * @param warmup The sensor warmup time in microseconds, this will imply
   *   that once the start function is called, the sensor will turn on and 
   *   the samples will be dropped for at least warmup microseconds
   * @param type The sensor type to be sampled.  Some boards might expose 
   *   multiple type sensors on one channel.  The value is an enum that is 
   *   sensor board specific
   * @param function The sensor driver can support some form of post 
   *   processing capability (e.g. average, FFT, etc).  This supported values
   *   in this field will be sensor board specfic. Note that the meaning 
   *   of the numSamples parameter will be dependent on the post processing 
   *   function.
   * @param other this is an array of type value pairs that will capture
   *   board specific parameters that don't need to be applied to all boards
   *   The last item in the array will have a type 0 to indidate end of list
   * @param storeData if TRUE the trigger channel is sampled like a regular
   *   channel and the data is stored in the same way.  If FALSE, the trigger
   *   channel data is just used for the purpose of triggering another channel
   * @return If the result is SUCCESS, <code>ready</code> will be signaled
   *   If the result is FAIL, no sampling will happen.
   */
  command result_t GenericSampling.prepareTrigger(uint8_t channel, 
						  uint32_t samplingRate, 
						  uint32_t numSamples, 
						  uint8_t sampleWidth, 
						  bool streaming, 
						  uint32_t warmup, 
						  uint32_t type, 
						  uint32_t function, 
						  TypeValItem *other, 
						  bool storeData){
    
    trace(DBG_USR1,"ERROR:  GenericSampling.prepareTrigger called.  This should not happen!\r\n");
    return FAIL;
  }


  /**
   * Report if sampling can be started
   * @param channel The sensor channel id
   * @param ok SUCCESS if sampling can be started by calling 
   *   <code>start</code>, FAIL otherwise
   * @return Ignored
   */
  default event result_t GenericSampling.prepareDone(uint8_t channel, result_t ok){
    return SUCCESS;
  }
     
  /** 
   * Start sampling requested by previous <code>prepare</code>
   *   If multiple channels are being passed in a list, then the sensor
   *   board will start all the channel simultaneously if supported.  However
   *   if individual start calls are executed, these channels are assumed to
   *   be independent. 
   *   If a trigger is setup and linked to a target channel, when the target 
   *   channel is started, the trigger channel will be started instead and 
   *   the target channel will only be started if the trigger is invoked.
   * @param numChannels The number of channels listed in the channelList
   * @param channelList An array of channel id values to be started
   * @param timeout if the complete collection is not done within timeout
   *   msec, the board will stop the capture and signal the samplingDone
   *   with a timeout error condition
   * @return SUCCESS if sampling started (<code>done</code> will be signaled
   *   when it complates), FAIL if it didn't.
   */
  command result_t GenericSampling.start(uint8_t numChannels, 
					 uint8_t *channelList, 
					 uint32_t timeout){
    
    //need to figure out whether we have info about the channels that are being requested
    //gSampleHeaders contains the information about the channels that we're currently aware of
    //
    
    //start channels will actuall start the channels and do some error checking.
    //in this module's model, channels will get started, warmed up, and then tested for trigger
    //conditions before getting written

#if 1    
    struct mallinfo minfo = mallinfo();
    
    trace(DBG_USR1,"Total space allocated from system = \t%10u\r\n",minfo.arena);
    trace(DBG_USR1,"Number of non-inuse chunks = \t\t%10u\r\n", minfo.ordblks);
    trace(DBG_USR1,"Number of MMAPPED regions = \t\t%10u\r\n", minfo.hblks);
    trace(DBG_USR1,"Total space in MMAPPED regions = \t%10u\r\n", minfo.hblkhd);
    trace(DBG_USR1,"Total allocated space = \t\t%10u\r\n", minfo.uordblks);
    trace(DBG_USR1,"Total non-inuse space = \t\t%10u\r\n", minfo.fordblks);
    trace(DBG_USR1,"top-most, releasable space = \t\t%10u\r\n", minfo.keepcost);
#endif   
    
    printList("GenericSampling.start() called with channel #'s: ", numChannels, channelList);
    
    if(call ChannelManager.startChannels(numChannels, channelList) == FAIL){
      return FAIL;
    }
    
    //start the overall acquisition timeout timer
    if(timeout){
      call AcquisitionTimeout.start(TIMER_ONE_SHOT,timeout);
    }
    
    return SUCCESS;
  }

  event result_t ChannelManager.startChannelsDone(uint8_t numChannels, uint8_t *channelList){
    call ChannelManager.warmupChannels(numChannels, channelList);
    return SUCCESS;
  }
  
  #define MAX_TRIGGER_TIMEOUT (1000)

  event result_t ChannelManager.warmupChannelsDone(uint8_t numChannels, 
						   uint8_t *channelList){
    
    trace(DBG_USR1,"Channel warmup completed\r\n");
    call ChannelManager.waitForData(numChannels, channelList);
    return SUCCESS;
  }
  
  /** 
   * Stop sampling started by earlier <code>start</code>
   * @param numChannels The number of channels listed in the channelList
   * @param channelList An array of channel id values to be started
   * @return SUCCESS if sampling can be stopped (<code>done</code> will 
   *   be signaled shortly), FAIL if it can't.
   */
  command result_t GenericSampling.stop(uint8_t numChannels, 
					uint8_t *channelList){

    printList("GenericSampling.stop() called with channel #'s: ", numChannels, channelList);
    
    return call ChannelManager.stopChannels(numChannels, channelList);
  }

  /**
   * Report sampling completion
   * @param channel The sensor channel id
   * @param status SUCCESS if sampling was succesful, FAIL if it failed. Failure
   *   may be due to the sampling interval being too short or to a data
   *   logging poblem.
   * @param numSamples Number of samples of data collected
   * @return Ignored
   */
  default event result_t GenericSampling.samplingDone(uint8_t channel, 
						      result_t status, 
						      uint32_t numSamples){

    return SUCCESS;
  }

  /**
   * This function supports triggering channel sampling from one or many
   *   channels based on the behavior of a trigger channel.
   * 
   * @param boolOp Boolean operation to combine different triggers.  
   *   Supported enum is board specific
   * @param triggerFunction The supported functions are board specific
   *   examples are rising edge, falling edge, max, min, average
   * @param triggerValue The tigger function evaluates the function and 
   *   compares to the value to evaulate the trigger
   * @param triggerChannel the channel id of the trigger
   * @param targetChannel the channel id of the triggered channel 
   * 
   * @return SUCCESS indicates the trigger was setup
   **/
    

  command result_t GenericSampling.AddTrigger(uint8_t boolOp, 
					      uint32_t triggerFunction,
					      float triggerValue, 
					      uint32_t triggerWindowSamples,
					      uint8_t triggerChannel,
					      uint8_t targetChannel){

    return call ChannelManager.addTrigger(boolOp, 
					  triggerFunction, 
					  triggerValue, 
					  triggerWindowSamples,
					  triggerChannel, 
					  targetChannel);
  }

  /**
   * This function clears the preset trigger functionality
   * 
   * @param targetChannel the channel id of the target channel
   */
  command void GenericSampling.ClearTrigger(uint8_t targetChannel){
    
    return call ChannelManager.clearTrigger(targetChannel);
  }

  /**
   * Report that a target channel has been triggered (trigger invoked)
   * @param channel The target channel id 
   * @return Ignored
   */
  default event result_t GenericSampling.TargetChannelTriggered(uint8_t channel){
    return SUCCESS;
  }

  /**
   * Retrieve information about a supported board feature
   * @param feature supported list of features to be interogated is board
   *   specific.  This will be an enumerated list that is defined across
   *   sensor boards, and each sensor board will support a subset of the
   *   range.  There is a special feature (type 0), which will return the
   *   list of supported features by this board rather than the infromation
   *   about a specific feature.
   * @param options This is an array options relating to the passed feature
   *   The driver will allocate the array.  The caller shouldn't modify 
   *   the contents of the array, nor can it assume that the array will
   *   persist after the function returns.
   * @return The function returns the number of entries in the array
   *   0 means that the feature is not supported
   */
  command uint32_t GenericSampling.GetSupportedFeature(uint32_t feature, 
						       uint32_t *options){
    return 0;
  }

  /**
   * Returns the actual data width of the sample returned by the board
   *   given a desired sample width.  e.g. the caller can request 14 bit
   *   samples and the board can pack it into 16 bit samples. It also
   *   indicates the endianess of the samples
   * @param sampleWidth desired number of bits per sample
   * @param dataWidth driver will return the data width in bits used to
   *   pack these samples
   * @param littleEndian driver will return the endianess of the data.  
   *   FALSE for little endian, FALSE for big endian
   *   
   */ 

  command void GenericSampling.getSampleInfo(uint8_t sampleWidth, 
					     uint8_t *dataWidth, 
					     bool *littleEndian){

    return;
  }

  /**********************
WriteData interface
  *******************/
  

  event result_t ChannelManager.DataReady(uint8_t channel, uint16_t numSamples, bool done){
    if(done){
      cleanupTimers();
      return signal GenericSampling.samplingDone(channel, SUCCESS, numSamples); 
    }
    return SUCCESS;
  }
}
