/***
 *
 * @author Robbie Adler
 *
 * This interface provides board specific channel enabling commands for use with the GenericSampling Sensorboard architecture
 *
 */
interface BoardManager{
  
  //operates on a list of exposed channels
  command result_t enableChannelsToBeSampled(uint8_t numChannels, uint8_t *channelList);
  
  event result_t enableChannelsToBeSampledDone(uint8_t numChannels, uint8_t *channelList);
 
  //operates on a list of dataChannels
  command result_t startDataChannels(uint8_t numChannels, uint8_t *channelList);
}
