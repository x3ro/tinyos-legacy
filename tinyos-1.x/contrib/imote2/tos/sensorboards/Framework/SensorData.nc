
/***
 *SensorData interface the describes a data being returned in Task context from a sensor board
 *
 *
 *@author Robbie Adler
 ***/

interface SensorData{
  
   /**
   * getOutputUOM
   *
   * Function to get the outputUOM for the data returned by a call to SensorData.getSensorData under the current configuration
   * @param uint8_t* UOM.  Pointer to a uint8_t where the UOM will be returned
   *
   * @returns FAIL if there is not enough information to return a valid UOM, SUCCESS otherwise
   **/
  command result_t getOutputUOM(uint8_t *UOM);
  
  /**
   *
   * setSensorType 
   *
   * Function to allow the sensortype that should be associated with the current collection to be set
   *
   *@return FAIL if this is not called on a valid DataChannel, SUCCES otherwise.
   **/

  command result_t setSensorType(uint32_t sensorType);
  
  /**
   *
   * setSamplingRate 
   *
   * Function to allow the sampling rate associated with the current collection to be set
   *
   * @param requestedSamplingRate is the rate requested of the data providing component
   * @param actualSamplingRate is the rate that the data providing component will actually return for the given request
   *
   *@return FAIL if this is not called on a valid DataChannel, SUCCESS otherwise.
   **/
  command result_t setSamplingRate(uint32_t requestedSamplingRate, uint32_t *actualSamplingRate);

  /**
   *
   * setSampleWidth 
   *
   * Function to allow the sampling width associated with the current collection to be set
   *
   * @param requestedSampleWidth is the sample width requested in bytes
   * 
   *@return FAIL if this is not called on a valid DataChannel or if the requestedSampleWidth is not supported, SUCCESS otherwise.
   **/
  command result_t setSampleWidth(uint8_t requestedSampleWidth);
  

  command result_t getSensorData(uint8_t *buffer, uint32_t numSamples);
  
  /**
   *
   *buffer = pointer to buffer that returns data
   *numSamples = number of samples requested
   *timestamp = timestap that this buffer was received at
   *
   *@return pointer to new buffer to fill with samples, or NULL if done
   **/

  event uint8_t *getSensorDataDone(uint8_t *buffer, uint32_t numSamples, uint64_t timestamp, float ADCScale, float ADCOffset);

  /**
   * event that gets signalled once the actual process of sampling has completely stopped.  This event will be signaled
   * sometime after getSensorDataDone has a null returned to it
   *
   *
   *
   **/
  
  event result_t getSensorDataStopped();
}
