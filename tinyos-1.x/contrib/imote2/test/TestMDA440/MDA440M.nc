includes downsample;

module MDA440M{
  provides {
    interface MDA440;
  }
  uses {
   interface SSP;
   interface BulkTxRx;
   interface PXA27XGPIOInt as TACHInterrupt;
  }
}
implementation {

    
#define VCC3_SENSOR_EN_PIN (82)
#define VCC5_SENSOR_EN_PIN (55)
#define VCC18_EN_PIN (56)
#define MUX0_ACCEL_PWR_EN_PIN (30)
#define MUX0_ACCEL_SIG_EN_PIN (57)
#define MUX0_LOSPEED_EN_PIN (84)
#define MUX0_TEMP_EN_PIN (83)
#define ADS1271_MODE_PIN (10)    
#define ADS1271_SYNC_PIN (17)
#define CPLDRESET_PIN (12) 
  
  TOSH_ASSIGN_PIN(VCC3_SENSOR_EN, A, VCC3_SENSOR_EN_PIN);
  TOSH_ASSIGN_PIN(VCC5_SENSOR_EN, A, VCC5_SENSOR_EN_PIN);
  TOSH_ASSIGN_PIN(VCC18_EN, A, VCC18_EN_PIN);
  
  TOSH_ASSIGN_PIN(MUX0_ACCEL_SIG_EN, A, MUX0_ACCEL_SIG_EN_PIN);
  TOSH_ASSIGN_PIN(MUX0_ACCEL_PWR_EN, A, MUX0_ACCEL_PWR_EN_PIN);
  
  TOSH_ASSIGN_PIN(MUX0_LOSPEED_EN, A, MUX0_LOSPEED_EN_PIN);
  TOSH_ASSIGN_PIN(MUX0_TEMP_EN, A, MUX0_TEMP_EN_PIN);
  TOSH_ASSIGN_PIN(ADS1271_MODE,A, ADS1271_MODE_PIN);
  TOSH_ASSIGN_PIN(ADS1271_SYNC,A, ADS1271_SYNC_PIN);
  TOSH_ASSIGN_PIN(CPLDRESET,A, CPLDRESET_PIN);
  
    
    //for now, the assumption will be that the first 3 define the address lines and the last one defines the enable line
    const uint8_t Mux0[4] = {50, 48, 81, 0};
    const uint8_t Mux1[4] = {53, 52, 51, 0};
    const uint8_t Mux2[4] = {106, 54, 0, 85};
    
  
#define DEFINE_PARAMTASK(funcname) \
task void _##funcname##veneer(){\
uint32_t argument;\
popqueue(&paramtaskQueue,&argument);\
funcname(argument);}
  
