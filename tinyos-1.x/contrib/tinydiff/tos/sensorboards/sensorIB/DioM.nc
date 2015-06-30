//Mohammad Rahimi
module DioM {
    provides {
        interface StdControl;
        interface Dio[uint8_t channel];
    }
    uses {
        interface StdControl as I2CPacketControl;
        interface Leds;
        interface I2CPacket;
    }
}

implementation {

    uint8_t state;      //keep state of our State Machine 
    uint8_t ioDirection;    //keep track if a io is input or output, one bit for each channel
    uint8_t io;         //keep track of what is actually on the chip
    uint16_t mode;      //keep track if we seek falling or rising or both edges, two bit for each channel
    uint16_t count[8];   //we can count the number of pulses 
    uint16_t countThreshold[8];   //the number of pulses to generate event
    int8_t i2c_data;    //the data read from the chip
    uint8_t position;   //the param setting we get this is for channel number
    uint8_t value;      //the param setting we get this for what we want to write on specified position
    uint8_t modeSet;    //the param setting we get this for edge setting

#define MAX_mode 2    //0 for falling and 1 for rising and 2 for any edge

#define XOR(a,b)  ((a) & ~(b))|(~(a) & (b))

    //set of bitwise functions
#define  testbit(var, bit)   ((var) & (1 <<(bit)))      //if zero then return zero and if one not equal zero
#define  setbit(var, bit)    ((var) |= (1 << (bit)))
#define  clrbit(var, bit)    ((var) &= ~(1 << (bit)))

    //Interrupt definition
#define INT_ENABLE()  sbi(EIMSK , 4)
#define INT_DISABLE() cbi(EIMSK , 4)


    
    //set of two bitwise operation to check the mode
    //ait make it a little dirtier but saves 6 byte
#define  testmode(var,ch)   ((var) >> (ch<<1))  & 3  
    static inline void setmode(char localmode, char channel) {
        mode &= ~(3 << (channel<<1));
        mode |= (localmode << (channel<<1));
    }
    
    enum {GET_DATA, SET_OUTPUT, SET_ALL,GET_THEN_SET,SET_PARAM,IDLE};


    command result_t StdControl.init() {
        int i;
        ioDirection=0xc0;    //all input except D6 and D7 which are the two relay outputs
        io=0xff;         //set all inputs to high and relays OFF (we know chip boots to 0xff)
        mode=0x5555;     //we seek Falling edged by default
        state=IDLE;       
        cbi(DDRE,4);            //Making INT pin input
        cbi(EICRB,ISC40);       //Making INT sensitive to falling edge
        sbi(EICRB,ISC41);
        for(i=0;i<8;i++) countThreshold[i]=1;
        call I2CPacketControl.init();
        return SUCCESS;
    }
    
    command result_t StdControl.start() {
        INT_ENABLE();           //probably bus is stable and now we are ready 
        return SUCCESS;
    }
    
    command result_t StdControl.stop() {
     return SUCCESS;
    }
        
    command result_t Dio.setparam[uint8_t channel](uint8_t ioSet,uint8_t modeToSet)
        {    
            //we only set INT flag if we set any channel to input otherwise we do not touch it.
            if(ioSet != OutputChannel && ioSet != InputChannel) return FALSE;
            if(modeToSet > MAX_mode) return FALSE;
            if(state==IDLE) {
                position=channel;
                value=ioSet;
                modeSet=modeToSet;
                state = GET_THEN_SET;
                return call I2CPacket.readPacket(1,0x01);
            }
            return FAIL;
        }
  
  
    command result_t Dio.high[uint8_t channel]()
        {
            return SUCCESS;
        }
    
    command result_t Dio.low[uint8_t channel]()
        {
            return SUCCESS;
        }
    
    command result_t Dio.reset[uint8_t channel]()
      {
          return SUCCESS;
      }
  
  command result_t Dio.setCount[uint8_t channel](uint16_t numberofcount)
      {
          if(numberofcount>0xffff) return FALSE;
          countThreshold[channel]=(uint8_t) numberofcount;
          return SUCCESS;
      }
  
  command result_t Dio.getData[uint8_t channel]()
      {    
          signal Dio.dataReady[channel](count[channel]);
          //count[channel]=0;
          return SUCCESS;
      } 
  
  default event result_t Dio.dataReady[uint8_t channel](uint16_t data) 
      {
           return SUCCESS;
      } 

  
  event result_t I2CPacket.writePacketDone(bool result) {
      //if(state==SET_PARAM)       
      return SUCCESS;
  }
  
  task void read_result()
      {
       uint8_t ChangedState;
       int i;
       ChangedState = XOR(io,i2c_data);     //see those one who has changed               
       for(i=0;i<8;i++){
           if(testbit(ioDirection,i)==InputChannel){   //we only care about input channels
               if(testbit(ChangedState,i)) {       //find the channels which are realy changed
                   switch (testmode(mode,i)) {
                   case Edge:       
                       //                       if(count[i] == 0xffff) signal Dio.dataOverflow[i]();
                       count[i]++;
                       break;
                   case RisingEdge:
                       if(testbit(io,i)==0 && testbit(i2c_data,i)!=1) { 
                           //                           if (count[i] == 0xffff) signal Dio.dataOverflow[i]();
                           count[i]++; 
                       }
                       break;
                   case FallingEdge:
                       if(testbit(io,i)!=0 && testbit(i2c_data,i)==0) {
                           //                           if (count[i] == 0xffff) signal Dio.dataOverflow[i]();
                           count[i]++;
                       }
                       break;
                   default:
                   }
               }
           }               
       }
       io=i2c_data;
       return;
      }

   event result_t I2CPacket.readPacketDone(char length, char* data) {
       uint8_t sw_state;
       i2c_data=*data;       
       if (length != 1)
           {
               state = IDLE;
               return FALSE;
           }             
       
       if (state == GET_DATA)
           {
               state = IDLE;
               post read_result();
               return SUCCESS;
           }

       if (state == GET_THEN_SET)
           {               
               if (value== OutputChannel) {     //if ouput we start with setting it high,since it is week high it is safer
                   setbit(ioDirection,position); 
               }           
               else if (value== InputChannel) { //if input since we should set it high,consult the datasheet of pcf8574
                   clrbit(ioDirection,position); 
               }       
               else return FALSE;

               if(modeSet <= MAX_mode) setmode(modeSet,position);  //only meaningfull in input mode,Rising,Falling or any Edge

               setbit(state,position);
               state = SET_PARAM;
               call I2CPacket.writePacket(1, (char*)&sw_state, 0x01);
               return SUCCESS;
          } 
       return SUCCESS;
   }
   


    TOSH_SIGNAL(SIG_INTERRUPT4)
        {
            state=GET_DATA;
            call I2CPacket.readPacket(1,0x03);                    
            return;
        }   
}
