/*
  Basic Mulit-Master I2C bus driver done.  Only supports
  Master-Transmitter and Slave-Receiver for now.
*/

module HPLI2CM
{
  provides {
    interface StdControl;
    interface I2C;
  }
}
implementation
{
  // global variables
  char state;           	// maintain the state of the current process
  char local_data;		// data to be read/written
  result_t result;

  // define constants for state
  enum {USR = 1,  // Unaddressed slave receiver or idle 
        MT,	  // Master Transmitter
        MR,	  // Master Receiver
        ST,	  // Slave Transmitter
        SR};	  // Slave Receiver

  // define TWI device status codes. 
  enum {
    TWS_BUSERROR	         = 0x00,
    TWS_START		         = 0x08,
    TWS_RSTART		         = 0x10,

    TWS_MT_SLA_ACK	         = 0x18,
    TWS_MT_SLA_NACK	         = 0x20,
    TWS_MT_DATA_ACK	         = 0x28,
    TWS_MT_DATA_NACK	     = 0x30,

    TWS_M_ARB_LOST	         = 0x38,
    TWS_MR_SLA_ACK	         = 0x40,
    TWS_MR_SLA_NACK	         = 0x48,
    TWS_MR_DATA_ACK	         = 0x50,
    TWS_MR_DATA_NACK	     = 0x58,

    TWS_SR_SLA_ACK           = 0x60,
    TWS_M_ARB_LOST_SLA_W_ACK = 0x68,
    TWS_SR_GC_ACK            = 0x70,
    TWS_M_ARB_LOST_GC_ACK    = 0x78,
    TWS_SR_DATA_ACK          = 0x80,
    TWS_SR_DATA_NACK         = 0x88,
    TWS_SR_GCDATA_ACK        = 0x90,
    TWS_SR_GCDATA_NACK       = 0x98,
    TWS_SR_STOP              = 0xA0,

    TWS_ST_SLA_ACK           = 0xA8,
    TWS_M_ARB_LOST_SLA_R_ACK = 0xB0,
    TWS_ST_DATA_ACK          = 0xB8,
    TWS_ST_DATA_NACK         = 0xC0,
    TWS_ST_DONE_ACK          = 0xC8
  };



  command result_t StdControl.init()
    {
      // Enable TWI interface and interrupts.
      sbi(TWCR, TWEN);
      
      // Set bit rate.
      cbi(TWSR, TWPS0);
      cbi(TWSR, TWPS1);
      //outb(TWBR, 58);  //55.5kHz
      //outb(TWBR, 29);  // 100kHz
      outb(TWBR, 10);  // 209kHz

      // Set address based on TOS_LOCAL_ADDRESS
      outb(TWAR, ((TOS_LOCAL_ADDRESS & 0x7f) << 1) | 0x01);

      TWCR = (TWCR & 0x0F) | 1<<TWIE | 1<<TWEA;        

      sei();

      local_data = 0;
      return SUCCESS;
    }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  async command result_t I2C.sendStart() {
    // Check state of TWI to see if its ready. 
    // Check for illegal start or stop condition.
    if( ((TWSR & 0xF8) != 0xF8) || (TWSR == 0) ) {
      TWCR = (TWCR & 0x0F) | 1<<TWSTO | 1<<TWEA;
      return FAIL;
    }

    // Direct TWI to send start condition.
    TWCR = (TWCR & 0x0F) | 1<<TWSTA | 1<<TWINT | 1<<TWEA;

    return SUCCESS;
  }

  // Silly task to signal when a stop condition is completed.
  task void I2C_task() {
    loop_until_bit_is_clear(TWCR,TWSTO);
    signal I2C.sendEndDone();
  }

  async command result_t I2C.sendEnd() {
    // Direct TWI to send stop condition
    TWCR = (TWCR & 0x0F) | 1<<TWINT | 1<<TWSTO | 1<<TWEA;
    post I2C_task();
    //signal I2C.sendEndDone();
    
    return SUCCESS;
  }


  // For reads and writes, if the TWINT bit is clear, the TWI is
  // busy or the TWI improperly initialized
  async command result_t I2C.read(bool ack) {
    TWCR = (TWCR & 0x0F) | 1<<TWINT | 1<<TWEA;
    
    return SUCCESS;
  }


  async command result_t I2C.write(char data) {
    outb(TWDR,data);
    TWCR = (TWCR & 0x0F) | 1<<TWINT | 1<<TWEA;
    
    return SUCCESS;
  }


  TOSH_SIGNAL(SIG_2WIRE_SERIAL) {
    
    switch (inb(TWSR) & 0xF8) {
    case TWS_BUSERROR:
      TWCR = (TWCR & 0x0F) | 1<<TWSTO | 1<<TWINT | 1<<TWEA;
      break;
      
    case TWS_START: 
    case TWS_RSTART:
      signal I2C.sendStartDone();
      break;
      
    case TWS_MT_SLA_ACK:
    case TWS_MT_DATA_ACK:
      signal I2C.writeDone(TRUE);
      break;
      
    case TWS_MT_SLA_NACK:
    case TWS_MT_DATA_NACK:
      signal I2C.writeDone(FALSE);
      break;
      
    case TWS_MR_SLA_ACK:
      signal I2C.writeDone(TRUE);
      break;
      
    case TWS_MR_SLA_NACK:
      signal I2C.writeDone(FALSE);
      break;
      
    case TWS_MR_DATA_ACK:
      signal I2C.readDone(TRUE, inb(TWDR));
      break;
      
    case TWS_MR_DATA_NACK:
      signal I2C.readDone(FALSE, inb(TWDR));
      break;
      
    case TWS_SR_SLA_ACK:
    case TWS_M_ARB_LOST_SLA_W_ACK:
    case TWS_SR_GC_ACK:
    case TWS_M_ARB_LOST_GC_ACK:
      signal I2C.gotWriteRequest(TRUE);
      break;
      
    case TWS_SR_DATA_ACK:
    case TWS_SR_GCDATA_ACK:
      signal I2C.gotWriteData(TRUE, inb(TWDR));
      break;
      
    case TWS_SR_DATA_NACK:
    case TWS_SR_GCDATA_NACK:
      signal I2C.gotWriteData(FALSE, inb(TWDR));
      break;
      
    case TWS_SR_STOP:
      TWCR = (TWCR & 0x0F) | 1<<TWINT | 1<<TWEA;          
      signal I2C.gotStop();
      break;
      
    case TWS_ST_SLA_ACK:
    case TWS_M_ARB_LOST_SLA_R_ACK:
      signal I2C.gotReadRequest(TRUE);
      break;
      
    case TWS_ST_DATA_ACK:
      signal I2C.sentReadData(TRUE);
      break;
           
    case TWS_ST_DATA_NACK:
      signal I2C.sentReadData(FALSE);
      break;
      
    case TWS_ST_DONE_ACK:
      signal I2C.sentReadDone(TRUE);
      break;
      
      
    default:
      break;
    }
  } 
}
