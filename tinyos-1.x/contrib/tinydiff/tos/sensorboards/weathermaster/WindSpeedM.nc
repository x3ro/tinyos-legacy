//Mohammad Rahimi
module WindSpeedM {
    provides {
        interface StdControl as WindSpeedControl;
        interface Dio as WindSpeed;
        interface Dio as WindGust;
    }
    uses {
        interface Leds;
    }
}

implementation {

#define INT_ENABLE()  sbi(EIMSK , 2)
#define INT_DISABLE() cbi(EIMSK , 2)

    uint16_t wind;
    uint16_t gust;
    uint8_t state;
    uint8_t edgeMode;

    command result_t WindSpeedControl.init() {
        INT_DISABLE();
        TOSH_MAKE_PW1_OUTPUT();
        TOSH_CLR_PW1_PIN();
        edgeMode=RisingEdge;
        wind=0;
        gust=0;
        state=0;
        return SUCCESS;
    }
    
    command result_t WindSpeedControl.start() {
        INT_ENABLE();
        TOSH_CLR_PW1_PIN();
        wind=0;
        gust=0;
        state=0;
        return SUCCESS;
    }
    
    command result_t WindSpeedControl.stop() {
        INT_DISABLE();
     return SUCCESS;
    }
    
  command result_t WindSpeed.setparam(uint8_t io,uint8_t modeToSet)
      {    
          //The available INT that is IN0-INT4 are not configurable
          //io is always input
          edgeMode=modeToSet;
          return SUCCESS;  
      }
  
  
  command result_t WindSpeed.high()
      {
          return SUCCESS;
      }
  
  command result_t WindSpeed.low()
      {
          return SUCCESS;
      }
  
  command result_t WindSpeed.reset()
      {
          return SUCCESS;
      }
  
  command result_t WindSpeed.setCount(uint16_t numberofcount)
      {
            return SUCCESS;
      }
  
  command result_t WindSpeed.getData()
      {             
          signal WindSpeed.dataReady(wind);
          wind=0;
          return SUCCESS;
      } 
  
  default event result_t WindSpeed.dataReady(uint16_t data) 
      {
           return SUCCESS;
      } 
  
  command result_t WindGust.setparam(uint8_t io,uint8_t modeToSet)
      {    
          //the parameter of gust is exactly as windspeed.
          return SUCCESS;  
      }

  command result_t WindGust.high()
      {
          return SUCCESS;
      }
  
  command result_t WindGust.low()
      {
          return SUCCESS;
      }
  
  command result_t WindGust.reset()
      {
          return SUCCESS;
      }
  
  command result_t WindGust.setCount(uint16_t numberofcount)
      {
            return SUCCESS;
      }
  
  command result_t WindGust.getData()
      {             
          signal WindGust.dataReady(gust);
          gust=0;
          return SUCCESS;
      } 
  
  default event result_t WindGust.dataReady(uint16_t data) 
      {
           return SUCCESS;
      } 
  



   TOSH_SIGNAL(SIG_INTERRUPT2)
       {                      
           INT_DISABLE();
           if(edgeMode==Edge) { wind++; gust++;}
           if(state==0){
               TOSH_CLR_PW1_PIN();
               state=1;
               if(edgeMode==RisingEdge) {wind++; gust++;}
           }
           else {
               TOSH_SET_PW1_PIN();
               state=0;
               if(edgeMode==FallingEdge) {wind++; gust++;}
           }

           //should get enabled
           INT_ENABLE();
           return;
       }   

   
}
