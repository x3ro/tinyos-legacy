/**
 * @author Robbie Adler
 **/


interface TriggerManager{



  command result_t addTrigger(uint8_t boolOp, 
			      uint32_t triggerFunction,
			      float triggerValue, 
			      uint32_t triggerWindowSamples,
			      uint8_t triggerChannel,
			      uint8_t targetChannel);

  command void clearTrigger(uint8_t targetChannel);
  
  command result_t getOutputUOM(uint8_t channel, uint8_t *pUOM);
  
  /**
   * set the collection specification for a channel that the TriggerManager will collect data from.
   * 
   * @param channel: that this specification applies to.  Channel may either be a target channel 
   *                or a trigger channel
   * @param samplingRate:  the sampling rate that the data should be captured at
   * @param numSamples:  total number of samples that should be collected
   * @param sampleWidth: Width of each sample rounded up to the nearest number of bytes
   * @param headerSize:  additional space that should be allocated by the TriggerManager for header info.
                         Data will start being written at this offset
   * @param footerSize:  additional space that should be allocated by the TriggerManager for footer info.
   * 
   * @return FAIL if this is not possible; SUCCESS otherwise
   *
   **/
  command result_t setCollectionInfo(uint8_t channel, 
				     uint32_t samplingRate, 
				     uint32_t numSamples,
				     uint8_t  sampleWidth,
				     uint16_t headerSize, 
				     uint16_t footerSize);

  /**
   * set the collection specification need for channel warmup.
   * 
   * @param channel: that this specification applies to.  Channel may either be a target channel 
   *                or a trigger channel
   * @param type:  the type of sensor to be warmed up.  Used in the case of multiple different possible sensor types.
   * 
   * @return FAIL if this is not possible; SUCCESS otherwise
   *
   **/
  command result_t setWarmupInfo(uint8_t channel, 
				 uint32_t type);
  
  /**
   * Wait for the trigger condition on a list of channels
   * @param numChannels:  Number of channels that we're waiting on
   * @param targetChannels:  array of channels that we're waiting on
   * @param timeout:  timeout to keep while waiting for the current set of trigger conditions
   * 
   * @return FAIL if this is not possible; SUCCESS otherwise
   *
   **/
  command result_t waitForTrigger(uint8_t numChannels, uint8_t *targetChannels, uint32_t timeout);
  
  /**
   * cancle Waiting for the trigger condition on a list of channels
   * @param numChannels:  Number of channels that we're waiting on
   * @param targetChannels:  array of channels that we're waiting on
   * @param timeout:  timeout to keep while waiting for the current set of trigger conditions
   * 
   * @return FAIL if this is not possible; SUCCESS otherwise
   *
   **/
  command result_t cancelWaitForTrigger(uint8_t numChannels, uint8_t *targetChannels);
  
   /**
   * Trigger condition has either hit or failed for a list of channels
   * @param numChannels:  Number of channels that we're waiting on
   * @param targetChannels:  array of channels that we're waiting on
   * @param status:  SUCCESS if it is ok to start acquiring data, FAIL otherwise
   *
   * @return SUCCESS if handles, FAIL otherwise
   *
   **/
  event result_t waitForTriggerDone(uint8_t numChannels, uint8_t *targetChannels, result_t status);
  
  /**
   * a triggered data buffer that should be committed to memory.  
   * @param buffer:  data buffer
   * @param numBytes: amount of data to write
   * @param done:  TRUE if all data requested by the capture is in the buffer, FALSE if this is a data Fragment that needs to be committed beforehand.
   *
   * @return SUCCESS if handles, FAIL otherwise
   *
   **/
  event result_t TriggeredData(uint8_t channel, 
			       uint8_t *buffer, 
			       float ADCScale, 
			       float ADCOffset,
			       uint16_t numBytesWrite, 
			       uint16_t numBytesTotal, 
			       uint16_t numSamples,
			       uint64_t timestamp);
			       
  event result_t CollectionDone(uint8_t dataChannel);
}
