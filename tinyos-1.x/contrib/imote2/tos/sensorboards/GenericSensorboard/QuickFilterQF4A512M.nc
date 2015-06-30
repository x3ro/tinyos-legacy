
module QuickFilterQF4A512M{

  provides {
    interface StdControl;
    interface SensorData[uint8_t channel];
    interface QuickFilterQF4A512;
    interface BluSH_AppI as ManualRead;
    interface BluSH_AppI as ClearCal;
  }
  uses {
    interface SSP;
    interface BulkTxRx as RawData;
    interface PXA27XGPIOInt as DRDYInterrupt;
    interface DVFS;
    interface Leds;
  }
}
implementation {

#include "UOM.h"

#include "Mix.h"
#include "calibrationFilter.h"
#include "paramtask.h"
#include "bufferManagementHelper.h"

#define GLBL_ID (0xa0) //this number must correspond to the version of the QF4A512 in use...see its datasheet
#define GLBL_ID_ADDR (0x01) //address corresponding to the global ID address
#define EE_STATUS_ADDR (0x0e) //address corresponding to the eeprom status register
#define EE_STATUS_WRITE_DONE_MASK (0x2)
#define EE_STATUS_READ_DONE_MASK (0x1)

#define CAL_CTRL_ADDR (0xED)
 
  // DMASIZE....this will get rounded up to 32 by buffermanagement library....but we only really want 12 bytes per transaction
#define DMASIZE (12)
  //NUMBUFFERS...number of distinct buffers allocated by our bufferemangement library for this component.
  //we probably only need 1, but declare 2 just in case
#define NUMBUFFERS (3)
  
#define LSB_SIZE (7.62939453125e-005)

  /**
   *
   *read command format
   * 
   *DO <1><addr(14)><1><0xXX>
   *DI <X><X(14)   ><X><data(8)>
   *
   *
   *
   **/
  const struct QFRegister QFRunRegisterTable[] = {{ 0x0015, 0x49 } ,
						  { 0x0031, 0x00 } ,
						  { 0x0061, 0x00 } ,
						  { 0x0091, 0x00 } ,
						  { 0x00C1, 0x00 } ,
						  { 0x0015, 0x49 } ,
						  { 0x0004, 0x01 } };


  const struct QFRegister QFStopRegisterTable[] = {{ 0x0004, 0x00 } ,
						   { 0x0015, 0x0c } };

  //cal table should live in SRAM so that we can modify as appropriate for our cal
  struct QFRegister QFCalRegisterTable[7];
  
  struct QFRegister QFEEPROMRegisterTable[9];  


  uint16_t *gRxBuffers[4];
  uint32_t gRxNumSamples[4];
  uint32_t gRxBufferPos[4];
  bool     gDoChannel[4];
  float    gChannelOffset[4];
  float    gChannelScale[4];
  bool     gUseCal[4];
  
  norace volatile BulkTxRxBuffer_t gBulkTxRxBuffer;
  
  uint8_t gPrivateRxBuffer[32] __attribute__((aligned(32)));
  uint8_t gPrivateTxBuffer[32] __attribute__((aligned(32)));
  
  //STATE VARIABLES
  uint16_t gLoadFilterState = 0;
  uint16_t gLoadCalFilterState = 0;
  uint16_t gSendRunState = 0;
  uint16_t gCalState = 0;
  uint16_t gManualReadState = 0;
  uint16_t gEEPROMWriteState = 0;  
  uint16_t gEEPROMReadState = 0;  
  uint16_t gEEPROMReadBlock = 0;  
  
  uint16_t gManualReadAddress = 0;
  norace volatile uint16_t gAccelStopState = 0;
  bool gDropFirstSample = FALSE;
  bool gSaveData = FALSE;
  bool gDoneCapturingData = FALSE;
  
  typedef enum{
    STATE_IDLE=0,
      STATE_LoadFilter,
      STATE_SendRun,
      STATE_SENDSTOP,
      STATE_RUN,
      STATE_LoadCalFilter,
      STATE_Cal,
      STATE_MANUALREAD,
      STATE_EEPROMWrite,
      STATE_EEPROMRead
      } qfaState_t;
  
  norace volatile qfaState_t gQFAState;

  uint16_t gTotalLoadFilterCommands = sizeof(QFImageRegisterTable)/sizeof(struct QFRegister);
  uint16_t gTotalLoadCalFilterCommands = sizeof(QFCalFilterRegisterTable)/sizeof(struct QFRegister);
  uint8_t gTotalSendRunCommands = sizeof(QFRunRegisterTable)/sizeof(struct QFRegister);  
  uint8_t gTotalStopCommands = sizeof(QFStopRegisterTable)/sizeof(struct QFRegister);  
  uint8_t gTotalCalCommands = 0;
  uint16_t gTotalManualReadCommands = 0;
  uint16_t gTotalEEPROMWriteCommands = 0;
  uint16_t gTotalEEPROMReadCommands = 8;
  
  void readDone(uint32_t arg);
  DEFINE_PARAMTASK(readDone);
  
  DECLARE_DMABUFFER(receive,NUMBUFFERS,DMASIZE);
  
#define CREATE_QFA_FRAME(buffer, table, index, read)  {buffer[0] = (((read) & 0x1) << 7) | ((table[(index)].uiAddress >> 7) & 0x7f);\
                                                       buffer[1] = (table[(index)].uiAddress & 0x7f) << 1;\
                                                       buffer[2] = table[(index)].ucValue;\
                                                       cleanDCache(buffer, 3);}
  
  
