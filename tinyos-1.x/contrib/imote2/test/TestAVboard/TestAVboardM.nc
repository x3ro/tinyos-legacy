/**
 * @author Robbie Adler
 **/


module TestAVboardM{
  provides{
    interface StdControl;
  }
  uses{
    interface Audio;
    interface StdControl as CodecControl;
  }
}

implementation{

#define BUFFERLEN 32768
  uint32_t gBuffer[BUFFERLEN] __attribute__((aligned(32)));
  uint32_t gNumSamples = BUFFERLEN/4;
    
  
  command result_t StdControl.init(){
    result_t res;
    //perform custom initialization here
    
    res = call CodecControl.init();
    
    return res; 
  }

  command result_t StdControl.start(){
    result_t res;
    //perform custom starting here
    
    res = call CodecControl.start();
    return res; 
  }
  
  
  command result_t StdControl.stop(){
    //perform custom stopping here
    result_t res;
    
    res = call CodecControl.stop();
    return res;
  }
  
  /****************************************
   *platform audio interface
   ****************************************/
  
  event void Audio.ready(result_t success){
    
    trace(DBG_USR1,"Audio Ready.  Audio Record returned %d\r\n",call Audio.audioRecord(gBuffer,gNumSamples));
    
    return;
  }
  
  event void Audio.muteDone(result_t success){

    return;
  }
    
  event void Audio.setVolumeDone(result_t success){

    return;
  }
  
  event void Audio.setSamplingRateDone(result_t success){
    
    return;
  }

  event void Audio.audioPlayDone(uint32_t *buffer, uint32_t numSamples){
    trace(DBG_USR1,"Audio Play done\r\n");
    
    return;
  }


  event void Audio.audioRecordDone(uint32_t *buffer, uint32_t numSamples){
    trace(DBG_USR1,"Audio Record done.  Audio Play returned %d\r\n", call Audio.audioPlay(buffer, numSamples));
  }
  
  
}
