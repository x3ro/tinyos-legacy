//Mohammad Rahimi
module I2CADCM
{
  provides {
      interface StdControl as IBADCcontrol;
      interface IBADC[uint8_t port];
  }
  uses {
      interface Leds;
      interface StdControl as I2CPacketControl;
      interface I2CPacket;
  }
}
implementation
{

#define WRITE_FLAG 0x00
#define READ_FLAG 0x03
#define TESTMODE 0

  enum {
      IDLE=0, 
      ADC_START_COVERT=1, 
      ADC_COVERT_IN_PROGRESS=2,
      TURN_OFF_EXCITATION=3
  };

  enum {
      ADC_POWER_DOWN=0x00,
      ADC_REF_OFF_ADC_ON=0x04,
      ADC_REF_ON_ADC_ON=0x0c
  };


  char state;       /* current state of the i2c request */
  char flags;       /* flags set on the I2C packets */
  char excite[8];   /*the status of the ref power*/
  char ADCchannel;         /*keeps track of which channel is in progress*/
  uint16_t value;   /* value of the incoming ADC reading */  
  
#define FIVE_VOLT_ON() TOSH_CLR_PW4_PIN()
#define FIVE_VOLT_OFF() TOSH_SET_PW4_PIN()
#define THREE_VOLT_ON()  TOSH_CLR_PW2_PIN()
#define THREE_VOLT_OFF() TOSH_SET_PW2_PIN()
#define TURN_VOLTAGE_BUFFER_ON() TOSH_CLR_PW5_PIN()
#define TURN_VOLTAGE_BUFFER_OFF() TOSH_SET_PW5_PIN()
  
  /*It returns whatever supposed to write in ADC control register to turn Off or On the reference*/
  static inline uint8_t setEx(uint8_t excitation){
      switch (excitation) {
      case NO_EXCITATION:
          FIVE_VOLT_OFF();
          THREE_VOLT_OFF();
          return 0x04;
          break;
      case ADCREF:
          FIVE_VOLT_OFF();
          THREE_VOLT_OFF();
          return 0x0c;
          break;
      case THREE_VOLT:
          FIVE_VOLT_OFF();
          THREE_VOLT_ON();
          return 0x04;
          break;
      case FIVE_VOLT:
          FIVE_VOLT_ON();
          THREE_VOLT_OFF();
          return 0x04;
          break;
      case ALL_EXCITATION:	
          FIVE_VOLT_ON();
          THREE_VOLT_ON();
          return 0x0c;
          break;
      default:
          FIVE_VOLT_OFF();
          THREE_VOLT_OFF();
          return 0x04;
          break;
      }
  }
  
  
  command result_t IBADCcontrol.init() {
      char ADC=0x00;
      state = IDLE;
      call I2CPacketControl.init();
      TOSH_MAKE_PW4_OUTPUT();
      TOSH_MAKE_PW2_OUTPUT();
      TOSH_MAKE_PW5_OUTPUT();
      FIVE_VOLT_OFF();
      THREE_VOLT_OFF();
      TURN_VOLTAGE_BUFFER_ON();
      call I2CPacket.writePacket(1, (char*)(&ADC), WRITE_FLAG);
      return SUCCESS;
  }
  
  command result_t IBADCcontrol.start() {
      return SUCCESS;
  }
  command result_t IBADCcontrol.stop() {
      return SUCCESS;
  }


  default event result_t IBADC.dataReady[uint8_t port](uint16_t data) {
    return FAIL; // ensures ADC is disabled if no handler
  }

  command result_t IBADC.setExcite[uint8_t port](uint8_t excitation) {
      excite[port]=excitation;
      return SUCCESS;
  }
  
  /* get a single reading from port */
  command result_t IBADC.getData[uint8_t port]() {
      char ADC;
      if( port>7 ) return FALSE; 
      if (state == IDLE)
          {
              ADCchannel = port;
              state = ADC_START_COVERT;              
              ADC = (port << 4) & 0x70 + setEx(excite[port]);    /*the second part adds the ref status*/              
              /* tell the ADC to start converting */
              if ((call I2CPacket.writePacket(1, (char*)(&ADC), WRITE_FLAG)) == FAIL)
                  {
                      state = IDLE;
                      return FAIL;
                  }
              return SUCCESS;
          }
      return FAIL;
  }
  
  event result_t I2CPacket.readPacketDone(char length, char* data) {
      char ADC=0;
      if (state == ADC_COVERT_IN_PROGRESS)
          {
              if(TESTMODE) value=ADCchannel;
              else {
                  value = (data[0] << 8) & 0x0f00;
                  value += (data[1] & 0xff);
              }
              state = TURN_OFF_EXCITATION;
              FIVE_VOLT_OFF();        //now turn the exitations off
              THREE_VOLT_OFF();       
              call I2CPacket.writePacket(1, (char*)(&ADC), WRITE_FLAG);
          }
      return SUCCESS;
  }
  
  event result_t I2CPacket.writePacketDone(bool result) {
      if (state == ADC_START_COVERT)
          {
              state = ADC_COVERT_IN_PROGRESS;
              if ((call I2CPacket.readPacket(2, READ_FLAG)) == 0)
                  {                      
                      state = IDLE;                  /* reading from the bus failed */
                      signal IBADC.dataReady[ADCchannel](0xffff);      
                  }
              return SUCCESS;
          }
      else if ( state == TURN_OFF_EXCITATION) {
          state = IDLE;
          signal IBADC.dataReady[ADCchannel](value);  //send the data
      }
      return SUCCESS;
  } 
}
