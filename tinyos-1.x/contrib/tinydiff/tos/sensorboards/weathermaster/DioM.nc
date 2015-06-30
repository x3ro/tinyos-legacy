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
        interface Timer as timeOut;
    }
}

implementation {

    uint8_t iostate;    //keep track if a io is input or output, one bit for each channel
    uint8_t state;      //keep track of what is actually on the chip
    uint16_t mode;      //keep track if we seek falling or rising or both edges, two bit for each channel
    uint8_t count[8];   //we can count the number of pulses 
    uint8_t countThreshold[8];   //the number of pulses to generate event
    uint8_t timeout;    //to keep the fact that timeout timer has started
    int8_t i2c_data;
    
    enum {
        TIME_OUT=1,
        NO_TIME_OUT=2
    };

#define TIME_OUT 50
#define MAX_mode 2    //0 for falling and 1 for rising and 2 for any edge

#define XOR(a,b)  ((a) & ~(b))|(~(a) & (b))

    //set of bitwise functions
#define  testbit(var, bit)   ((var) & (1 <<(bit)))      //if zero then return zero and if one not equal zero
#define  setbit(var, bit)    ((var) |= (1 << (bit)))
#define  clrbit(var, bit)    ((var) &= ~(1 << (bit)))

    //Interrupt definition
#define INT_ENABLE()  sbi(EIMSK , 0)
#define INT_DISABLE() cbi(EIMSK , 0)


    
    //set of two bitwise operation to check the mode
    //ait make it a little dirtier but saves 6 byte
#define  testmode(var,ch)   ((var) >> (ch<<1))  & 3  
    static inline void setmode(char localmode, char channel) {
        mode &= ~(3 << (channel<<1));
        mode |= (localmode << (channel<<1));
    }
    

    //a flag to determine when we should enable the INT
    //we always disable INT when we write to the chip and
    //we should keep track of what we are supposed to do in
    // the call I2C call back
    enum {
        INPUT_INT_NOT_READY=0,
        INPUT_INT_READY=1
    }interruptState;   

    enum
        {
            RETURN_TO_READ_AFTER_WRITING =0 ,       //if we come from consistancy check
            RETURN_TO_READ_AFTER_INT =1           //if we come from channel INT
        }readingState;


    //to be removed
    /*
    static inline void delay(){
        int i;
        for(i=0;i<100;i++) asm volatile("nop");
    }

    static inline void signiture(){
        TOSH_MAKE_PW1_OUTPUT();  
        TOSH_SET_PW1_PIN();
        delay();
        TOSH_CLR_PW1_PIN();                                                        
        return;
    }
    */

    command result_t StdControl.init() {
        int i;
        INT_DISABLE();
        interruptState=INPUT_INT_NOT_READY;   //we do not expect INT service routine until Dio parameter is beinf set
        iostate=0xff;    //all input
        state=0xff;      //set all inputs to high
        mode=0x0000;     //mode is 00 that means we seek Rising edged by default
        for(i=0;i<8;i++) countThreshold[i]=1;
        call I2CPacketControl.init();
        call I2CPacket.writePacket(1, (char*)(&state), 0x01); 
        return SUCCESS;
    }
    
    command result_t StdControl.start() {
        return SUCCESS;
    }
    
    command result_t StdControl.stop() {
     return SUCCESS;
    }
    
    
  command result_t Dio.setparam[uint8_t channel](uint8_t io,uint8_t modeToSet)
      {    
          //we only set INT flag if we set any channel to input otherwise we do not touch it.
          INT_DISABLE();
          if (io== OutputChannel) {     //if ouput we start with setting it high,since it is week high it is safer
              setbit (iostate,channel); 
              setbit (state,channel);
              if(iostate=0x00) interruptState=INPUT_INT_NOT_READY;   //all are now output and no input channel  so no int should be active
          }          
          else if (io== InputChannel) { //if input since we should set it high,consult the datasheet of pcf8574
              clrbit(iostate,channel); 
              setbit (state,channel);
              interruptState=INPUT_INT_READY;
        }       
          else return FALSE;
          if(modeToSet <= MAX_mode) setmode(modeToSet,channel);  //only meaningfull in input mode,Rising,Falling or any Edge
          call I2CPacket.writePacket(1, (char*)(&state), 0x01); 
          return SUCCESS;
      }
  
  
  command result_t Dio.high[uint8_t channel]()
      {
          INT_DISABLE();  
          if((testbit(iostate,channel) == OutputChannel)) setbit(state,channel);
          call I2CPacket.writePacket(1, (char*)(&state), 0x01); 
          return SUCCESS;
      }
  
  command result_t Dio.low[uint8_t channel]()
      {
          INT_DISABLE();
          if((testbit(iostate,channel) == OutputChannel)) clrbit(state,channel);
          call I2CPacket.writePacket(1, (char*)(&state), 0x01); 
          return SUCCESS;
      }
  
  command result_t Dio.reset[uint8_t channel]()
      {
          return SUCCESS;
      }
  
  command result_t Dio.setCount[uint8_t channel](uint16_t numberofcount)
      {
          if(numberofcount>255) return FALSE;
          countThreshold[channel]=(uint8_t) numberofcount;
          return SUCCESS;
      }
  
  command result_t Dio.getData[uint8_t channel]()
      {             
          signal Dio.dataReady[channel](count[channel]);
          count[channel]=0;
          return SUCCESS;
      } 
  
  default event result_t Dio.dataReady[uint8_t channel](uint16_t data) 
      {
           return SUCCESS;
      } 
  
  event result_t I2CPacket.writePacketDone(bool result) {
      if(interruptState==INPUT_INT_READY) INT_ENABLE();
      call I2CPacket.readPacket(1,0x02);    //we again read to check consistancy      
      readingState=RETURN_TO_READ_AFTER_WRITING;       //if we come from consistancy check
      INT_ENABLE();
      return SUCCESS;
  }
  
  task void read_result()
      {
       uint8_t ChangedState;
       int i;
       timeout=NO_TIME_OUT;
       call timeOut.stop();
       //call Leds.greenToggle();
       if(readingState=RETURN_TO_READ_AFTER_WRITING)  
           {
               state=i2c_data;         //This is done for consistancy.when we set a channel to input
                                      //we do not know it initial state
               return;
           }
       else if(readingState=RETURN_TO_READ_AFTER_INT)
           {                              
               ChangedState = XOR(state,i2c_data);     //see those one who has changed               
               for(i=0;i<8;i++){
                   if(testbit(iostate,i)==InputChannel){   //we only care about input channels
                       if(testbit(ChangedState,i)) {       //find the channels which are realy changed
                           switch (testmode(mode,i)) {
                               //switch (mode[i]) {
                           case Edge:       
                               count[i]++;
                               break;
                           case RisingEdge:
                               if(testbit(state,i)==0 && testbit(i2c_data,i)!=1) { 
                                   count[i]++; 
                               }
                               break;
                           case FallingEdge:
                               if(testbit(state,i)!=0 && testbit(i2c_data,i)==0) {
                                   count[i]++;
                               }
                               break;
                           default:
                           }
                       }
                       if (count[i] >= countThreshold[i]) {
                           count[i]=0;
                           //INT_ENABLE();  //added later for maximum safety of not dead lock by leavinf INT disabled
                           signal Dio.dataReady[i](count[i]);
                       }
                   }               
               }
               state=i2c_data;        //update state to what is actualy read now
               INT_ENABLE();
               return;
           }
       return;
      }

   event result_t I2CPacket.readPacketDone(char length, char* data) {
       if(length != 1) return FALSE;
       i2c_data=*data;
       post read_result();
       return SUCCESS;
   }
   
    event result_t timeOut.fired() {
        //call Leds.yellowToggle();
        if(timeout==TIME_OUT){
            //call Leds.redToggle();
            call I2CPacket.readPacket(1,0x03);         
            call timeOut.start(TIMER_ONE_SHOT , TIME_OUT);
        }
        else{ 
            timeout=NO_TIME_OUT;
        }
        return SUCCESS;
    }

    /*    
  task void read()
       {
           //call Leds.greenToggle();
           //timeout=TIME_OUT;
           readingState=RETURN_TO_READ_AFTER_INT;       //if we come from consistancy check
           call I2CPacket.readPacket(1,0x03);                    
           //call timeOut.start(TIMER_ONE_SHOT , TIME_OUT);
           return;
       }
    */

  TOSH_SIGNAL(SIG_INTERRUPT0)
       {
           INT_DISABLE();           
           //call Leds.redToggle();
           timeout=TIME_OUT;
           readingState=RETURN_TO_READ_AFTER_INT;       //if we come from consistancy check
           //call I2CPacket.readPacket(1,0x02);                    
           call I2CPacket.readPacket(1,0x03);                    
           call timeOut.start(TIMER_ONE_SHOT , TIME_OUT);          
           //post read();
           return;
       }   
}
