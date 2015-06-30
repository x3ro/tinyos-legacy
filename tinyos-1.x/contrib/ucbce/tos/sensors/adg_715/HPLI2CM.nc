/* -*- Mode: C; c-basic-indent: 3; indent-tabs-mode: nil -*- */ 


//Mohammad Rahimi,Phil Buonadonna
module HPLI2CM {

  provides {
    interface StdControl;
    interface I2C;
  }
  uses interface Interrupt;
  uses interface Leds;
}

implementation {

  // global variables
  char state;           	// maintain the state of the current processx
  char global_data;
 
#define SET_START_TX() sbi(TWCR,TWSTA)
#define CLEAR_START_TX() cbi(TWCR,TWSTA)
#define SET_STOP_TX() sbi(TWCR,TWSTO)
#define CLEAR_STOP_TX() cbi(TWCR,TWSTO)
#define I2C_ENABLE() sbi(TWCR,TWEN)    
#define I2C_DISABLE() cbi(TWCR,TWEN)
#define INT_ENABLE() sbi(TWCR,TWIE)
#define INT_DISABLE() cbi(TWCR,TWIE)
#define INT_FLAG_ENABLE() sbi(TWCR,TWINT)
#define INT_FLAG_DISABLE() cbi(TWCR,TWINT)
#define ACK_ENABLE() sbi(TWCR,TWEA)
#define NACK_ENABLE() cbi(TWCR,TWEA)
#define RESET() outp(0x0,TWCR);
#define MAKE_CLOCK_OUTPUT() sbi(DDRD, 0);
#define CLOCK_HIGH() sbi(PORTD,0);  
#define CLCOK_LOW() sbi(PORTD,0);  
#define MAKE_DATA_INPUT() cbi(DDRD, 1);
#define DATA_PULL_UP() sbi(PORTD, 1);
#define DATA_NO_PULL_UP() cbi(PORTD, 1);

  // define constants for state
  enum {
      IDLE = 1,   // idle 
      MA_START,   // Initiation of the Master Bus
      MA_ADDRESS, // Master Transmitter,writing address
      MA_DATA,    // Master Transmitter,writing data
      MR_DATA,	     // Master Receiver
      ST,	      // Slave Transmitter
      SR          // Slave Receiver
  };	  
  
  
  // define TWI device status codes. 
  enum {
      TWS_BUSERROR	= 0x00,
      TWS_START		= 0x08,
      TWS_RSTART		= 0x10,
      TWS_MT_SLA_ACK	= 0x18,
      TWS_MT_SLA_NACK	= 0x20,
      TWS_MT_DATA_ACK	= 0x28,
      TWS_MT_DATA_NACK	= 0x30,
      TWS_M_ARB_LOST	= 0x38,
      TWS_MR_SLA_ACK	= 0x40,
      TWS_MR_SLA_NACK	= 0x48,
      TWS_MR_DATA_ACK	= 0x50,
      TWS_MR_DATA_NACK	= 0x58
  };
  
  static inline void setBitRate()   // See Note, Page 205 of ATmega128 docs
      { 
          cbi(TWSR, TWPS0);
          cbi(TWSR, TWPS1);
          outp(100,TWBR);           
      }
  
  static inline void init()
      {
          //sbi(PORTD, 0);	// i2c SCL,this activate pullup resistor
          //sbi(PORTD, 1);	// i2c SDA,this activate pullup resistor
          
          MAKE_CLOCK_OUTPUT();
          MAKE_DATA_INPUT();
          CLOCK_HIGH();
          DATA_PULL_UP();          
          RESET();          
          I2C_ENABLE();
          INT_ENABLE();                      //*********************
          ACK_ENABLE();
          call Interrupt.enable();           //*********************
          atomic {
            state = IDLE;
          }
      }
  
  static inline void reset()
      {
          RESET();
          //INT_DISABLE();
          //I2C_DISABLE();
          setBitRate();
          init();          
      }  
  
  // Silly task to signal when a stop condition is completed.
  task void I2C_task() {
      loop_until_bit_is_clear(TWCR,TWSTO);
      INT_FLAG_ENABLE();
      //INT_DISABLE();         //***************
      signal I2C.sendEndDone();
  }
  
  command result_t StdControl.init() {      
      setBitRate();
      init();
      return SUCCESS;
  }
  
  command result_t StdControl.start() {
      return SUCCESS;
  }
  
  command result_t StdControl.stop() {
      return SUCCESS;
  }
  
  command result_t I2C.sendStart() {

    atomic {
      state=MA_START;
    }

      signal I2C.sendStartDone();                    
      return SUCCESS;
  }
  
  
  void sendstart()
      {
          SET_START_TX();
          INT_FLAG_ENABLE();
      }
  void sendAddress()
      {
          outb(TWDR,global_data);
          //if(state==MA_ADDRESS) CLEAR_START_TX();
          CLEAR_START_TX();
          INT_FLAG_ENABLE();
      }
  command result_t I2C.sendEnd() {
      SET_STOP_TX();
      //INT_FLAG_ENABLE();          
      post I2C_task();
      return SUCCESS;
  }
  
  // For reads and writes, if the TWINT bit is clear, the TWI is
  // busy or the TWI improperly initialized
  command result_t I2C.read(bool ack) {
      //if (bit_is_clear(TWCR,TWINT)) return FAIL;
      //if(state==MR_DATA){
      //INT_ENABLE();             //******************
      if (ack)  ACK_ENABLE();
      else      NACK_ENABLE();
      INT_FLAG_ENABLE();
      //}
      return SUCCESS;
  }
  
  command result_t I2C.write(char data) {

    atomic {
      global_data=data;
    }

      //INT_ENABLE();            //******************

    atomic {
      if(state==MA_START) {
          state=MA_ADDRESS;
          sendstart();
      }
      if(state==MA_DATA)
          {
              //if(bit_is_clear(TWCR,TWINT)) return FAIL;     
              //call Leds.redToggle();
              outb(TWDR,data);
              INT_FLAG_ENABLE();
          }
    }
      return SUCCESS;
  }

default event result_t I2C.sendStartDone() {
    return SUCCESS;
}

default event result_t I2C.sendEndDone() {
    return SUCCESS;
}

default event result_t I2C.readDone(char data) {
    return SUCCESS;
}

default event result_t I2C.writeDone(bool success) {
    return SUCCESS;
}

TOSH_SIGNAL(SIG_2WIRE_SERIAL) {

    uint8_t i2cState;
    i2cState=inp(TWSR) & 0xF8;      

      INT_FLAG_DISABLE();
      switch (i2cState) {
      case TWS_BUSERROR:
          reset();
          //outb(TWCR,((1 << TWSTO) | (1 << TWINT)));  // Reset TWI
          break;          
      case TWS_START:                //08
      case TWS_RSTART:               //10
          sendAddress();              
          //signal I2C.sendStartDone();                    
          break;          
      case TWS_MT_SLA_ACK:           //18
          state=MA_DATA;
          signal I2C.writeDone(TRUE);
          break;          
      case TWS_MT_DATA_ACK:          //28
          state=MA_DATA;
          signal I2C.writeDone(TRUE);
          break;          
      case TWS_MT_SLA_NACK:          //20
          signal I2C.writeDone(FALSE);
          break;
      case TWS_MT_DATA_NACK:         //30
          signal I2C.writeDone(FALSE);
          break;      
      case TWS_MR_SLA_ACK:
          state=MA_DATA;
          signal I2C.writeDone(TRUE);
          break;          
      case TWS_MR_SLA_NACK:
            signal I2C.writeDone(FALSE);
          break;          
      case TWS_MR_DATA_ACK:
      case TWS_MR_DATA_NACK:
          state=MA_DATA;
          signal I2C.readDone(inb(TWDR));
          break;          
      default:
          //something wrong
          reset();
          break;
      }   
} 
}

