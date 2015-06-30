/*****
 *
 * This Module provides the basic sensorobard specific implementation of the BoardManager interface
 *
 *
 *
 *
 *******/


module BasicSensorboardManagerM{
  provides{
    interface BoardManager;
  }
  uses{
    interface StdControl as AccelDataControl;
    interface PMIC;
  }
}
implementation{

#include "paramtask.h"
#include "pmic.h"

  void signalEnableChannelsToBeSampledDone(uint32_t arg);
  DEFINE_PARAMTASK(signalEnableChannelsToBeSampledDone);
  
  typedef struct{
    uint8_t numChannels;
    uint8_t *channelList;
  } channelList_t;
  
  channelList_t gChannelList;
  bool gChannelListInUse;
  
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
    for(i=0;i<numChannels;i++){
      switch(channelList[i]){
      case 1: //this is the accelerometer
	call AccelDataControl.init();
	break;
      default:
	trace(DBG_USR1,
	      "ERROR:  BasicSensorboardMangerM.enableChannelsToBeSampled passed unknown channel %d\r\n",
	      channelList[i]);
	return FAIL;
	break;
      }
    }
    
    //save the channelList for later so that we can signal out of this path just in case there is a dependency
    assert(gChannelListInUse == FALSE);
    gChannelList.numChannels = numChannels;
    gChannelList.channelList = malloc(numChannels);
    assert(gChannelList.channelList);
    memcpy(gChannelList.channelList,channelList,numChannels);
    gChannelListInUse = TRUE;
    
    POST_PARAMTASK(signalEnableChannelsToBeSampledDone,&gChannelList);
    
    return SUCCESS;
  } 
   
  command result_t BoardManager.startDataChannels(uint8_t numChannels, uint8_t *channelList){
    int i;
    //list of channels here are data channels
    call PMIC.enableSBVoltage_High(FALSE, LDO_TRIM_2P8);
    TOSH_uwait(6000); //wait 1 ms
    call PMIC.enableSBVoltage_High(TRUE, LDO_TRIM_2P8);

    
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
}
