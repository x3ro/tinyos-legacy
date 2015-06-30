//Mohammad Rahimi
module CounterM {
    provides {
        interface StdControl as CounterControl;
        interface Dio as Counter;
    }
    uses {
        interface Leds;
    }
}

implementation {

#define INT_ENABLE()  sbi(EIMSK , 5)
#define INT_DISABLE() cbi(EIMSK , 5)

    uint16_t count;
    uint8_t state;
    uint8_t edgeMode;

    command result_t CounterControl.init() {
        INT_DISABLE();
        TOSH_MAKE_PW1_OUTPUT();
        TOSH_CLR_PW1_PIN();
        edgeMode=RisingEdge;
        count=0;
        state=0;
        cbi(DDRE,5);            //Making INT pin input
        cbi(EICRB,ISC50);       //Making INT sensitive to falling edge
        sbi(EICRB,ISC51);

        return SUCCESS;
    }
    
    command result_t CounterControl.start() {
        INT_ENABLE();
        TOSH_CLR_PW1_PIN();
        count=0;
        state=0;
        return SUCCESS;
    }
    
    command result_t CounterControl.stop() {
        INT_DISABLE();
     return SUCCESS;
    }
    
  command result_t Counter.setparam(uint8_t io,uint8_t modeToSet)
      {    
          //The available INT that is IN0-INT4 are not configurable
          //io is always input
          edgeMode=modeToSet;
          return SUCCESS;  
      }
  
  
  command result_t Counter.high()
      {
          return SUCCESS;
      }
  
  command result_t Counter.low()
      {
          return SUCCESS;
      }
  
  command result_t Counter.reset()
      {
          return SUCCESS;
      }
  
  command result_t Counter.setCount(uint16_t numberofcount)
      {
            return SUCCESS;
      }
  
  command result_t Counter.getData()
      {             
          signal Counter.dataReady(count);
          count=0;
          return SUCCESS;
      } 
  
  default event result_t Counter.dataReady(uint16_t data) 
      {
           return SUCCESS;
      } 
  
   TOSH_SIGNAL(SIG_INTERRUPT5)
       {                      
           if(edgeMode==Edge) count++;
           if(state==0){
               TOSH_CLR_PW1_PIN();
               state=1;
               if(edgeMode==RisingEdge) count++;
           }
           else {
               TOSH_SET_PW1_PIN();
               state=0;
               if(edgeMode==FallingEdge) count++;
           }
           return;
       }   

   
}