#define CREATE_MANUAL_QFA_READ_FRAME(buffer,address) {buffer[0] = (1 << 7) | (((address) >> 7) & 0x7f);\
                                                      buffer[1] = (address & 0x7f) << 1;\
                                                      buffer[2] = 0;\
                                                      cleanDCache(buffer, 3);}
  
#define CHANGE_STATE(state)  {g##state##State = 0;\
                              gQFAState = STATE_##state;\
                              post sendNext##state##Cmd();}
  
#define NEW_DATA(data)  ( ((data) >> 4) & 0x1)
#define CHANNEL_ID(data) ( ((data) >> 5) & 0x3)
#define SAMPLE(hi, lo) ( ((hi) << 8) | ((lo)) )

  task void sendNextLoadFilterCmd();
  task void sendNextLoadCalFilterCmd();
  task void sendNextSendRunCmd();
  task void sendNextStopCmd();
  task void sendNextCalCmd();
  task void sendNextManualReadCmd();
  task void sendNextEEPROMWriteCmd();
  task void sendNextEEPROMReadCmd();
  task void getDataTask();
  
  void getData();
  void configureEEPROMWrite(uint16_t chipaddress, uint16_t EEPROMDestAddr, uint16_t numBytes);
  void configureEEPROMRead(uint16_t chipaddress, uint16_t EEPROMDestAddr, uint16_t numBytes);

  command result_t StdControl.init() {

    static bool init = FALSE;
    
    if(init == FALSE){
      GPIO_SET_ALT_FUNC(10,0,GPIO_IN);
      call SSP.setMasterSCLK(TRUE);
      call SSP.setMasterSFRM(TRUE);
      call SSP.setSSPFormat(SSP_SPI);
      call SSP.setDataWidth(SSP_8bits);
      call SSP.enableInvertedSFRM(FALSE);
      call SSP.enableSPIClkHigh(FALSE);
      call SSP.shiftSPIClk(TRUE);
      
      call SSP.setRxFifoLevel(SSP_8Samples);
      call SSP.setTxFifoLevel(SSP_8Samples);
      call SSP.setClkRate(0);
      call SSP.setClkMode(SSP_normalmode);
      
      INIT_DMABUFFER(receive, NUMBUFFERS, DMASIZE);
      init = TRUE;
      trace(DBG_USR1,"sizeof(receiveBuffers, *receiveBuffers, **receiveBuffers) = %d %d %d\r\n", sizeof(receiveBuffers), sizeof(*receiveBuffers), sizeof(**receiveBuffers));
    }
    
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    gSaveData = TRUE;
    return SUCCESS;
  }

  command result_t QuickFilterQF4A512.initializeQF4A512(){
    
    trace(DBG_USR1,"changing clk to 104M and initializing QF4A512\r\n");
    call DVFS.SwitchCoreFreq(104,104);
    gSaveData = FALSE;
    //explicitly disable the interrupt so that we don't get anything too early
    call DRDYInterrupt.disable();
    
    atomic{
      gDoneCapturingData = FALSE;
    }
    
    
    atomic{
      gBulkTxRxBuffer.RxBuffer = gPrivateRxBuffer;
      gBulkTxRxBuffer.TxBuffer = gPrivateTxBuffer;
    }
    
    CHANGE_STATE(LoadFilter);
    return SUCCESS;
  }

  command result_t QuickFilterQF4A512.calibrateQF4A512(bool offset, uint8_t channel){
    //calibration state machine:
    //1.) load calibration filter
    //2.) start calibration
    //3.) commit calibration values to EEPROM
    
    if( (channel < 1) || (channel > 4)){
      trace(DBG_USR1,"ERROR:  Invalid channel %d passed to calibrateQF4A512.  Valid channels are 1-4\r\n", channel);
      return FAIL;
    } 
    
    call StdControl.init();
        
    if(offset){
      //offset calibration
      trace(DBG_USR1,"Performing Offset Calibration...Positive Input should be shorted to Negative Input\r\n");
      
      //set offset registers to 0 so that we get a reasonable value
      QFCalRegisterTable[0].uiAddress = 0x56 + (channel-1)*0x30;
      QFCalRegisterTable[0].ucValue = 0x0;
      
      QFCalRegisterTable[1].uiAddress = 0x57 + (channel-1)*0x30;
      QFCalRegisterTable[1].ucValue = 0x0;
      
      //if we're doing an offset calibration, our gain needs to be the default value
      QFCalRegisterTable[2].uiAddress = 0x58 + (channel-1)*0x30;
      QFCalRegisterTable[2].ucValue = 0x0;
      
      QFCalRegisterTable[3].uiAddress = 0x59 + (channel-1)*0x30;
      QFCalRegisterTable[3].ucValue = 0x80;

      
      //set the target register to 0
      QFCalRegisterTable[4].uiAddress = 0xEF;
      QFCalRegisterTable[4].ucValue = 0x0;
      
      QFCalRegisterTable[5].uiAddress = 0xEE;
      QFCalRegisterTable[5].ucValue = 0x0;

      //configure us for the proper channel, an offset cal, and to start
      QFCalRegisterTable[6].uiAddress = CAL_CTRL_ADDR;
      QFCalRegisterTable[6].ucValue = (0x8) | ((channel-1) & 0x3);
      
      gTotalCalCommands = 7;
      //setup the EEPROM write so that we can commit later
      //offset registers = 0x56-0x57 + (channel-1)*0x30;
      configureEEPROMWrite(0x56+ (channel-1)*0x30, 0xF00 + (channel-1)*2, 2);
      
    }
    else{
      //gain calibration
      trace(DBG_USR1,"Performing Gain Calibration...Positive Input should be connected to a 1/2 negative scale voltage  (-1.25V for a 5Vpp configuration)\r\n");
      
      //if we're doing a gain calibration, we will assume that the offset registers are already correct 
      QFCalRegisterTable[0].uiAddress = 0x58 + (channel-1)*0x30;
      QFCalRegisterTable[0].ucValue = 0x0;
      
      QFCalRegisterTable[1].uiAddress = 0x59 + (channel-1)*0x30;
      QFCalRegisterTable[1].ucValue = 0x80;
      
      //set the target register to 0

      //0xEF is the high order 8 bits of the cal gain value
      //due to the accidental gain inversion in our HW, our value need to reflect negative -1/2 scale instead of 1/2
      QFCalRegisterTable[2].uiAddress = 0xEF;
      QFCalRegisterTable[2].ucValue = 0x40;
      
      //0xEE is the low order 8 bits of the cal gain value`
      QFCalRegisterTable[3].uiAddress = 0xEE;
      QFCalRegisterTable[3].ucValue = 0x00;

      //configure us for the proper channel, an offset cal, and to start
      QFCalRegisterTable[4].uiAddress = CAL_CTRL_ADDR;
      QFCalRegisterTable[4].ucValue = (0xC) | ((channel-1) & 0x3);
      
      gTotalCalCommands = 5;
      //setup the EEPROM write so that we can commit later
      //offset registers = 0x58-0x59 + (channel-1)*0x30;
      
      configureEEPROMWrite(0x58+ (channel-1)*0x30, 0xF02+ (channel-1)*2, 2);
    }
        
    gSaveData = FALSE;
    //explicitly disable the interrupt so that we don't get anything too early
    call DRDYInterrupt.disable();
    
    atomic{
      gBulkTxRxBuffer.RxBuffer = gPrivateRxBuffer;
      gBulkTxRxBuffer.TxBuffer = gPrivateTxBuffer;
    }
   
    CHANGE_STATE(Cal);
    //    CHANGE_STATE(LoadCalFilter);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    
    trace(DBG_USR1,"AccelDataM.StdControl.stop()...changing clk to 13M\r\n");
    call DRDYInterrupt.disable();
    //    call DVFS.SwitchCoreFreq(13,13);
    return SUCCESS;
  }

  command result_t SensorData.getSensorData[uint8_t channel](uint8_t *RxBuffer, uint32_t NumSamples){
    
    if(channel < 4){
      trace(DBG_USR1,"QuickFilterQF4A512M[%d]:  getting %d samples into buffer %#x\r\n",channel, NumSamples, (uint32_t)RxBuffer);

      gRxBuffers[channel] = (uint16_t *)RxBuffer;
      gRxNumSamples[channel] = NumSamples;
      gRxBufferPos[channel] = 0;
      gDoChannel[channel] = TRUE;
      return SUCCESS;
    }
    else{
      trace(DBG_USR1,"FATAL CONFIGURATION ERROR:  QuickFilterQF4A512M.getSensorData received invalid channel id %d\r\n",channel);
      return FAIL;
    }
  }

  default event result_t SensorData.getSensorDataStopped[uint8_t channel](){
    return SUCCESS;
  }
  
  default event uint8_t *SensorData.getSensorDataDone[uint8_t channel](uint8_t *buffer, uint32_t numSamples, uint64_t timestamp, float ADCScale, float ADCOffset){
    return NULL;
  }

  command result_t  SensorData.getOutputUOM[uint8_t channel](uint8_t *UOM) {
    if(UOM){
      *UOM = UOM_tfromString("gs");
      return SUCCESS;	
    }
    else{
      return FAIL;
    }
  }

  command result_t  SensorData.setSensorType[uint8_t channel](uint32_t sensorType) {
    if(channel < 4){
      
      gChannelOffset[channel] = 0;
      
      switch(GET_ANALOG_INPUT_RANGE(sensorType)){
	
      case SENSOR_ANALOG_RANGE_PLUSMINUS2P5V:
	gChannelScale[channel] = -5.0/65536;
	break;
	
      case SENSOR_ANALOG_RANGE_PLUSMINUS5V:
	gChannelScale[channel] = -10.0/65536;
	break;
	
      case SENSOR_ANALOG_RANGE_PLUSMINUS10V:
	gChannelScale[channel] = -20.0/65536;
	break;
	
      default:
	trace(DBG_USR1,"ERROR:  Unknown ANALOG_INPUT_RANGE %d for sensorType %d\r\n",GET_ANALOG_INPUT_RANGE(sensorType), sensorType);
	return FAIL;
      }
      return SUCCESS;    
    }
    else{
      return FAIL;
    }
  }

  command result_t SensorData.setSamplingRate[uint8_t channel](uint32_t requestedSamplingRate, uint32_t *actualSamplingRate){
    if(actualSamplingRate){
      *actualSamplingRate = requestedSamplingRate;
      return SUCCESS;
    }
    return FAIL;
  } 
  
  command result_t SensorData.setSampleWidth[uint8_t channel](uint8_t requestedSampleWidth){
    if(requestedSampleWidth == 2){
      return SUCCESS;
    }
    return FAIL;
  }
  
  task void sendNextStopCmd(){
    uint32_t i;

    if(gAccelStopState == gTotalStopCommands){
      trace(DBG_USR1,"QF4A512 stopped\r\n");
      for(i=0; i<4; i++){
	if(gDoChannel[i]){
	  signal SensorData.getSensorDataStopped[i]();
	  gDoChannel[i] = FALSE;
	}
      }
    }
    else{
      gBulkTxRxBuffer.TxBuffer[0] = QFStopRegisterTable[gAccelStopState].uiAddress;
      gBulkTxRxBuffer.TxBuffer[1] = QFStopRegisterTable[gAccelStopState].ucValue;
      cleanDCache(gBulkTxRxBuffer.TxBuffer,2);
      
      assert(call RawData.BulkTxRx((BulkTxRxBuffer_t *)&gBulkTxRxBuffer, 2));
      gAccelStopState++;
    }
  }
  
  task void printFirstSampleMsg(){
    trace(DBG_USR1,"Found first sample indication...enabling interrupt\r\n");
  }
  
  task void signalInitializeQF4A512Done(){
    signal QuickFilterQF4A512.initializeQF4A512Done();
  }  
  
  task void checkForFirstDRDY(){
    if(READ_GPIO(10)){
      
      post signalInitializeQF4A512Done();
      
      //this is the command that we'll be using while we're asking for data
      memset(gBulkTxRxBuffer.TxBuffer, 0, 12);
      cleanDCache(gBulkTxRxBuffer.TxBuffer, 12);
      //make sure that we're dropping the first sample because it will almost undoubtably be garbage
      gDropFirstSample = TRUE;
      //allocate a newbuffer
      getData();
      //call DRDYInterrupt.enable(TOSH_RISING_EDGE);
      post printFirstSampleMsg();
    }
    else{
      //odd that it wasn't already set...but presumably possible (albeit unlikely)
      
      post checkForFirstDRDY();
    }

  }
  
  task void sendNextSendRunCmd(){
   
    if(gSendRunState == gTotalSendRunCommands){
      gQFAState = STATE_RUN;
      trace(DBG_USR1,"QF4A512 now running\r\n");
      post checkForFirstDRDY();
    }
    else{
      CREATE_QFA_FRAME(gBulkTxRxBuffer.TxBuffer, QFRunRegisterTable, gSendRunState,0);
      assert(call RawData.BulkTxRx((BulkTxRxBuffer_t *)&gBulkTxRxBuffer, 3));
      gSendRunState++;
    }
  }

  task void sendNextManualReadCmd(){
    
    if(gManualReadState > 0){
      //we must have already completed a read;
      invalidateDCache(gBulkTxRxBuffer.RxBuffer, 3);
      trace(DBG_USR1,"Read %#x from address %#x\r\n",gBulkTxRxBuffer.RxBuffer[2], gManualReadAddress-1);
    }

    if(gManualReadState == gTotalManualReadCommands){
      gQFAState = STATE_IDLE;
      trace(DBG_USR1,"Read Complete\r\n");
    }
    else{
      
      //since we're in the middle of sending 
      gBulkTxRxBuffer.TxBuffer[0] = (1 << 7) | ((gManualReadAddress >> 7) & 0x7f);
      gBulkTxRxBuffer.TxBuffer[1] = (gManualReadAddress & 0x7f) << 1;
      gBulkTxRxBuffer.TxBuffer[2] = 0;
      cleanDCache(gBulkTxRxBuffer.TxBuffer, 3);
      
      gManualReadAddress++;
      
      assert(call RawData.BulkTxRx((BulkTxRxBuffer_t *)&gBulkTxRxBuffer, 3));
      gManualReadState++;
    }
  }

    
  task void sendNextLoadFilterCmd(){
   
    if(gLoadFilterState == gTotalLoadFilterCommands){
#if 1
      gEEPROMReadBlock=0;
      configureEEPROMRead(0x56, 0xF00, 4);
      CHANGE_STATE(EEPROMRead);
#else
      CHANGE_STATE(SendRun);
#endif    

  trace(DBG_USR1,"finished initializing QF4A512\r\n");
    }
    else{
      
      CREATE_QFA_FRAME(gBulkTxRxBuffer.TxBuffer, QFImageRegisterTable, gLoadFilterState,0);
      assert(call RawData.BulkTxRx((BulkTxRxBuffer_t *)&gBulkTxRxBuffer, 3));
      gLoadFilterState++;
    }
  }
  
  task void sendNextLoadCalFilterCmd(){
    if(gLoadCalFilterState == gTotalLoadCalFilterCommands){
      trace(DBG_USR1,"finished loading calibration filter...starting calibration\r\n");
      CHANGE_STATE(Cal);
    }
    else{
      CREATE_QFA_FRAME(gBulkTxRxBuffer.TxBuffer, QFCalFilterRegisterTable, gLoadCalFilterState,0);
      assert(call RawData.BulkTxRx((BulkTxRxBuffer_t *)&gBulkTxRxBuffer, 3));
      gLoadCalFilterState++;
    }
  }


  void configureEEPROMWrite(uint16_t chipAddr, uint16_t EEPROMDestAddr, uint16_t numBytes){
    
    //writing to EEPROM
    
    //clear out the EEPROM status register so that it is valid
    QFEEPROMRegisterTable[0].uiAddress = 0x0e;
    QFEEPROMRegisterTable[0].ucValue = 0x0;
  

    //set eeclk_rate to 000 in register STARTUP_1 (0x07)
    QFEEPROMRegisterTable[1].uiAddress = 0x07;
    QFEEPROMRegisterTable[1].ucValue = 0x0;

    //CHIP_STDADDR(0x19-0x1A) = address of starting address
    QFEEPROMRegisterTable[2].uiAddress = 0x19;
    QFEEPROMRegisterTable[2].ucValue = (chipAddr & 0xff);

    QFEEPROMRegisterTable[3].uiAddress = 0x1a;
    QFEEPROMRegisterTable[3].ucValue = (chipAddr & 0x3f00)>>8;    
    
    //EE_STADDR(0x17-0x18) = address of destination address...
    QFEEPROMRegisterTable[4].uiAddress = 0x17;
    QFEEPROMRegisterTable[4].ucValue = (EEPROMDestAddr & 0xff);
    
    QFEEPROMRegisterTable[5].uiAddress = 0x18;
    QFEEPROMRegisterTable[5].ucValue = (EEPROMDestAddr & 0xf00)>>8;
    
    
    //END_ADDR(0x1b-0x1c) = end address of destination block
    QFEEPROMRegisterTable[6].uiAddress = 0x1b;
    QFEEPROMRegisterTable[6].ucValue = ((EEPROMDestAddr+numBytes-1) & 0xff);
    
    QFEEPROMRegisterTable[7].uiAddress = 0x1c;
    QFEEPROMRegisterTable[7].ucValue = ((EEPROMDestAddr+numBytes-1) & 0x3f00)>>8;


    //start the transfer....set wr_start in EE_TRANS(0x05)
    QFEEPROMRegisterTable[8].uiAddress = 0x05;
    QFEEPROMRegisterTable[8].ucValue = 0x2;
    
    gTotalEEPROMWriteCommands = 9;
    gEEPROMWriteState = 0;
    
  }
  
  void configureEEPROMRead(uint16_t chipDestAddr, uint16_t EEPROMSrcAddr, uint16_t numBytes){
    
    //reading from EEPROM
    
    //clear out the EEPROM status register so that it is valid
    QFEEPROMRegisterTable[0].uiAddress = 0x0e;
    QFEEPROMRegisterTable[0].ucValue = 0x0;
    
    //set eeclk_rate to 000 in register STARTUP_1 (0x07)
    QFEEPROMRegisterTable[1].uiAddress = 0x07;
    QFEEPROMRegisterTable[1].ucValue = 0x0;

    //CHIP_STDADDR(0x19-0x1A) = address of starting address
    QFEEPROMRegisterTable[2].uiAddress = 0x19;
    QFEEPROMRegisterTable[2].ucValue = (chipDestAddr & 0xff);

    QFEEPROMRegisterTable[3].uiAddress = 0x1a;
    QFEEPROMRegisterTable[3].ucValue = (chipDestAddr & 0x3f00)>>8;    
    
    //EE_STADDR(0x17-0x18) = address of destination address...
    QFEEPROMRegisterTable[4].uiAddress = 0x17;
    QFEEPROMRegisterTable[4].ucValue = (EEPROMSrcAddr & 0xff);
    
    QFEEPROMRegisterTable[5].uiAddress = 0x18;
    QFEEPROMRegisterTable[5].ucValue = (EEPROMSrcAddr & 0xf00)>>8;
    
    
    //END_ADDR(0x1b-0x1c) = end address of destination block
    QFEEPROMRegisterTable[6].uiAddress = 0x1b;
    QFEEPROMRegisterTable[6].ucValue = ((chipDestAddr+numBytes-1) & 0xff);
    
    QFEEPROMRegisterTable[7].uiAddress = 0x1c;
    QFEEPROMRegisterTable[7].ucValue = ((chipDestAddr+numBytes-1) & 0x3f00)>>8;


    //start the transfer....set rd_start in EE_TRANS(0x05)
    QFEEPROMRegisterTable[8].uiAddress = 0x05;
    QFEEPROMRegisterTable[8].ucValue = 0x1;
    
    gTotalEEPROMReadCommands = 9;
    gEEPROMReadState = 0;
  }


  task void sendNextEEPROMWriteCmd(){
    if(gEEPROMWriteState == gTotalEEPROMWriteCommands){
      trace(DBG_USR1,"Finished Writing EEPROM..waiting for completion indication\r\n"); 
      
      CREATE_MANUAL_QFA_READ_FRAME(gBulkTxRxBuffer.TxBuffer, EE_STATUS_ADDR);
      assert(call RawData.BulkTxRx((BulkTxRxBuffer_t *)&gBulkTxRxBuffer, 3));
      gEEPROMWriteState++;
    }
    else if(gEEPROMWriteState > gTotalEEPROMWriteCommands){
      invalidateDCache(gBulkTxRxBuffer.RxBuffer, 3);
      if( (gBulkTxRxBuffer.RxBuffer[2] & ~EE_STATUS_WRITE_DONE_MASK) != 0){
	trace(DBG_USR1,"ERROR: EEPROM status reg = %#x\r\n", gBulkTxRxBuffer.RxBuffer[2]);
      }
      
      if( (gBulkTxRxBuffer.RxBuffer[2] & EE_STATUS_WRITE_DONE_MASK) == EE_STATUS_WRITE_DONE_MASK ){
	trace(DBG_USR1,"EEPROM Write Done\r\n");
	gQFAState = STATE_IDLE;
      }
      else{
	CREATE_MANUAL_QFA_READ_FRAME(gBulkTxRxBuffer.TxBuffer, EE_STATUS_ADDR);
	assert(call RawData.BulkTxRx((BulkTxRxBuffer_t *)&gBulkTxRxBuffer, 3));
      }
    }
    else{
      CREATE_QFA_FRAME(gBulkTxRxBuffer.TxBuffer, QFEEPROMRegisterTable, gEEPROMWriteState,0);
      assert(call RawData.BulkTxRx((BulkTxRxBuffer_t *)&gBulkTxRxBuffer, 3));
      gEEPROMWriteState++;
    }
  }

  task void sendNextEEPROMReadCmd(){
    if(gEEPROMReadState == gTotalEEPROMReadCommands){
      trace(DBG_USR1,"Finished Reading EEPROM..waiting for completion indication\r\n"); 
      
      CREATE_MANUAL_QFA_READ_FRAME(gBulkTxRxBuffer.TxBuffer, EE_STATUS_ADDR);
      assert(call RawData.BulkTxRx((BulkTxRxBuffer_t *)&gBulkTxRxBuffer, 3));
      gEEPROMReadState++;
    }
    else if(gEEPROMReadState > gTotalEEPROMReadCommands){
      invalidateDCache(gBulkTxRxBuffer.RxBuffer, 3);
      if( (gBulkTxRxBuffer.RxBuffer[2] & EE_STATUS_READ_DONE_MASK) == EE_STATUS_READ_DONE_MASK){
	trace(DBG_USR1,"EEPROM Read Done for block %d\r\n", gEEPROMReadBlock);
	gEEPROMReadBlock++;
	if(gEEPROMReadBlock < 4){
	  configureEEPROMRead(0x56+ (gEEPROMReadBlock)*0x30, 0xF00 + (gEEPROMReadBlock)*0x4, 4);
	  CHANGE_STATE(EEPROMRead);
	} 
	else{
	  CHANGE_STATE(SendRun);
	}
      }
      else{
	CREATE_MANUAL_QFA_READ_FRAME(gBulkTxRxBuffer.TxBuffer, GLBL_ID_ADDR);
	assert(call RawData.BulkTxRx((BulkTxRxBuffer_t *)&gBulkTxRxBuffer, 3));
      }
    }
    else{
      CREATE_QFA_FRAME(gBulkTxRxBuffer.TxBuffer, QFEEPROMRegisterTable, gEEPROMReadState,0);
      assert(call RawData.BulkTxRx((BulkTxRxBuffer_t *)&gBulkTxRxBuffer, 3));
      gEEPROMReadState++;
    }
  }

  task void sendNextCalCmd(){
   
    if(gCalState == gTotalCalCommands){
      CREATE_MANUAL_QFA_READ_FRAME(gBulkTxRxBuffer.TxBuffer, CAL_CTRL_ADDR);
      assert(call RawData.BulkTxRx((BulkTxRxBuffer_t *)&gBulkTxRxBuffer, 3));
      gCalState++;
    }
    else if(gCalState > gTotalCalCommands){
      invalidateDCache(gBulkTxRxBuffer.RxBuffer, 3);
      if( (gBulkTxRxBuffer.RxBuffer[2] & 0x8) == 0){
      	trace(DBG_USR1,"Calibration Complete...committing values to EEPROM\r\n");
	CHANGE_STATE(EEPROMWrite);
      }
      else{
	//cal is not yet complete....
	CREATE_MANUAL_QFA_READ_FRAME(gBulkTxRxBuffer.TxBuffer, CAL_CTRL_ADDR);
	assert(call RawData.BulkTxRx((BulkTxRxBuffer_t *)&gBulkTxRxBuffer, 3));
      }
    }
    else{
      CREATE_QFA_FRAME(gBulkTxRxBuffer.TxBuffer, QFCalRegisterTable, gCalState,0);
      assert(call RawData.BulkTxRx((BulkTxRxBuffer_t *)&gBulkTxRxBuffer, 3));
      gCalState++;
    }
  }
  
  void resetSampleCount(){
    int i;
    for(i=0; i<4; i++){
      gRxBufferPos[i] = 0;
    }
    trace(DBG_USR1,"Successfully reset sample count for all channels\r\n");
  }
  
  void storeSamplesAndCheckCompletion(uint16_t channelData[4], bool channelDataValid[4]){
    uint32_t i;
    uint16_t *currentBuffer;
    bool done = TRUE;
    for(i=0; i<4; i++){
      if( (gRxBuffers[i] != NULL) && (gRxBufferPos[i] < gRxNumSamples[i]) && (channelDataValid[i] == TRUE)){
	currentBuffer = gRxBuffers[i];
	currentBuffer[gRxBufferPos[i]] = channelData[i];
	gRxBufferPos[i] = gRxBufferPos[i] + 1;
	if(gRxBufferPos[i] == gRxNumSamples[i]){
	  //we've gotten all of the data requested of this channel...signal that we're done and get a new buffer if necessary
	  gRxBuffers[i] = (uint16_t *)signal SensorData.getSensorDataDone[i]((uint8_t *)gRxBuffers[i], 
									     gRxBufferPos[i], 
									     OSCR0, 
									     gChannelScale[i], 
									     gChannelOffset[i]);
	  if(gRxBuffers[i]){
	    gRxBufferPos[i]=0;
	  } 
	}
      } 
    }
    
    for(i=0; i<4; i++){
      done = done & (gRxBuffers[i] == NULL);
    }
    if(done){
      //in order to clean up state nicely...we will let 1 more command end
      atomic{
	gAccelStopState=1;
	gDoneCapturingData = TRUE;
	gBulkTxRxBuffer.TxBuffer[0] = QFStopRegisterTable[0].uiAddress;
	gBulkTxRxBuffer.TxBuffer[1] = QFStopRegisterTable[0].ucValue;
	cleanDCache(gBulkTxRxBuffer.TxBuffer,2);
      }

    }
  }   
  
  void readDone(uint32_t arg){
    bufferInfo_t *pBI = (bufferInfo_t *)arg;
    uint16_t currentData[4];
    bool currentDataValid[4];
    uint8_t currentChannel;
    uint8_t *buffer;
    unsigned int i=0;
    
    if(pBI == NULL){
      return;
    }
    
    assert(pBI->numBytes == DMASIZE);
    buffer = pBI->pBuf;
    if(gSaveData == FALSE){
      //we're currently in warmup mode...return buffers
      returnBuffer(&receiveBufferSet,(uint8_t *)buffer);
      returnBufferInfo(&receiveBufferInfoSet,pBI);
    }
    else{
      invalidateDCache(buffer, pBI->numBytes);
      
      for(i=0; i<4; i++){
	currentDataValid[i] = FALSE;
      }
      
      if( (gDropFirstSample == FALSE) && (gDoneCapturingData == FALSE)){
	
	//don't make any assumptions about the order that the data comes in
	for(i=0; i<4; i++){
	  //FIXME...condition needs to be &&'d with whether we want this channel in the first place
	  if(NEW_DATA(buffer[3*i]) == 1){
	    currentChannel = CHANNEL_ID(buffer[3*i]);
	    if(currentChannel < 4){
	      currentDataValid[currentChannel] = TRUE;
	      currentData[currentChannel] = SAMPLE( buffer[(3*i) + 1], buffer[(3*i) + 2]);  
	    }
	    else{
	      trace(DBG_USR1,"Found unknown sample index\r\n");
	    }
	  }
	}
      }
      else{
	gDropFirstSample = FALSE;
      }
      
      //we're actually done with the buffers passed to us here...return them
      returnBuffer(&receiveBufferSet,(uint8_t *)buffer);
      returnBufferInfo(&receiveBufferInfoSet,pBI);
      
      //check to see if we're done...if we're dropping the first sample, currentDataValid will be all false
      storeSamplesAndCheckCompletion(currentData, currentDataValid);
    }
  }
  
  task void getDataTask(){
    //FIXME
    trace(DBG_USR1,"ERROR:  QF4A512 is generated data too fast.  Estimated Sampling rate = ..\r\n");
    //need to clean up state here since we will now be prematurely ending the acquisition
    atomic{
      gAccelStopState=1;
      gDoneCapturingData = TRUE;
      gBulkTxRxBuffer.TxBuffer[0] = QFStopRegisterTable[0].uiAddress;
      gBulkTxRxBuffer.TxBuffer[1] = QFStopRegisterTable[0].ucValue;
      cleanDCache(gBulkTxRxBuffer.TxBuffer,2);
    }
    getData();
  }
  
  void getData(){
    uint8_t *tempBuf;
    
    if(!(tempBuf = getNextBuffer(&receiveBufferSet))){
	printFatalErrorMsg("Unable to obtain new buffer for receiving data...current level = ",
			   1,
			   getBufferLevel(&receiveBufferSet)); 
      }
      gBulkTxRxBuffer.RxBuffer = tempBuf;
      
      //if this assert fails, it means that we still have an oustanding transaction in the port
      //if this happens, it means that the board is most likely generating data faster than we can handle it
      if(call RawData.BulkTxRx((BulkTxRxBuffer_t *)&gBulkTxRxBuffer, 12) == FALSE){
	post getDataTask();
	returnBuffer(&receiveBufferSet,tempBuf);
      }
  }
  
  async event void DRDYInterrupt.fired(){
    
    //special handling so that we don't miss the first DRDY IRQ
    if(gDoneCapturingData == FALSE){
      
      //every time we get an indication that a new set of samples is ready
      //1.) allocate a new buffer
      //2.) store a pointer to the buffer in the gBulkTxRxBuffer structure that is used to do the transaction
      //3.) start the transaction
      //Notes:  no need to explicitly restore the pointer to the tx buffers since it will not have changed since the last time we did this
      getData();
    }
    else{
      call DRDYInterrupt.disable();
      gQFAState = STATE_SENDSTOP;
      //we will have already create the proper thing to send out since we wanted to do it the last time...
      gBulkTxRxBuffer.RxBuffer = gPrivateRxBuffer;
      assert(call RawData.BulkTxRx((BulkTxRxBuffer_t *)&gBulkTxRxBuffer, 2));
    }
    
    call DRDYInterrupt.clear();
    call Leds.greenToggle();
  } 
  
  async event uint8_t *RawData.BulkReceiveDone(uint8_t *RxBuffer, uint16_t NumBytes){
    return NULL;
  }
  
  task void signalBulkTransmitFail(){
    trace(DBG_USR1,"BulkTransmit failed\r\n");
  }
  
  async event uint8_t *RawData.BulkTransmitDone(uint8_t *TxBuffer, uint16_t NumBytes){
    return NULL;
  }

