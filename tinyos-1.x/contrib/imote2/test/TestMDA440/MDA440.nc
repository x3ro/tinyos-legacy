/**
*
* interface that describes the functionalities exposed by the MDA440
* sensorboard
* 
*@author Robbie Adler
* 
**/

interface MDA440{
  command result_t init();
  
  // Helper commands
  command result_t enableHighSpeedChain();
  command result_t disableHighSpeedChain();
  command result_t enableLowSpeedChain();
  command result_t disableLowSpeedChain();

  command result_t selectMux0Channel(uint8_t channel);
  command result_t selectLowSpeedChannel(uint8_t channel);
  
  // Acquisition Related Commands
  command result_t getSamples(uint8_t *buffer, uint16_t NumSamples,uint32_t K);
  event result_t getSamplesDone(uint8_t *buffer);

    // Acquisition Related Commands
  command result_t startTach();
  command result_t stopTach(uint32_t *totalTime, uint32_t *totalSamples);
   
  //High Level selection routines
  command result_t turnOffBoard();	
  command result_t setAccelIn(uint8_t channel);
  command result_t setTempIn(uint8_t channel);
  command result_t setCurrentIn(uint8_t channel);
  command result_t enableTachTrigger(bool enable);
  command result_t setRefVoltageIn();
}
