/*****
 *
 * This Module provides the basic sensorobard specific implementation of the BoardManager interface
 *
 *
 *
 *
 *******/

module GenericSensorboardManagerM{
  provides{
    interface BoardManager;
    interface BluSH_AppI as CalOffset;    
    interface BluSH_AppI as CalGain;    
  }
  uses{
    interface StdControl as AccelDataControl;
    interface I2CBusSequence;
    interface PMIC;
    interface QuickFilterQF4A512;
    interface Timer;
  }
}
implementation{
#include "paramtask.h"
#include "pmic.h"
#define SLAVE_WRITE_ADDR 0x40
  
  //we want to test out our code by first enabling all pins as outputs
  // then toggling between 1's and 0's every 1's
  
  //DO NOT MAKE THESE CONST!!!
  i2c_op_t configSequence[] = { 
    {I2C_START,0,0},
    {I2C_WRITE, SLAVE_WRITE_ADDR, 0},
    {I2C_WRITE, 0x3, 0},  //write configuration register command byte 
    {I2C_END, 0x0, 0},  //after next write, send stop bit
    {I2C_WRITE, 0x0, 0},  //write configuration register value
  };
#define CONFIGSEQUENCESIZE (sizeof(configSequence)/sizeof(*configSequence))
  
  i2c_op_t WriteZeros[] = { 
    {I2C_START,0,0},
    {I2C_WRITE, SLAVE_WRITE_ADDR, 0},
    {I2C_WRITE, 0x1, 0},  //write output port register register
    {I2C_END, 0x0, 0},  //after next write, send stop bit
    {I2C_WRITE, 0x0, 0},  //write output port value
  };
#define WRITEZEROSSIZE (sizeof(WriteZeros)/sizeof(*WriteZeros))
  
  i2c_op_t WriteOnes[] = { 
    {I2C_START,0,0},
    {I2C_WRITE, SLAVE_WRITE_ADDR, 0},
    {I2C_WRITE, 0x1, 0},  //write output port register register
    {I2C_END, 0x0, 0},  //after next write, send stop bit
    {I2C_WRITE, 0xFF, 0},  //write output port value
  };
#define WRITEONESSIZE (sizeof(WriteOnes)/sizeof(*WriteOnes))

  
  void signalEnableChannelsToBeSampledDone(uint32_t arg);
  DEFINE_PARAMTASK(signalEnableChannelsToBeSampledDone);
  
  typedef struct{
    uint8_t numChannels;
    uint8_t *channelList;
  } channelList_t;
  
  bool gConfigureDone = FALSE;
  channelList_t gChannelList;
  bool gChannelListInUse;

  bool gCalibrateOffsetFlag;
  uint8_t gCalibrateChannel;
  bool gCalibrate;

  void signalEnableChannelsToBeSampledDone(uint32_t arg){
    channelList_t *pCL = (channelList_t *)arg;
    assert(pCL->channelList);
    assert(pCL->numChannels > 0);
    signal BoardManager.enableChannelsToBeSampledDone(pCL->numChannels, pCL->channelList);
    free(pCL->channelList);
    pCL->channelList = NULL;
    gChannelListInUse = FALSE;
  }
  
  command result_t BoardManager.enableChannelsToBeSampled(uint8_t numChannels, uint8_t *channelList){
    int i;
    bool bValidChannel = FALSE;
    //chip comes up with everything in right state...only need to configure it as all outputs  
    
    for(i=0;i<numChannels;i++){
      switch(channelList[i]){
      case 1: 
      case 2:
      case 3:
      case 4:
	bValidChannel = TRUE;
	break;
      default:
	break;
      }
    }
    if(bValidChannel == TRUE){
      call PMIC.enableSBVoltage_High(FALSE, LDO_TRIM_3P2);
      call PMIC.enableSBVoltage_High(TRUE, LDO_TRIM_3P2);
      
      //save the channelList for later so that we can signal when we are told that the QFA has been initialized
      assert(gChannelListInUse == FALSE);
      gChannelList.numChannels = numChannels;
      gChannelList.channelList = malloc(numChannels);
      assert(gChannelList.channelList);
      memcpy(gChannelList.channelList,channelList,numChannels);
      gChannelListInUse = TRUE;
      gCalibrate = FALSE;
      
      //wait 10ms just to let the voltage change settle out
      return call Timer.start(TIMER_ONE_SHOT, 10);
    }
    
    return SUCCESS;
  } 
  
  event result_t Timer.fired(){
    
    call I2CBusSequence.runI2CBusSequence(configSequence, CONFIGSEQUENCESIZE);
    return SUCCESS;
  }
  
  event result_t QuickFilterQF4A512.initializeQF4A512Done(){
    POST_PARAMTASK(signalEnableChannelsToBeSampledDone,&gChannelList);
    return SUCCESS;
  }
   
  command result_t BoardManager.startDataChannels(uint8_t numChannels, uint8_t *channelList){
    int i;

    for(i=0;i<numChannels;i++){
      switch(channelList[i]){
      case 1: //this is the accelerometer
	call AccelDataControl.start();
	break;
      default:
	break;
      }
    }
    return SUCCESS;
  }
  
  task void unknownI2CSequence(){
    trace(DBG_USR1,"received runI2CBusSequenceDone for unknown I2C Sequence\r\n");
    return;
  }

  task void I2CSequenceDone(){
    trace(DBG_USR1,"Successfully reset QFA\r\n");
    call AccelDataControl.init();
    
    if(gCalibrate == TRUE){
      call QuickFilterQF4A512.calibrateQF4A512(gCalibrateOffsetFlag, gCalibrateChannel);
    }
    else{
      call QuickFilterQF4A512.initializeQF4A512();
    }
    return;
  }
  
  task void writeZerosTask(){
    trace(DBG_USR1,"configured i2c expander for outputs...reseting QFA\r\n");
    call I2CBusSequence.runI2CBusSequence(WriteZeros, WRITEZEROSSIZE);
  }

  task void writeOnesTask(){
    trace(DBG_USR1,"Reset QFA....bringing out of reset\r\n");
    call I2CBusSequence.runI2CBusSequence(WriteOnes, WRITEONESSIZE);
  }
  
  event void I2CBusSequence.runI2CBusSequenceDone(i2c_op_t *pOpsExecuted, uint8_t numOpsExecuted, result_t success){
    if( (success == SUCCESS) && pOpsExecuted == configSequence){
      gConfigureDone = TRUE;
      post writeZerosTask();
    }
    else if( (success == SUCCESS) && pOpsExecuted == WriteZeros){
      post writeOnesTask();
    }
    else if( (success == SUCCESS) && pOpsExecuted == WriteOnes){
      post I2CSequenceDone();
    }
    else{
      post unknownI2CSequence();
    }
    return;
  }

  command BluSH_result_t CalOffset.getName(char *buff, uint8_t len){
    
    const char name[] = "CalOffset";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t CalOffset.callApp(char *cmdBuff, uint8_t cmdLen,
					   char *resBuff, uint8_t resLen){
    
    uint32_t targetChannel;
    if(strlen(cmdBuff) > strlen("CalOffset ")){
      
      sscanf(cmdBuff,"CalOffset %d", &targetChannel);
      trace(DBG_USR1,"Calibrating offset for channel %d\r\n", targetChannel);
#if 1      
      call QuickFilterQF4A512.calibrateQF4A512(TRUE, targetChannel);
    
#else
      gCalibrateOffsetFlag = FALSE;
      gCalibrateChannel = targetChannel;
      gCalibrate = TRUE;

      call PMIC.enableSBVoltage_High(FALSE, LDO_TRIM_3P2);
      call PMIC.enableSBVoltage_High(TRUE, LDO_TRIM_3P2);
      
      //wait 10ms just to let the voltage change settle out
      return call Timer.start(TIMER_ONE_SHOT, 10);
#endif    
    }
    else{
      trace(DBG_USR1,"CalOffset targetChannel\r\n");
    }
    
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t CalGain.getName(char *buff, uint8_t len){
    
    const char name[] = "CalGain";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t CalGain.callApp(char *cmdBuff, uint8_t cmdLen,
					   char *resBuff, uint8_t resLen){
    
    uint32_t targetChannel;
    if(strlen(cmdBuff) > strlen("CalGain ")){
      
      sscanf(cmdBuff,"CalGain %d", &targetChannel);
      trace(DBG_USR1,"Calibrating gain for channel %d\r\n", targetChannel);

#if 1
      call QuickFilterQF4A512.calibrateQF4A512(FALSE, targetChannel);
#else      
      gCalibrateOffsetFlag = FALSE;
      gCalibrateChannel = targetChannel;
      gCalibrate = TRUE;
      
      call PMIC.enableSBVoltage_High(FALSE, LDO_TRIM_3P2);
      call PMIC.enableSBVoltage_High(TRUE, LDO_TRIM_3P2);
            
      //wait 10ms just to let the voltage change settle out
      return call Timer.start(TIMER_ONE_SHOT, 10);
#endif    
    }
    else{
      trace(DBG_USR1,"CalGain targetChannel\r\n");
    }
    
    return BLUSH_SUCCESS_DONE;
  }


}
