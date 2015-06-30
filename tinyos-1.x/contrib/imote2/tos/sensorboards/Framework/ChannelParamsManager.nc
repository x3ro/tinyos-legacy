/**
 * @author Robbie Adler
 **/

interface ChannelParamsManager{
  
  command result_t storeParams(uint8_t channel, 
			       uint32_t samplingRate, 
			       uint32_t numSamples, 
			       uint8_t sampleWidth, 
			       bool streaming, 
			       uint32_t type, 
			       uint32_t function, 
			       TypeValItem *other);
  
  command result_t writeSampleHeader(uint8_t *buffer);
  command size_t getHeaderSize();
  command result_t setNumSamples(uint16_t numSamples);
  command result_t setSampleOffset(uint32_t numSamples);
  command result_t incrementSampleOffset(uint16_t numSamples);
  command result_t setMicroTimestamp(uint64_t timestamp);
  command result_t setWallTimestamp(uint32_t timestamp);
  command result_t setADCScale(float ADCScale);
  command result_t setADCOffset(float ADCOffset);
  command result_t setSequenceID(uint32_t ID);
  command result_t setOutputUOM(uint8_t UOM);
  
}
