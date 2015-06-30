/**
 *@author Robbie Adler
 **/

interface Audio{
  
  
  /****************************************
   *platform audio interface
   ****************************************/
  /**
   *Codec is ready to playback or record
   *
   *
   *
   *
   **/

  event void ready(result_t success);
  
  /**
   *mute playback on the port
   *
   *@param enable:  port is muted if TRUE, disabled if FALSE
   *
   *@return FAIL if error, SUCCESS otherwise
   **/

  command result_t mute(bool enable);
  event void muteDone(result_t success);
    
  
  /**
   *set playback volume
   *
   *@param volumeInDecibels:  signed integer denoting the requested volume in decibels
   *
   *@return FAIL if error, SUCCESS otherwise
   **/
  command result_t setVolume(int8_t volumeInDecibels);
  event void setVolumeDone(result_t success);
  
  /**
   *set sampling rate
   *
   *@param Fs:  Sampling rate of the codec (rounded to the nearest integer).  Note that the sampling rate cannot be changed while the interface is being used.  Thus, this interface will change the sampling rate for the next call to play/record.
   *
   *@return FAIL if error, SUCCESS otherwise
   **/
  
  command result_t setSamplingRate(uint32_t Fs);
  event void setSamplingRateDone(result_t success);

  /**
   *start the playback of stereo data.   
   *
   *@param buffer:  samples to playback.  Samples are 16bit stereo samples packed into a 32-bit word.  Left samples are in the low 16 bits.  Right samples are in the high 16 bits
   *@param numSamples:  total number of samples to play
   *
   *@return FAIL if error, SUCCESS otherwise
   **/
  command result_t audioPlay(uint32_t *buffer, uint32_t numSamples);
  event void audioPlayDone(uint32_t *buffer, uint32_t numSamples);


  /**
   *start the recording of stereo data.   
   *
   *@param buffer:  buffer to store samples into.  Samples are 16bit stereo samples packed into a 32-bit word.  Left samples are in the low 16 bits.  Right samples are in the high 16 bits.  Must be
   *                alligned on a 32byte boundary and have length that is integral number of 32 bytes
   *@param numSamples:  total number of samples to record.  Since samples are effectively 32 bits, buffer must be sized appropriately.
   *
   *@return FAIL if error, SUCCESS otherwise
   **/
  command result_t audioRecord(uint32_t *buffer, uint32_t numSamples);
  event void audioRecordDone(uint32_t *buffer, uint32_t numSamples);


}
