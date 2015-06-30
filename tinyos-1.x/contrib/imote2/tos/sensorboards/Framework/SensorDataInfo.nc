
/***
 *SensorDataInfo interface that allows for a sideband channel of setting and getting parameters/information about the current collection
 *
 *
 *@author Robbie Adler
 ***/

interface SensorDataInfo{
  
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
}
