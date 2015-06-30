
module BasicSensorboardAccelDataM{

  provides {
    interface StdControl;
    interface SensorData;
  }
  uses {
    interface SSP;
    interface BulkTxRx as RawData;
    interface PXA27XGPIOInt as RDYInterrupt;
    interface DVFS;
  }
}
implementation {

#include "UOM.h"

#define ACCEL_CMD_BLOCK_SIZE 1
#define SPEED  0
#define LSB_SIZE (1/1024.0)
  

  typedef uint8_t AccelCmd_t[2];
  
  AccelCmd_t AccelInitCmds[] = {{0x00, 0xA7},
				{0x00, 0x96},
				{0x00, 0x97},
				{0x00, 0x98},
				{0x00, 0x99},
				{0x00, 0x9A},
				{0x00, 0x9B},
				{0xC7 | (SPEED <<4) , 0x20},
				{0x04, 0x21}};
  
  //read out all of the accel data
  AccelCmd_t AccelReadCmds[] = {{0x00, 0xA8}, //XLow
				{0x00, 0xA9}, //XHigh
				{0x00, 0xAA}, //YLow
				{0x00, 0xAB}, //YHigh
				{0x00, 0xAC}, //ZLow
				{0x00, 0xAD}};//ZHigh
  
  

  uint16_t *gAccelRxBuffer = NULL;
  uint16_t gAccelRxNumBytes = 0;
  uint16_t gAccelRxBufferPos = 0;
  
  
  BulkTxRxBuffer_t gBulkTxRxBuffer;
  int32_t gXTotal=0, gYTotal=0, gZTotal=0;
  uint32_t gTotalSamples = 0;
  
  norace int16_t gCurrentXVal, gCurrentYVal;
  norace uint8_t gScratchPad;

  uint8_t gPrivateRxBuffer[32] __attribute__((aligned(32)));
  norace uint8_t gAccelInitState = 0;
  norace uint8_t gAccelReadState = 0;
  norace bool gAccelInitDone = FALSE;
  norace bool gAccelReadDone = TRUE;
  uint8_t gTotalInitCommands = sizeof(AccelInitCmds)/sizeof(AccelCmd_t);
  uint8_t gTotalReadCommands = sizeof(AccelReadCmds)/sizeof(AccelCmd_t);  
    
  void AccelInit();
  void AccelRead();
    
  command result_t StdControl.init() {

    trace(DBG_USR1,"AccelDataM.StdControl.init()\r\n");
    GPIO_SET_ALT_FUNC(96,0,GPIO_IN);
    call RDYInterrupt.enable(TOSH_RISING_EDGE);
    call SSP.setMasterSCLK(TRUE);
    call SSP.setMasterSFRM(TRUE);
    call SSP.setSSPFormat(SSP_SPI);
    call SSP.setDataWidth(SSP_16bits);
    call SSP.enableInvertedSFRM(FALSE);
    call SSP.enableSPIClkHigh(TRUE);
    call SSP.shiftSPIClk(TRUE);
    
    call SSP.setRxFifoLevel(SSP_8Samples);
    call SSP.setTxFifoLevel(SSP_8Samples);
    call SSP.setClkRate(1);
    call SSP.setClkMode(SSP_normalmode);
    
    atomic{
      gAccelRxBuffer = NULL;
      gAccelRxNumBytes = 0;
      gAccelRxBufferPos = 0;
    }
    
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    
    if(gAccelRxBuffer!= NULL){
      trace(DBG_USR1,"AccelDataM.StdControl.start()...changing clk to 104M\r\n");
      call DVFS.SwitchCoreFreq(104,104);
      call RDYInterrupt.enable(TOSH_RISING_EDGE);
      AccelInit();
      return SUCCESS;
    }
    else{
      return FAIL;
    }
  }
  
  task void stopAcquisitionTask(){
    //this code does not directly call StdControl.stop() in order to protect against separate paths through
    //that function
    trace(DBG_USR1,"AccelDataM.stopping acquisition...changing clk to 13M\r\n");
    call RDYInterrupt.disable();
    signal SensorData.getSensorDataStopped();
  }  

  command result_t StdControl.stop() {
    
    trace(DBG_USR1,"AccelDataM.StdControl.stop()...changing clk to 13M\r\n");
    call RDYInterrupt.disable();
    //    call DVFS.SwitchCoreFreq(13,13);
    return SUCCESS;
  }

  command result_t SensorData.getSensorData(uint8_t *RxBuffer, uint32_t NumSamples){
    
    trace(DBG_USR1,"AccelData:  getting %d samples into buffer %#x\r\n",NumSamples, (uint32_t)RxBuffer);
    atomic{
      gAccelRxBuffer=RxBuffer;
      gAccelRxNumBytes=NumSamples*6;
      gAccelRxBufferPos = 0;
    }
    return SUCCESS;
  }
    
  command result_t  SensorData.getOutputUOM(uint8_t *UOM) {
    if(UOM){
      *UOM = UOM_tfromString("gs");
      return SUCCESS;	
    }
    else{
      return FAIL;
    }
  }

  command result_t  SensorData.setSensorType(uint32_t sensorType) {
    
    return SUCCESS;    
  }

  command result_t SensorData.setSamplingRate(uint32_t requestedSamplingRate, uint32_t *actualSamplingRate){
    if(actualSamplingRate){
      *actualSamplingRate = MAX_SAMPLING_RATE;
      return SUCCESS;
    }
    return FAIL;
  } 
  
  command result_t SensorData.setSampleWidth(uint8_t requestedSampleWidth){
    if(requestedSampleWidth == 6){
      return SUCCESS;
    }
    return FAIL;
  }


  void AccelInit(){
    trace(DBG_USR1,"AccelData:  initializing accelerometer\r\n");
    atomic{
      gAccelInitState = 0;
      gAccelInitDone = FALSE;
      gXTotal = 0;
      gYTotal = 0;
      gZTotal = 0;
      gTotalSamples = 0;
      gBulkTxRxBuffer.RxBuffer = gPrivateRxBuffer;
      gBulkTxRxBuffer.TxBuffer = AccelInitCmds[gAccelInitState];
    }
    if(call RawData.BulkTxRx(&gBulkTxRxBuffer, sizeof(AccelCmd_t))==FAIL){
      trace(DBG_USR1,"BulkTransmit failed\r\n");
    }
  }
    
  void AccelRead(){
    atomic{
      gAccelReadState = 0;
      gAccelReadDone = FALSE;
      gBulkTxRxBuffer.RxBuffer = gPrivateRxBuffer;
      gBulkTxRxBuffer.TxBuffer = AccelReadCmds[gAccelReadState];
    }
    if(call RawData.BulkTxRx(&gBulkTxRxBuffer, sizeof(AccelCmd_t)* ACCEL_CMD_BLOCK_SIZE)==FAIL){
      trace(DBG_USR1,"BulkTransmit failed\r\n");
    }
  }
  
  task void AccelReadTask(){
    if(gAccelInitDone){
      AccelRead();
    }
  }

  async event void RDYInterrupt.fired(){
    call RDYInterrupt.clear();
    if(gAccelInitDone){
      AccelRead();
    }
  } 
  
  async event uint8_t *RawData.BulkReceiveDone(uint8_t *RxBuffer, uint16_t NumBytes){
    return NULL;
  }
  
  task void signalBulkTransmitFail(){
    trace(DBG_USR1,"BulkTransmit failed\r\n");
  }
  
  async event uint8_t *RawData.BulkTransmitDone(uint8_t *TxBuffer, uint16_t NumBytes){
    if(gAccelInitDone == FALSE){
      gAccelInitState++;
      if(gAccelInitState == gTotalInitCommands){
	gAccelInitDone = TRUE;
      }
      else{
	return AccelInitCmds[gAccelInitState];
      }
    }
    else if(gAccelReadDone == FALSE){
      gAccelReadState++;
      if(gAccelReadState == gTotalReadCommands){
	gAccelReadDone = TRUE;
      }else{
	return AccelReadCmds[gAccelReadState];
      }
    }
    return NULL;
  }

  async event BulkTxRxBuffer_t *RawData.BulkTxRxDone(BulkTxRxBuffer_t *TxRxBuffer, uint16_t NumBytes){
    if(gAccelInitDone == FALSE){
      gAccelInitState++;
      if(gAccelInitState == gTotalInitCommands){
	gAccelInitDone = TRUE;
	post AccelReadTask();
      }
      else{
	TxRxBuffer->TxBuffer = AccelInitCmds[gAccelInitState];
	return TxRxBuffer;
      }
    }
    else if(gAccelReadDone == FALSE){
      switch(gAccelReadState){
      case 0:
	gScratchPad = gPrivateRxBuffer[0];
	break;
      case 1:
	gCurrentXVal = (int16_t)((gPrivateRxBuffer[0] << 8) | gScratchPad);
	break;
      case 2:
	gScratchPad = gPrivateRxBuffer[0];
	break;
      case 3:
	gCurrentYVal = (int16_t)((gPrivateRxBuffer[0] << 8) | gScratchPad);
	break;
      case 4:
	gScratchPad = gPrivateRxBuffer[0];
	break;
      case 5:
	atomic{
	  if(gAccelRxBuffer){
	    gAccelRxBuffer[gAccelRxBufferPos] = gCurrentXVal;
	    gAccelRxBuffer[gAccelRxBufferPos+1] = gCurrentYVal;
	    gAccelRxBuffer[gAccelRxBufferPos+2] = (int16_t)((gPrivateRxBuffer[0] << 8) | gScratchPad);
	    gAccelRxBufferPos+=3;
	  }
	}
	if((gAccelRxBufferPos*2) >= gAccelRxNumBytes){
	  //we're done
	  if((gAccelRxBuffer = (uint16_t *) signal SensorData.getSensorDataDone((uint8_t *)gAccelRxBuffer, gAccelRxNumBytes/6, OSCR0, LSB_SIZE, 0.0)) != NULL){
	    gAccelRxBufferPos = 0;
	  }
	  else{
	    //the fact that we're not init'ed any more means that we will no longer receive any sample interrupts...
	    //this will allow us to post a task to stop the acqusition
	    gAccelInitDone = FALSE;
	    post stopAcquisitionTask();
	  }
	}
	break;
      default:
	//??
      }

      gAccelReadState+=ACCEL_CMD_BLOCK_SIZE;
      if(gAccelReadState == gTotalReadCommands){
	gAccelReadDone = TRUE;
      }else{
	TxRxBuffer->TxBuffer = AccelReadCmds[gAccelReadState];
	return TxRxBuffer;
      }
    }
    //    post signalEnableCmdDone();
    return NULL;
  }
}