#define POST_PARAMTASK(funcname, arg) \
{pushqueue(&paramtaskQueue, arg);post _##funcname##veneer();}
  
  
#define DMASIZE 2048
  //#define DOWNSAMPLEFACTOR 1
  
  
  downsampleStates_t downsampleStates;
  downsampleTempBuffer_t downsampleTempBuffer[DMASIZE/4];
  
#define NUMBUFFERS 3
  
  typedef struct{
    short buf[DMASIZE] __attribute ((aligned(32)));
    bool inuse;
  } buffer_t;
  
  buffer_t tempBuffers[NUMBUFFERS];
  
  
  uint8_t *getNextBuffer(){
    int i;
    uint8_t *ret = NULL;
    atomic{
      for(i=0;i<NUMBUFFERS; i++){
	if(tempBuffers[i].inuse == FALSE){
	  tempBuffers[i].inuse = TRUE;
	  ret = (uint8_t *)tempBuffers[i].buf;
	  break;
	}
      }
    }
    return ret;
  }

  void returnBuffer(short *buf){
    int i;
    atomic{
      for(i=0;i<NUMBUFFERS; i++){
	if(tempBuffers[i].buf == buf){
	  tempBuffers[i].inuse = FALSE;
	}
      }
    }
  }
  
  void initBuffer(){
    int i;
    atomic{
      for(i=0;i<NUMBUFFERS; i++){
	tempBuffers[i].inuse = FALSE;
      }
    }
  }
  
  uint8_t *gOutBuffer;
  uint16_t *gOutBufferTemp;
  uint32_t gOutBufferIncrement;
  
  uint16_t gOutBufferCount;
  uint16_t gInBufferCount;
  uint16_t gBufferCountMax;

  uint32_t gDownsampleFactor;
  bool gDropFirstBuffer;

  uint32_t gTotalTachTime;
  uint32_t gTotalTachSamples;
  
  void EnableMux(const uint8_t mux[4]){
    if(mux[3]){
      GPIO_SET_ALT_FUNC(mux[3],0, GPIO_OUT);
      SET_GPIO(mux[3]);
    }
  }
  
    void DisableMux(const uint8_t mux[4]){
      if(mux[3]){
	GPIO_SET_ALT_FUNC(mux[3],0, GPIO_OUT);
	CLEAR_GPIO(mux[3]);
      }
    }
  
  void SetMuxAddress(const uint8_t mux[4], uint8_t bit0, uint8_t bit1, uint8_t bit2){
    if(mux[0]){
      GPIO_SET_ALT_FUNC(mux[0],0, GPIO_OUT);
	if(bit0==0){ 
	  CLEAR_GPIO(mux[0]);
	}
	else{  
	  SET_GPIO(mux[0]);
	}
      }
      if(mux[1]){
	GPIO_SET_ALT_FUNC(mux[1],0, GPIO_OUT);
	if(bit1==0){
	  CLEAR_GPIO(mux[1]);
	} 
	else {
	  SET_GPIO(mux[1]);
	}
      }
      if(mux[2]){
	GPIO_SET_ALT_FUNC(mux[2], 0, GPIO_OUT);
	if(bit2==0) {
	  CLEAR_GPIO(mux[2]);
	}
	else{
	  SET_GPIO(mux[2]);
	}
      }
    }
   
    
    command result_t MDA440.init(){
      
      TOSH_CLR_CPLDRESET_PIN();
      TOSH_MAKE_CPLDRESET_OUTPUT();

      TOSH_SET_VCC3_SENSOR_EN_PIN();
      TOSH_CLR_VCC5_SENSOR_EN_PIN();
      TOSH_SET_VCC18_EN_PIN();
      TOSH_CLR_MUX0_ACCEL_SIG_EN_PIN();
      TOSH_CLR_MUX0_ACCEL_PWR_EN_PIN();
      DisableMux(Mux2);
      
      TOSH_CLR_MUX0_LOSPEED_EN_PIN();
      TOSH_CLR_MUX0_TEMP_EN_PIN();
      
      TOSH_MAKE_VCC3_SENSOR_EN_OUTPUT();
      TOSH_MAKE_VCC5_SENSOR_EN_OUTPUT();
      TOSH_MAKE_VCC18_EN_OUTPUT();
      TOSH_MAKE_MUX0_ACCEL_PWR_EN_OUTPUT();
      TOSH_MAKE_MUX0_ACCEL_SIG_EN_OUTPUT();
      TOSH_MAKE_MUX0_LOSPEED_EN_OUTPUT();
      TOSH_MAKE_MUX0_TEMP_EN_OUTPUT();

      TOSH_SET_CPLDRESET_PIN();

      initBuffer();
      
      
      //put the A/D in high-resolution mode
      TOSH_MAKE_ADS1271_MODE_INPUT();
      
      //put the A/D in powerdown mode until we can actually do something to it
      TOSH_CLR_ADS1271_SYNC_PIN();
      TOSH_MAKE_ADS1271_SYNC_OUTPUT();
      
      GPIO_SET_ALT_FUNC(107,0,GPIO_IN);
      call TACHInterrupt.enable(TOSH_FALLING_EDGE);
      gTotalTachTime=0;
      gTotalTachSamples=0;
      

      //HACK For now because something stange is happening
      //TOSH_SET_ADS1271_SYNC_PIN();
      
      //SSP must be told whether it's Master or Slave to SCLK or SFRM and then
      //it can be inited.  All other parameters must be set after init is
      // called
      call SSP.setMasterSCLK(TRUE);
      call SSP.setMasterSFRM(FALSE);
      //      call SSP.init();


      //call SSP.setSSPFormat(SSP_SSP);    //SSP format
      call SSP.enableInvertedSFRM(TRUE);
      call SSP.setDataWidth(SSP_16bits); //16 bit data
      call SSP.setClkRate(1); //divide by 2...6.5MHz clk
      call SSP.setReceiveWithoutTransmit(TRUE);
     
      return SUCCESS;
    }


    command result_t MDA440.enableHighSpeedChain(){
      TOSH_CLR_VCC3_SENSOR_EN_PIN();
      TOSH_SET_VCC5_SENSOR_EN_PIN();
      TOSH_SET_VCC18_EN_PIN();
      SetMuxAddress(Mux2,0,0,0);
      EnableMux(Mux2);
      return SUCCESS;
    }

    command result_t MDA440.disableHighSpeedChain(){
      TOSH_SET_VCC3_SENSOR_EN_PIN();
      TOSH_CLR_VCC5_SENSOR_EN_PIN();
      TOSH_CLR_VCC18_EN_PIN();
      
      DisableMux(Mux2);
      return SUCCESS;
    }
    
    command result_t MDA440.disableLowSpeedChain(){
      TOSH_SET_VCC3_SENSOR_EN_PIN();
      TOSH_CLR_VCC5_SENSOR_EN_PIN();
      TOSH_SET_VCC18_EN_PIN();
      
      DisableMux(Mux2);
      return SUCCESS;
    }
    
    command result_t MDA440.enableLowSpeedChain(){
      TOSH_CLR_VCC3_SENSOR_EN_PIN();
      TOSH_SET_VCC5_SENSOR_EN_PIN();
      TOSH_CLR_VCC18_EN_PIN();  //make sure it's off
      SetMuxAddress(Mux2,0,1,0); //select Low speed
      EnableMux(Mux2);
      return SUCCESS;
    }
    
    command result_t MDA440.turnOffBoard(){
      TOSH_SET_VCC3_SENSOR_EN_PIN();
      TOSH_CLR_VCC5_SENSOR_EN_PIN();
      TOSH_CLR_VCC18_EN_PIN();
      TOSH_CLR_MUX0_ACCEL_PWR_EN_PIN();
      TOSH_CLR_MUX0_ACCEL_SIG_EN_PIN();
      DisableMux(Mux2);
      TOSH_CLR_MUX0_LOSPEED_EN_PIN();
      TOSH_CLR_MUX0_TEMP_EN_PIN();
      return SUCCESS;
    
    }	
    
    command result_t MDA440.selectMux0Channel(uint8_t channel){
      
      switch(channel)
	{
	case 0: SetMuxAddress(Mux0,0,0,0);
	  break;
	case 1: SetMuxAddress(Mux0,1,0,0);
	  break;
	case 2: SetMuxAddress(Mux0,0,1,0);
	  break;
	case 3: SetMuxAddress(Mux0,1,1,0);
	  break;
	case 4: SetMuxAddress(Mux0,0,0,1);
	  break;
	case 5: SetMuxAddress(Mux0,1,0,1);
	  break;
	case 6: SetMuxAddress(Mux0,0,1,1);
	  break;
	case 7: SetMuxAddress(Mux0,1,1,1);
	    break;
	default:
	  return FAIL;
	} 
      return SUCCESS;
    }
    
    command result_t MDA440.selectLowSpeedChannel(uint8_t channel){
            
      switch(channel)
	{
	case 0: SetMuxAddress(Mux1,0,0,0);
	  break;
	case 1: SetMuxAddress(Mux1,1,0,0);
	  break;
	case 2: SetMuxAddress(Mux1,0,1,0);
	  break;
	case 3: SetMuxAddress(Mux1,1,1,0);
	  break;
	case 4: SetMuxAddress(Mux1,0,0,1);
	  break;
	case 5: SetMuxAddress(Mux1,1,0,1);
	  break;
	case 6: SetMuxAddress(Mux1,0,1,1);
	  break;
	case 7: SetMuxAddress(Mux1,1,1,1);
	    break;
	default:
	  return FAIL;
	  break;
	  }
      return SUCCESS;
    }    
    
    command result_t MDA440.getSamples(uint8_t *buffer, uint16_t NumSamples, uint32_t K){
      uint8_t *tempBuf;
      
      TOSH_SET_ADS1271_SYNC_PIN();
      downsampleInit(&downsampleStates,downsampleTempBuffer);
      
      //need to call this the first time here
      atomic{
	gOutBuffer = buffer; //buffer that we eventually need to return
	gOutBufferTemp = (uint16_t *) buffer; //pointer that we can manipulate with pointer arihmetic
	gOutBufferIncrement = DMASIZE/K;
	
	gOutBufferCount = 0; //loop counter for iterations
	gInBufferCount = 0;

	gBufferCountMax = ((NumSamples/DMASIZE)* K) + ((K>1)?1:0); //precomputed number of iterations..used by both DMA side and downsample side
	gDropFirstBuffer = (K>1)?TRUE:FALSE;
	gDownsampleFactor = K;

      }
      tempBuf = getNextBuffer();
      if(tempBuf){
	call BulkTxRx.BulkReceive(tempBuf, DMASIZE*2);
      }
      else{
	trace(DBG_USR1,"unable to obtain buffer at start\r\n");
      }
            //TOSH_SET_ADS1271_SYNC_PIN();
      return SUCCESS;
    }

    command result_t MDA440.setAccelIn(uint8_t channel){
        // Helper commands
      call  MDA440.enableHighSpeedChain();
      call  MDA440.selectMux0Channel(7);
      TOSH_SET_MUX0_ACCEL_SIG_EN_PIN();
      TOSH_SET_MUX0_ACCEL_PWR_EN_PIN();
      
      GPIO_SET_ALT_FUNC(85,0,GPIO_OUT);
      SET_GPIO(85);
      TOSH_CLR_VCC3_SENSOR_EN_PIN();
      TOSH_SET_VCC5_SENSOR_EN_PIN();
      TOSH_CLR_ADS1271_SYNC_PIN();
      
      return SUCCESS;
    }
    
    command result_t MDA440.setTempIn(uint8_t channel){
      call  MDA440.enableLowSpeedChain();
      call  MDA440.selectMux0Channel(7);
      TOSH_SET_MUX0_ACCEL_SIG_EN_PIN();
      TOSH_SET_MUX0_ACCEL_PWR_EN_PIN();
      
      GPIO_SET_ALT_FUNC(85,0,GPIO_OUT);
      SET_GPIO(85);
      TOSH_CLR_VCC3_SENSOR_EN_PIN();
      TOSH_SET_VCC5_SENSOR_EN_PIN();
      TOSH_CLR_ADS1271_SYNC_PIN();
      
      return SUCCESS;
    }
    
    command result_t MDA440.setCurrentIn(uint8_t channel){
      call MDA440.enableLowSpeedChain();
      call MDA440.selectMux0Channel(channel);
      call MDA440.selectLowSpeedChannel(3);
      TOSH_SET_MUX0_LOSPEED_EN_PIN();
      TOSH_SET_MUX0_ACCEL_SIG_EN_PIN();
      TOSH_SET_MUX0_ACCEL_PWR_EN_PIN();
      
      GPIO_SET_ALT_FUNC(85,0,GPIO_OUT);
      SET_GPIO(85);
      TOSH_CLR_VCC3_SENSOR_EN_PIN();
      TOSH_SET_VCC5_SENSOR_EN_PIN();
      TOSH_CLR_ADS1271_SYNC_PIN();
      
      
      return SUCCESS;
    }
    
    command result_t MDA440.enableTachTrigger(bool enable){
      return SUCCESS;
    }
    
    command result_t MDA440.setRefVoltageIn(){
      return SUCCESS;
    }
        
 
  void postProcessBuffer(uint8_t *data){
    
    uint32_t time = OSCR0;
        
    downsample(&downsampleStates, (short *)data, DMASIZE,
	       gOutBufferTemp,
	       gDownsampleFactor);
    returnBuffer(data);
    if(gDropFirstBuffer){
      gDropFirstBuffer = FALSE;
    }    
    else{
      gOutBufferTemp += gOutBufferIncrement;
    }
      
    gOutBufferCount++;
    
    time = OSCR0-time;
    trace(DBG_USR1,"downsample %d, %d\r\n",time, gOutBufferCount);
    if(gOutBufferCount >= gBufferCountMax){
      signal MDA440.getSamplesDone(gOutBuffer);
    }
    return;
  }
  DEFINE_PARAMTASK(postProcessBuffer);
  
  
  async event uint8_t *BulkTxRx.BulkReceiveDone(uint8_t *data, uint16_t NumBytes){
    uint8_t *tempBuf= NULL;
    
    POST_PARAMTASK(postProcessBuffer,data);
    gInBufferCount++;
    
    if( gInBufferCount < gBufferCountMax){
      tempBuf = getNextBuffer();
    }
    else{
      //iff we're done, stop the ADC, stop DMA, let the last decimate run which should signal the upper layer
      TOSH_CLR_ADS1271_SYNC_PIN();
      return NULL;
    }
    if(!tempBuf){
      trace(DBG_USR1,"unable to obtain buffer %d\r\n", gInBufferCount);
    }
    return tempBuf;
  }
  
  async event uint8_t *BulkTxRx.BulkTransmitDone(uint8_t *data, 
						 uint16_t numBytes){
    return NULL;
  }

  async event BulkTxRxBuffer_t *BulkTxRx.BulkTxRxDone(BulkTxRxBuffer_t *TxRxBuffer,
							  uint16_t numBytes){
    return NULL;
  }

  
  
  async event void TACHInterrupt.fired(){
    static norace int32_t lastValue=0;
    int32_t currentValue,totalTime;
    currentValue = OSCR0;
    call TACHInterrupt.clear();
    totalTime = currentValue-lastValue;
    atomic{
      gTotalTachTime += totalTime;
      gTotalTachSamples++;
    }
    
    lastValue = currentValue;
  } 
  
  command result_t MDA440.startTach(){
    atomic{
      gTotalTachTime = 0;
      gTotalTachSamples = 0;
    }
  }
  
  command result_t MDA440.stopTach(uint32_t *totalTime, uint32_t *totalSamples){
    if(totalTime && totalSamples){
      atomic{
	*totalTime = gTotalTachTime;
	*totalSamples = gTotalTachSamples;
      }
      return SUCCESS;
    }
    else{
      return FAIL;
    }
  }
  
}
