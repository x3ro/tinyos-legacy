 //Authors:		Mohammad Rahimi mhr@cens.ucla.edu 

module I2CPacketMasterM
{
  provides {
    interface StdControl;
    interface I2CPacketMaster[uint8_t id];
  }
  uses {
    interface I2CMaster;
    interface StdControl as I2CStdControl;
    interface Leds;
  }
}

implementation
{

  /* state of the i2c request  */
  enum {IDLE=45,
        I2C_START_COMMAND=35,
        I2C_WRITE_ADDRESS=33,
        I2C_WRITE_DATA=22,
        I2C_WRITE_DONE=31,
        I2C_READ_ADDRESS=56,
        I2C_READ_DATA=41,
        I2C_READ_DONE=44,
        I2C_STOP_COMMAND=27};

  //Note: The only variable to be protected is state most notably at two places that the component 
  //can be entered at write and read
  norace char* data;    //bytes to write to the i2c bus 
  norace char length;   //length in bytes of the request 
  norace char index;    //current index of read/write byte 
  norace char state;    //current state of the i2c request 
  norace char address;  //destination address 

  //**************************************************************
  //*****************Initialization and Termination***************
  //************************************************************** 
command result_t StdControl.init() 
    {    
        call I2CStdControl.init();
        atomic {state = IDLE;}
        index = 0;
        return SUCCESS;
    }
 
command result_t StdControl.start() 
    {
        call I2CStdControl.start();
        return SUCCESS;
    }

command result_t StdControl.stop() {
     return SUCCESS;
  }

  //**************************************************************
  //***************Starting the Read/Write transaction************
  //************************************************************** 
 command result_t I2CPacketMaster.writePacket[uint8_t id](char in_length,char* in_data) 
     {       
         uint8_t status;
         atomic 
             {
                 status = FALSE; 
                 if (state == IDLE) status = TRUE;   
             }
         if(status == FALSE ) return FAIL;       
         address = id;
         data = in_data;
         index = 0;
         length = in_length;
         state = I2C_WRITE_ADDRESS;
         call I2CMaster.sendStart();
   
         return SUCCESS;
     }
 
 command result_t I2CPacketMaster.readPacket[uint8_t id](char in_length, char* in_data) {
     uint8_t status;
     atomic {
         status = FALSE;
         if (state == IDLE) status = TRUE;             
     }
     if(status == FALSE ) return FAIL;     
     address = id;
     data = in_data;
     index = 0;
     length = in_length;
     state = I2C_READ_ADDRESS;
     call I2CMaster.sendStart();
     return SUCCESS;
  }
  
 // the start symbol was sent    
 async event result_t I2CMaster.sendStartDone() 
     {
         if(state == I2C_WRITE_ADDRESS)
             {
                 state = I2C_WRITE_DATA;
                 call I2CMaster.write((address << 1) + 0);
             }
         else if (state == I2C_READ_ADDRESS)
             {
                 state = I2C_READ_DATA;
                 call I2CMaster.write((address << 1) + 1);
             }
         return SUCCESS;
     }
 
 // the stop symbol was sent, note that it is return in a task so we can very well return to upper layer
 async event result_t I2CMaster.sendEndDone() {
     if (state == I2C_WRITE_DONE) {   //successfull write
         state = IDLE;
         signal I2CPacketMaster.writePacketDone[address](SUCCESS);
     }
     else if (state == I2C_READ_DONE) {      //successfull read
         state = IDLE;
         signal I2CPacketMaster.readPacketDone[address](length,data);
     }
     return SUCCESS;    
 }

 //write fail task.
 task void write_fail()
     {
         signal I2CPacketMaster.writePacketDone[address](FAIL);
         atomic {state = IDLE;}
     }
 
 //notification of a byte successfully written to the bus following by write or read continuation or ending
 async event result_t I2CMaster.writeDone(bool result) {     
     if(result == FAIL) {
         post write_fail(); //we can not return in the context of interrupt
         return FAIL;
     }
     switch(state)
         {
         case I2C_WRITE_DATA:
             index++;
             if (index == length) state = I2C_STOP_COMMAND;                     
             return call I2CMaster.write(data[index-1]);
             break;
         case I2C_STOP_COMMAND:
             state = I2C_WRITE_DONE;
             return call I2CMaster.sendEnd();
             break;
         case I2C_READ_DATA:
             index++;
             if (index == length)  return call I2CMaster.read(0);
             else if (index < length) return call I2CMaster.read(1);             
             break;
         default:
             return FAIL;
         }
     return SUCCESS;
 }
 //notification of a byte successfully read from the bus following by more read continuation or ending
 async event result_t I2CMaster.readDone(char in_data) {
     data[index-1] = in_data;
     index++;
     if (index == length)
         call I2CMaster.read(0);
     else if (index < length)
         call I2CMaster.read(1);
     else if (index > length)
         {
             state = I2C_READ_DONE;
             call I2CMaster.sendEnd();
         }
     return SUCCESS;
 }
 
 default event result_t I2CPacketMaster.readPacketDone[uint8_t id](char in_length, char* in_data) 
     {
         return SUCCESS;
     }
 
 default event result_t I2CPacketMaster.writePacketDone[uint8_t id](bool result) 
     {
         return SUCCESS;
     }

}

