/**
 * @author Robbie Adler
 **/

interface DSPManager{
  
  command result_t initPostProcessing(uint32_t samplingRate, 
				      uint32_t numSamples, 
				      uint8_t sampleWidth, 
				      bool streaming, 
				      uint32_t warmup, 
				      uint32_t type, 
				      uint32_t function, 
				      TypeValItem *other);

  command result_t isSupportedFunction(uint32_t function);
  
  /*
   *return the amount of storage required for the required post-processing routing to function properly
   *
   *
   */
  command result_t getDataStorageSize(uint32_t *requestedSize, uint32_t *requiredSize, uint32_t *numRecords);
  
}
