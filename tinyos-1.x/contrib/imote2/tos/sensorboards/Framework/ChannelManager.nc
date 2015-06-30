/**
 * @author Robbie Adler
 **/


interface ChannelManager{
  
  /**
   *command to "start" a list of channels.  In the context of the channel manager, the
   *start function is used to actually start the sampling process on a channel
   *
   *
   *
   **/
  
  command result_t startChannels(uint8_t numChannels, 
				 uint8_t *channelList);

  
  /**
   *
   *event that indicates that the channels have successfully been started and that it is ok
   *to start warming them up
   *
   *
   **/
  
  event result_t startChannelsDone(uint8_t numChannels, 
				   uint8_t *channelList);
  /**
   *command to "stop" a list of channels.  In the context of the channel manager, the
   *stop function is used to actually stop the sampling process on group of channels
   *
   *
   *
   **/
  
  command result_t stopChannels(uint8_t numChannels, 
			 uint8_t *channelList);
  
  /**
   * command to "warmup" a bunch of channels.  When the warmup time has elapsed,
   * warmupDone will be signalled
   *
   *
   *
   *
   **/
  command result_t warmupChannels(uint8_t numChannels, 
				  uint8_t *channelList);
  
  event result_t warmupChannelsDone(uint8_t numChannels, 
				    uint8_t *channelList);
  
  
  /**
   * Wait for data on a list of channels
   * @param numChannels:  Number of channels that we're waiting on
   * @param targetChannels:  array of channels that we're waiting on
   * @param timeout:  timeout to keep while waiting for the current set of trigger conditions
   * 
   * @return FAIL if this is not possible; SUCCESS otherwise
   *
   **/
  command result_t waitForData(uint8_t numChannels, uint8_t *targetChannels);

  
  /**
   * all the channel mananger to prepare a channel to be sampled.
   * 
   *
   *
   *
   *
   *
   * @param memoryRequested: pointer to a variable that the ChannelManager may store information about the
   * amount of memory that it thinks is requested for this transaction
   *
   * @param memoryRequired: pointer to a variable that the ChannelManager may store information about the
   * amount of memory that it thinks is required for this transaction
   *
   * @return: SUCCESS if all of the parameters are valid options, FAIL otherwise
   **/

  command result_t prepareChannel(uint8_t channel, 
				  uint32_t samplingRate, 
				  uint32_t numSamples, 
				  uint8_t sampleWidth, 
				  bool streaming, 
				  uint32_t warmup, 
				  uint32_t type, 
				  uint32_t function, 
				  TypeValItem *other);
							  
  event result_t DataReady(uint8_t channel, uint16_t numBytes, bool done);

  command result_t addTrigger(uint8_t boolOp, 
			      uint32_t triggerFunction,
			      float triggerValue, 
			      uint32_t triggerWindowSamples,
			      uint8_t triggerChannel,
			      uint8_t targetChannel);

  command void clearTrigger(uint8_t targetChannel);

  
}