task void sendErrorEvent(){
  trace(DBG_USR1,"ERROR:  QF4A512M Received unknown send event\r\n");
}

  async event BulkTxRxBuffer_t *RawData.BulkTxRxDone(BulkTxRxBuffer_t *TxRxBuffer, uint16_t NumBytes){
    bufferInfo_t *pBI;
    
    switch(gQFAState){
    case STATE_LoadFilter:
      post sendNextLoadFilterCmd();
      break;
    case STATE_SendRun:
      post sendNextSendRunCmd();
      break;
    case STATE_SENDSTOP:
      post sendNextStopCmd();
      break;
    case STATE_MANUALREAD:
      post sendNextManualReadCmd();
      break;
    case STATE_EEPROMWrite:
      post sendNextEEPROMWriteCmd();
      break;
    case STATE_EEPROMRead:
      post sendNextEEPROMReadCmd();
      break;
    case STATE_RUN:
      
      //got at least the first one..it is now safe to enable the interrupt so that we can do this automatically in the future
      call DRDYInterrupt.enable(TOSH_RISING_EDGE);
      
      pBI = getNextBufferInfo(&receiveBufferInfoSet);
      assert(pBI);
      pBI->pBuf = TxRxBuffer->RxBuffer;
      pBI->numBytes = NumBytes;
      POST_PARAMTASK(readDone,pBI);

      break;
    case STATE_Cal:
      post sendNextCalCmd();
      break;
    case STATE_LoadCalFilter:
      post sendNextLoadCalFilterCmd();
      break;
    default:
      post sendErrorEvent();
    
    }

    return NULL;
  }

  command BluSH_result_t ManualRead.getName(char *buff, uint8_t len){
    
    const char name[] = "ReadQFA";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t ManualRead.callApp(char *cmdBuff, uint8_t cmdLen,
					     char *resBuff, uint8_t resLen){
    
    uint32_t startAddress, numBytes;
    if(strlen(cmdBuff) > strlen("ReadQFA ")){
      sscanf(cmdBuff,"ReadQFA %x %d", &startAddress, &numBytes);
      trace(DBG_USR1,"Reading %d bytes starting at QFA address %#x\r\n", numBytes, startAddress);
      
      //Make sure that we're initialized just in case the user calls this command before doing anything else 
      call StdControl.init();  

      //store global state for state machine
      gManualReadAddress = startAddress;
      gManualReadState = 0;
      gTotalManualReadCommands = numBytes;
      atomic{
	gBulkTxRxBuffer.RxBuffer = gPrivateRxBuffer;
	gBulkTxRxBuffer.TxBuffer = gPrivateTxBuffer;
      }
      
      gQFAState =  STATE_MANUALREAD;
      CREATE_MANUAL_QFA_READ_FRAME(gBulkTxRxBuffer.TxBuffer, gManualReadAddress);
      
      assert(call RawData.BulkTxRx((BulkTxRxBuffer_t *)&gBulkTxRxBuffer, 3));

      
    }
    else{
      trace(DBG_USR1,"ReadQFA startAddress(hex no leading 0x) numBytes\r\n");
    }
    
    return BLUSH_SUCCESS_DONE;
  }
  command BluSH_result_t ClearCal.getName(char *buff, uint8_t len){
    
    const char name[] = "ClearCal";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t ClearCal.callApp(char *cmdBuff, uint8_t cmdLen,
					     char *resBuff, uint8_t resLen){
    
    uint32_t channel;
    if(strlen(cmdBuff) <= strlen("ClearCal ")){
      trace(DBG_USR1,"ClearCal channel(1-4)\r\n");
      return BLUSH_SUCCESS_DONE;
    }
         

    sscanf(cmdBuff,"ClearCal %d", &channel);
    if( (channel < 1) || (channel > 4)){
      trace(DBG_USR1,"Channel must be between 1 and 4\r\n");
      return BLUSH_SUCCESS_DONE;
    }
	
    trace(DBG_USR1,"Clearing Calibration for channel %d\r\n",channel);
    
    //Make sure that we're initialized just in case the user calls this command before doing anything else 
    call StdControl.init();  
    
    //set offset registers to 0 so that we get a reasonable value
    QFCalRegisterTable[0].uiAddress = 0x56 + (channel-1)*0x30;
    QFCalRegisterTable[0].ucValue = 0x0;
    
    QFCalRegisterTable[1].uiAddress = 0x57 + (channel-1)*0x30;
    QFCalRegisterTable[1].ucValue = 0x0;
    
    //if we're doing an offset calibration, our gain needs to be the default value
    QFCalRegisterTable[2].uiAddress = 0x58 + (channel-1)*0x30;
    QFCalRegisterTable[2].ucValue = 0x0;
    
    QFCalRegisterTable[3].uiAddress = 0x59 + (channel-1)*0x30;
    QFCalRegisterTable[3].ucValue = 0x80;
    
    gTotalCalCommands = 4;
    //setup the EEPROM write so that we can commit later
    //offset registers = 0x56-0x57 + (channel-1)*0x30;
    configureEEPROMWrite(0x56+ (channel-1)*0x30, 0xF00 + (channel-1)*4, 4);
    
    //explicitly disable the interrupt so that we don't get anything too early
    call DRDYInterrupt.disable();
    
    atomic{
      gBulkTxRxBuffer.RxBuffer = gPrivateRxBuffer;
      gBulkTxRxBuffer.TxBuffer = gPrivateTxBuffer;
    }
    CHANGE_STATE(Cal);
    return BLUSH_SUCCESS_DONE;
  }

}



