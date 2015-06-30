/**
 * @author Robbie Adler
 **/

module WM8940M{
  provides{
    interface StdControl;
    interface Audio;
  }
  uses{
    interface I2S;
    interface BulkTxRx;
    interface I2CBusSequence;
    interface StdControl as I2CSequenceControl;
  }
}

implementation{

#include "WM8940.h"  
#include "intel16.h"

#include "math.h"
#define SLAVE_WRITE_ADDR (0x1A)

#ifndef SAMPLINGRATE
#define SAMPLINGRATE (8)
  //WM8940_SR configured WM8940's digital filters for the the right sampling rate
#define WM8940_SR (5) 
#define PXA_SYSCLK (I2S_SYSCLK_2p053M)

#endif
  
#define TEST_LEN (2000)

  typedef enum
    {
      I2CState_IDLE,
      I2CState_PowerOn,
      I2CState_PowerOff
    } I2CState_t;
  
  
  uint8_t gI2CInProgress = FALSE;
  uint8_t gPowerOnState = 0;
  I2CState_t gI2CState = I2CState_IDLE;
  norace bool gInitPlay = TRUE;
  
  uint32_t *gRxBuffer;
  norace uint16_t gRxNumBytes, gRxBufferPos;
  
  uint32_t *gTxBuffer;
  norace uint32_t gTxNumBytes, gTxBufferPos;

  i2c_op_t I2CRegisterSequence[] = { 
    {I2C_START,0,0},
    {I2C_WRITE, SLAVE_WRITE_ADDR<<1, 0},
    {I2C_WRITE, 0x3, 0},  //placeholder for register address to write 
    {I2C_WRITE, 0x3, 0},  //placeholder for high order-byte of data to write 
    {I2C_END, 0x0, 0},  //after next write, send stop bit
    {I2C_WRITE, 0x0, 0},  //placeholder for low-order byte of data to write
  };
#define I2CREGISTERSEQUENCELEN (sizeof(I2CRegisterSequence)/sizeof(*I2CRegisterSequence))
  
  task void continuePowerOnSequence();

  result_t writeRegister(uint8_t address, uint16_t data){
    uint8_t localI2CInProgress;

    atomic{
      if(gI2CInProgress == TRUE){
	localI2CInProgress = FALSE;
      }
      else{
	localI2CInProgress = TRUE;
      }
    }
    if(localI2CInProgress == FALSE){
      return FAIL;
    }
    
    I2CRegisterSequence[2].param = address;
    I2CRegisterSequence[3].param = (uint8_t) ((data >> 8) & 0xFF);
    I2CRegisterSequence[5].param = (uint8_t) ((data ) & 0xFF);
    return call I2CBusSequence.runI2CBusSequence(I2CRegisterSequence, I2CREGISTERSEQUENCELEN);    
  }
  
  result_t issuePowerOnSequence(){
    if(gI2CState != I2CState_IDLE){
      return FAIL;
    }
    if(gPowerOnState != 0){
      return FAIL;
    }
    
    gI2CState = I2CState_PowerOn;
      
    return post continuePowerOnSequence();
  }
  
  task void issuePowerOnSequenceDone(){
    
    trace(DBG_USR1,"Completed WM8940 PowerOn Sequence\r\n");
    call I2S.enableRecord(TRUE);
    call I2S.enablePlayback(TRUE);
    call I2S.enableI2S(TRUE);
    
    atomic{
      gTxBufferPos = 0;
      gTxBuffer = pcmdata;
      gTxNumBytes = pcmdatalen;
      
      gRxBufferPos = 0;
      gRxBuffer = NULL;
      gRxNumBytes = 0;
      
    }
    
    call BulkTxRx.BulkTransmit((uint8_t *)pcmdata, (pcmdatalen > 8188)? 8188: pcmdatalen);
  }
  
  task void continuePowerOnSequence(){
    uint8_t address = 0;
    uint16_t data = 0;
    bool doWrite = TRUE;
    /**
     * Power on Sequence from datasheet page 64
     * 1.) turn on power supplies and wait for supply voltages to settle
     * 2.) Reset internal registers with SW reset command
     * 3.) enable non-VMID derived bias generator (VMID_OP_EN=1) and level shifters (LVLSHIFT_EN = 1)
     * 4.) enable DAC soft mute (DACMU = 1)
     * 5.) select clk source to MCLK (CLKSEL = 0) and audio mode (master or slave)
     * 6.) enable power on Bias Conrtrol (POB_CTRL = 1) and wait for outputs to settle
     * 7.) enable speaker outputs (SPKPEN = 1, and SPKNEN = 1) and wait for outputs to settle
     * 8.) set VMIDSEL[1:0] bits for 50kohm reference string impedance
     * 9.) wait for VMID supply to settle (choose the value of VMIDSEL bits based on startup time
     *     VMIDSEL = 10 for the slowest startup time, VMIDSEL = 11 for the fastest startup). Startup
     *     time is defined by the value of the VMIDSEL bits (the reference impedance) and the external
     *     decoupling capacitor on VMID.
     *10.) enable analogue amplifier bias control (BIASEN = 1) and VMID buffer (BUFIOEN = 1)
     *11.) disable power on Bias Control (POB_CTRL = 1) and VMID soft start (SOFT_START = 1)
     *12.) Enable DAC (DACEN=1) and speaker Mixer (SPKMIXEN = 1).
     *13.) enable output of DAC to speaker mixer (DAC2SPK = 1).
     *14.) disable speaker mute (SPKMUTE = 0) and set SPKVOL = -57dB.
     *15.) Ramp up SPKVOL using the following values: -27dB, -15dB, -13dB, -11dB, -9dB, -8dB, -7dB
     *     -6dB, -5dB, -4dB, -3dB, -2dB, -1dB, 0dB.
     *16.) Disable DAC soft mute (DACMU = 0)
     *
     *17.) TODO!!!  ADD initialization for record path (not included on page 64)...rough flow is below
     *18.) Configure Mic biasing
     *19.) Configure input PGA settings
     *20.) Configure boost circuit
     *21.) Set ADC volume
     *22.) enable ADC
     
     
     **/
    
    switch(gPowerOnState){
    case 0:
      //Reset internal registers with SW reset command
      address = SOFTWARERESET;
      data = 0;

      break;
    case 1:
      //enable non-VMID derived bias generator (VMID_OP_EN=1) and level shifters (LVLSHIFT_EN = 1)
      address = POWERMANAGEMENT1;
      data = POWERMANAGEMENT1_VMID_OP_EN | POWERMANAGEMENT1_LVLSHIFT_EN;
      break;
    case 2:
      //enable DAC soft mute (DACMU = 1)
      address = DACCONTROL;
      data = DACCONTROL_DACMU;
      break;
      
    case 3:
      //select clk source to MCLK (CLKSEL = 0) and audio mode (master or slave)
      address = CLOCKGENCONTROL;
      data = CLOCKGENCONTROL_MCLKDIV(0) | CLOCKGENCONTROL_BCLKDIV(0);  //MS = 0 and CLKSEL = MCLK
      break;
    
    case 4:
      //enable power on Bias Conrtrol (POB_CTRL = 1) and VMID soft start (SOFT_START = 1)
      address = ADDITIONALCONTROL;
      data = ADDITIONALCONTROL_POB_CTRL | ADDITIONALCONTROL_SOFT_START | ADDITIONALCONTROL_SR(WM8940_SR);
      break;
      
    case 5:
      //enable speaker outputs (SPKPEN = 1, and SPKNEN = 1) and wait for outputs to settle
      address = POWERMANAGEMENT3;
      data = POWERMANAGEMENT3_SPKPEN | POWERMANAGEMENT3_SPKNEN;
      break;

    case 6:
      //set VMIDSEL[1:0] bits for 50kohm reference string impedance
      address = POWERMANAGEMENT1;
      data = POWERMANAGEMENT1_VMID_OP_EN | POWERMANAGEMENT1_LVLSHIFT_EN | POWERMANAGEMENT1_VMIDSEL(1);
      break;

    case 7:
      //   wait for VMID supply to settle (choose the value of VMIDSEL bits based on startup time
      //   VMIDSEL = 10 for the slowest startup time, VMIDSEL = 11 for the fastest startup). Startup
      //   time is defined by the value of the VMIDSEL bits (the reference impedance) and the external
      //   decoupling capacitor on VMID.
      TOSH_uwait(1000);
      doWrite = FALSE;
      
      break;
      
    case 8:
      // enable analogue amplifier bias control (BIASEN = 1) and VMID buffer (BUFIOEN = 1)
      address = POWERMANAGEMENT1;
      data = POWERMANAGEMENT1_VMID_OP_EN | POWERMANAGEMENT1_LVLSHIFT_EN | POWERMANAGEMENT1_VMIDSEL(1) | POWERMANAGEMENT1_BIASEN | POWERMANAGEMENT1_BUFIOEN | POWERMANAGEMENT1_MICBEN;
      break;
    
    case 9:
      // disable power on Bias Cont(int16_t)rol (POB_CTRL = 0) and VMID soft start (SOFT_START = 0)
      address = ADDITIONALCONTROL;
      data = ADDITIONALCONTROL_SR(WM8940_SR);
      break;
      
    case 10:
      // Enable DAC (DACEN=1) and speaker Mixer (SPKMIXEN = 1).
      address = POWERMANAGEMENT3;
      data = POWERMANAGEMENT3_SPKPEN | POWERMANAGEMENT3_SPKNEN | POWERMANAGEMENT3_DACEN | POWERMANAGEMENT3_SPKMIXEN; 
      break;
      
    case 11:
      // enable output of DAC to speaker mixer (DAC2SPK = 1).
      address = SPKMIXERCONTROL;
      data = SPKMIXERCONTROL_DAC2SPK;
      break;

    case 12:
      //  disable speaker mute (SPKMUTE = 0) and set SPKVOL = -57dB.
      address = SPKVOLUMECONTROL;
      data = 0;  //mute and spkvol = -57dB
      break;

    case 13: 
      // set SPKVOL to -27dB, 
      address = SPKVOLUMECONTROL;
      data = SPKVOLUMECONTROL_SPKVOL((-27) - (-57));
      break;

    case 14:
      // set SPKVOL to -15dB, 
      address = SPKVOLUMECONTROL;
      data = SPKVOLUMECONTROL_SPKVOL((-25) - (-57));
      break;

    case 15: 
      // set SPKVOL to -13dB, 
      address = SPKVOLUMECONTROL;
      data = SPKVOLUMECONTROL_SPKVOL((-13) - (-57));
      break;

    case 16: 
      // set SPKVOL to -11dB, 
      address = SPKVOLUMECONTROL;
      data = SPKVOLUMECONTROL_SPKVOL((-11) - (-57));
      break;

    case 17: 
      // set SPKVOL to -9dB, 
      address = SPKVOLUMECONTROL;
      data = SPKVOLUMECONTROL_SPKVOL((-9) - (-57));
      break;

    case 18: 
      // set SPKVOL to -8dB, 
      address = SPKVOLUMECONTROL;
      data = SPKVOLUMECONTROL_SPKVOL((-8) - (-57));
      break;

    case 19: 
      // set SPKVOL to -7dB, 
      address = SPKVOLUMECONTROL;
      data = SPKVOLUMECONTROL_SPKVOL((-7) - (-57));
      break;

    case 20: 
      // set SPKVOL to -6dB, 
      address = SPKVOLUMECONTROL;
      data = SPKVOLUMECONTROL_SPKVOL((-6) - (-57));
      break;

    case 21: 
      // set SPKVOL to -5dB, 
      address = SPKVOLUMECONTROL;
      data = SPKVOLUMECONTROL_SPKVOL((-5) - (-57));
      break;

    case 22: 
      // set SPKVOL to -4dB, 
      address = SPKVOLUMECONTROL;
      data = SPKVOLUMECONTROL_SPKVOL((-4) - (-57));
      break;

    case 23: 
      // set SPKVOL to -3dB, 
      address = SPKVOLUMECONTROL;
      data = SPKVOLUMECONTROL_SPKVOL((-3) - (-57));
      break;

    case 24: 
      // set SPKVOL to -2dB, 
      address = SPKVOLUMECONTROL;
      data = SPKVOLUMECONTROL_SPKVOL((-2) - (-57));
      break;

    case 25: 
      // set SPKVOL to -1dB, 
      address = SPKVOLUMECONTROL;
      data = SPKVOLUMECONTROL_SPKVOL((-1) - (-57));
      break;

    case 26: 
      // set SPKVOL to -0dB, 
      address = SPKVOLUMECONTROL;
      data = SPKVOLUMECONTROL_SPKVOL((0) - (-57));
      break;
      
    case 27:
      //Disable DAC soft mute (DACMU = 0)
      address = DACCONTROL;
      data = 0;
      break;

    case 28:
      //set the Codec's audio interface to the correct mode
      address = AUDIOINTERFACE;
      data = AUDIOINTERFACE_LOUTR | AUDIOINTERFACE_WL(0) | AUDIOINTERFACE_FMT(2);  
      //data for DAC and ADC are in left phase.  This should put data in lower 16 bits of I2S FIFO
      break;
      
    case 29:
      //connect microphone to input PGA
      address = INPUTCTRL;
      data  = INPUTCTRL_MICN2INPPGA | INPUTCTRL_MICP2INPPGA;
      break;
      
    case 30:
      //enable input PGA, ADC, and BOOST
      address = POWERMANAGEMENT2;
      data = POWERMANAGEMENT2_INPPGAEN | POWERMANAGEMENT2_ADCEN | POWERMANAGEMENT2_BOOSTEN;
      break;

    case 31:
      //set pga volume to max, disable pga mute, set pga to update on first zero crossing
      address = INPPGAGAINCTRL;
      data = INPPGAGAINCTRL_INPPGAZC | INPPGAGAINCTRL_INPPGAVOL(0x3F);
      break;
         
    case 32:
      //set the adc digital attenuation to 0db (value of 0xFF)
      address = ADCDIGITALVOLUME;
      data = 0xFF;
      break;
      
    case 33:
      //we're done!
      gPowerOnState = 0;
      gI2CState = I2CState_IDLE;
      post issuePowerOnSequenceDone();
      doWrite = FALSE;
      return;
      
    default:
      doWrite = FALSE;
      trace(DBG_USR1,"WM8940 found invalid state %d in Powerup Sequence\r\n", gPowerOnState);
      
    }
    
    if(doWrite == TRUE){
      if(writeRegister(address, data) == FAIL){
	post continuePowerOnSequence();
      }  
      else{
	gPowerOnState++;
      }
    }
    else{
      //if we're not writing it's because we did something (mostly likely just waited some time for something to settle) and that it's time to move on
      gPowerOnState++;
      post continuePowerOnSequence();
    }
  }
  command result_t StdControl.init(){
    /**
     *
     * I2S_SYSCLK = K4 (113)
     * I2S_SYNC = J4 (31)
     * I2S_BITCLK = K1 (28)
     * I2S_DATA_IN = K2 (29)
     * I2S_DATA_OUT = G6 (30)
     *
     * 
     *
     * From section 14.4.1 of the PXA27X developer's manual, the step to init are:
     * 1.) set I2S_BITCLK direction
     * 2.) choose between I2S or MSB-justified modes.  WM8940 uses normal I2S mode
     * 3.) optionally use programmed I/O to prime the tx fifo
     * 4.) Set the SACRO to enable (set ENB bit) and to set tx and rx fifo thresholds 
     *
     *
     **/

    call I2CSequenceControl.init();
    call I2S.setAudioClkDivider(PXA_SYSCLK);
    call I2S.setBitClkDir(FALSE);
    
    call I2S.enableMSBJustifiedMode(FALSE);
    call I2S.setRxFifoLevel(I2S_8Samples);
    call I2S.setTxFifoLevel(I2S_8Samples);
    
    return SUCCESS;
  }

  task void initI2S(){
    call I2S.initI2S();   
  }
  
  command result_t StdControl.start(){
    /**
     *To actually have data played out the codec, the following must occur
     *
     * the audio interface for the PXA27x must be configured
     * the codec output must be turned on
     * the code must be placed into slave mode (default)
     * the audio interface should be enabled
     *
     * Other notes:  codec default sampling rate is 48KHz
     *
     * see page 64 for suggested power on order
     *    
     *
     * 
     **/
    call I2CSequenceControl.start();
    post initI2S();
    return SUCCESS;
    
  }

  command result_t StdControl.stop(){

    /**
     * See page 65 for suggested power down order
     *
     *
     *
     **/
    call I2S.enableI2S(FALSE);
    call I2S.enablePlayback(FALSE);
    
    return SUCCESS;
  }
  
  event void I2S.initI2SDone(){
    //host interface to codec is initialized.  now initialize the actual codec

    if(issuePowerOnSequence() == FAIL){
      trace(DBG_USR1,"WM8940.issuePowerOnSequence() failed\r\n");
    }
  }
  
  task void recordDone(){
    uint32_t *buffer;
    uint32_t numBytes;

    
    atomic{
      buffer = gRxBuffer;
      gRxBuffer = NULL;
    
      gRxBufferPos = 0;

      numBytes = gRxNumBytes;
      gRxNumBytes = 0;
    }
    invalidateDCache((uint8_t *)buffer, numBytes);

    signal Audio.audioRecordDone(buffer, numBytes/4);
    
  }
  

  async event uint8_t *BulkTxRx.BulkReceiveDone(uint8_t *RxBuffer, uint16_t NumBytes){
    
    //gRxBufferPos and gRxNumBytes protected by ARM ISR
    gRxBufferPos += NumBytes;
    
    if(gRxBufferPos >= gRxNumBytes){
	post recordDone();
	return NULL;
      }
    else{
      return (uint8_t *)gRxBuffer + gRxBufferPos;
    }
  }
  
  task void transmitDone(){
    //debugging task
    uint32_t pos;

    atomic{
      pos = gTxBufferPos;
    }
    
    trace(DBG_USR1,"transmitDone..pos = %d!\r\n", pos);
  }
  
  task void signalAudioReady(){
    atomic{
      gTxBuffer = NULL;
      gTxNumBytes = 0;
      gTxBufferPos = 0;
    }
    signal Audio.ready(SUCCESS);
  }
  

  task void playbackDone(){
    uint32_t *buffer;
    uint32_t numBytes;

    
    atomic{
      buffer = gTxBuffer;
      gTxBuffer = NULL;
    
      gTxBufferPos = 0;

      numBytes = gTxNumBytes;
      gTxNumBytes = 0;
    }
    
    signal Audio.audioPlayDone(buffer, numBytes/4);
    
  }
  
  
  async event uint8_t *BulkTxRx.BulkTransmitDone(uint8_t *TxBuffer, uint16_t NumBytes){
    //post transmitDone();
      
    gTxBufferPos += NumBytes;
    
    if(gInitPlay == TRUE){
      if(gTxBufferPos >= gTxNumBytes){
	post signalAudioReady();
	gInitPlay = FALSE;
	return NULL;
      }
      else{
	return ((uint8_t *)pcmdata) + gTxBufferPos;
      }
    }
    else{
      if(gTxBufferPos >= gTxNumBytes){
	post playbackDone();
	return NULL;
      }
      else{
	//call BulkTxRx.BulkTransmit((uint8_t *)(pcmdata+gTxBufferPos), ((pcmdatalen-gTxBufferPos) > 8188)? 8188: (pcmdatalen-gTxBufferPos));
	return (uint8_t *)gTxBuffer + gTxBufferPos;
      }
    }
  }
    
  async event BulkTxRxBuffer_t *BulkTxRx.BulkTxRxDone(BulkTxRxBuffer_t *TxRxBuffer, uint16_t NumBytes){
    
    return NULL;
  }

  
  
  
  
  task void unknownI2CSequence(){
    trace(DBG_USR1,"received runI2CBusSequenceDone for unknown I2C Sequence %d\r\n", gI2CState);
    return;
  }

  task void failedI2CSequence(){
    trace(DBG_USR1,"runI2CBusSequence failed for I2C Sequence %d\r\n", gI2CState);
    return;
  }

  task void IDLEI2CSequence(){
    trace(DBG_USR1,"received runI2CBusSequenceDone for IDLE I2C State\r\n");
    return;
  }

    
  event void I2CBusSequence.runI2CBusSequenceDone(i2c_op_t *pOpsExecuted, uint8_t numOpsExecuted, result_t success){
    if(success == SUCCESS){
      switch(gI2CState){
      case I2CState_IDLE:
	
	post  IDLEI2CSequence();
	break;
	
      case I2CState_PowerOn:
	post continuePowerOnSequence();
	break;

      case I2CState_PowerOff:
	break;

      default:
	post unknownI2CSequence();
      }
    }
    else{
      post unknownI2CSequence();
    }
    return;
  }

  command result_t Audio.mute(bool enable){

    return FAIL;
  }
  
  default event void Audio.muteDone(result_t success){
    
    return;
  }
  
  command result_t Audio.setVolume(int8_t volumeInDecibels){
    
    uint8_t value;
    
    if((volumeInDecibels > 0) || (volumeInDecibels < -127)){
      return FAIL;
    }
    
    value = ((volumeInDecibels + 127) * 2) + 1;
    
    return writeRegister(DACDIGITALVOLUME, DACDIGITALVOLUME_DACVOL(value));
  }
  
  default event void Audio.setVolumeDone(result_t success){
    
    return;
  }
  
  command result_t Audio.setSamplingRate(uint32_t Fs){
    
    return FAIL;
  }

  default event void Audio.setSamplingRateDone(result_t success){
    
    return;
  }

  command result_t Audio.audioPlay(uint32_t *buffer, uint32_t numSamples){
    uint32_t *pBuf;
    uint32_t bufpos;
    bool initPlay;
    
    atomic{
      initPlay = gInitPlay;
    }
    
    if(initPlay == TRUE){
      //gate the acceptance of a play command until we signal audio.ready();
      return FAIL;
    }
    
    atomic{
      pBuf = gTxBuffer;
      bufpos = gTxBufferPos;
    }
    
    if( (bufpos != 0) || (pBuf != NULL)){
      //gate acceptance due to ongoing play command
      return FAIL;
    }
    
    atomic{
      gTxBuffer = buffer;
      gTxBufferPos = 0;
      gTxNumBytes = numSamples * 4;
    }
    cleanDCache((uint8_t *)buffer, numSamples * 4);
    
    call BulkTxRx.BulkTransmit((uint8_t *)buffer, ((numSamples*4) > 8188)? 8188: (numSamples*4));
    
    return SUCCESS;
  }
  
  default event void Audio.audioPlayDone(uint32_t *buffer, uint32_t numSamples){
    
    return;
  }

  command result_t Audio.audioRecord(uint32_t *buffer, uint32_t numSamples){
    uint32_t *pBuf;
    uint32_t bufpos;
    bool initPlay;
    
    atomic{
      initPlay = gInitPlay;
    }
    
    if(initPlay == TRUE){
      //gate the acceptance of a record command until we signal audio.ready();
      return FAIL;
    }
    
    atomic{
      pBuf = gRxBuffer;
      bufpos = gRxBufferPos;
    }
    
    if( (bufpos != 0) || (pBuf != NULL)){
      //gate acceptance due to ongoing record command
      return FAIL;
    } 
    
    atomic{
      gRxBuffer = buffer;
      gRxBufferPos = 0;
      gRxNumBytes = numSamples * 4;
    }
    
    call BulkTxRx.BulkReceive((uint8_t *)buffer, ((numSamples*4) > 8188)? 8188: (numSamples*4));
    
    return SUCCESS;
  }
  
  default event void Audio.audioRecordDone(uint32_t *buffer, uint32_t numSamples){
    
    return;
  }

}
