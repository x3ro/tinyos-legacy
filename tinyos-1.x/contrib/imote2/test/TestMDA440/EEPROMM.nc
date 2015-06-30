includes trace;

module EEPROMM{
  provides{
    interface StdControl;
    interface EEPROM;
  }
  uses {
    interface PXA27XInterrupt as I2CInterrupt;
  }
}
implementation {
  
  bool gotReset;
  norace  bool bWriteDone;;
  norace uint8_t UID[6];
  
#define EEPROM_ADDR 0x50  
#define ASSIGN_ADDR 0x64
 
  result_t readEEPROM(uint8_t address, uint8_t *value, uint8_t numBytes){
    //send the PMIC the address that we want to read
    if(numBytes > 0){
      IDBR = EEPROM_ADDR<<1; 
      ICR |= ICR_START;
      ICR |= ICR_TB;
      while(ICR & ICR_TB);
      
      //actually send the address terminated with a STOP
      IDBR = address;
      ICR &= ~ICR_START;
      ICR |= ICR_STOP;
      ICR |= ICR_TB;
      while(ICR & ICR_TB);
      ICR &= ~ICR_STOP;
      
      
      //actually request the read of the data
      IDBR = EEPROM_ADDR<<1 | 1; 
      ICR |= ICR_START;
      ICR |= ICR_TB;
      while(ICR & ICR_TB);
      ICR &= ~ICR_START;
      
      //using Page Read Mode
      while (numBytes > 1){
	ICR |= ICR_TB;
	while(ICR & ICR_TB);
	*value = IDBR;
	value++;
	numBytes--;
      }
      
      ICR |= ICR_STOP;
      ICR |= ICR_ACKNAK;
      ICR |= ICR_TB;
      while(ICR & ICR_TB);
      *value = IDBR;
      ICR &= ~ICR_STOP;
      ICR &= ~ICR_ACKNAK;
      
      return SUCCESS;
    }
    return FAIL;
  }
  
  result_t writeEEPROM(uint8_t address, uint8_t *value, uint8_t numBytes){
    // bool bLocalWriteDone;
    if(numBytes>0){
      
      
      IDBR = EEPROM_ADDR<<1;
      ICR |= ICR_START;
      ICR |= ICR_TB;
      while(ICR & ICR_TB);
      
      IDBR = address;
      ICR &= ~ICR_START;
      ICR |= ICR_TB;
      while(ICR & ICR_TB);
      
      while(numBytes>1){
	IDBR = *value;
	ICR |= ICR_TB;
	while(ICR & ICR_TB);
	numBytes--;
	value++;
      }
      IDBR = *value;
      ICR |= ICR_STOP;
      ICR |= ICR_TB;
      while(ICR & ICR_TB);
      ICR &= ~ICR_STOP;
      
      //now, we need a way to poll for a nack
#if 0      
      ICR |= (ICR_BEIE | ICR_ITEIE);
      IDBR = EEPROM_ADDR<<1;
      ICR |= ICR_START;
      ICR |= ICR_TB;
      
      atomic{
	bWriteDone = FALSE;
      }
      do{
	atomic{
	  bLocalWriteDone = bWriteDone;
	}
      }
      while(!bLocalWriteDone);
#else
      TOSH_uwait(5000);
#endif
      return SUCCESS;
    }
    return FAIL;
  }
  
  command result_t StdControl.init(){
    //enable the clock
    //while(!bPMICenabled);
    CKEN |= CKEN_CKEN14;
    //config the GPIO's

    GPIO_SET_ALT_FUNC(117,0x1,GPIO_IN);
    GPIO_SET_ALT_FUNC(118,0x1,GPIO_IN);
    //PICR = ICR_IUE | ICR_SCLE | ICR_BEIE | ICR_ITEIE ;
    ICR = ICR_IUE | ICR_SCLE;
    atomic{
      gotReset=FALSE;
    }    
    
    return call I2CInterrupt.allocate();
  }

  
  command result_t StdControl.start(){
    //init unit
    call I2CInterrupt.enable();

#if 0
    UID[0]= 0xDE;
    UID[1]= 0xAD;
    UID[2]= 0xBE;
    UID[3]= 0xEF;
    writeEEPROM(0,UID, 4);

    UID[0]= 0;
    UID[1]= 0;
    UID[2]= 0;
    UID[3]= 0;
    readEEPROM(0,UID, 4);
    trace(DBG_USR1,"Initialized EEPROM....UID = %#x %#x %#x %#x\r\n",UID[0],UID[1],UID[2],UID[3]);
#endif
    return SUCCESS;
  }
  
  
  command result_t StdControl.stop(){
    call I2CInterrupt.disable();
    CKEN &= ~CKEN_CKEN14;
    PICR = 0;
    
    return SUCCESS;
  }
  
  async event void I2CInterrupt.fired(){
    uint32_t status, update=0;
    //currently, we use this to enable ACK polling
    status = ISR;
    
    if(status & ISR_ITE){
      update |= ISR_ITE;
      trace(DBG_USR1,"finished with write %#x\r\n",status);
      ICR &= ~(ICR_BEIE | ICR_ITEIE);
      
      //set the address pointer back to 0
      IDBR = 0;
      ICR &= ~ICR_START;
      ICR |= ICR_STOP;
      ICR |= ICR_TB;
      while(ICR & ICR_TB);
      ICR &= ~ICR_STOP;
      
      atomic{
	bWriteDone = TRUE;
      }
    }
    if(status & ISR_BED){
      update |= ISR_BED;
      trace(DBG_USR1,"bus error %#x\r\n",status);
    }
    PISR = update;
  }
  
  
  command result_t EEPROM.getUID(uint8_t val[6]){
    
  }

  command result_t EEPROM.write(uint8_t address, uint8_t *data, uint8_t numBytes){
    return writeEEPROM(address, data, numBytes);
  }
  
  command result_t EEPROM.read(uint8_t address, uint8_t *data, uint8_t numBytes){
    return readEEPROM(address, data, numBytes);
  }
  
}


