//Mohammad Rahimi
includes IB;
module SamplerM
{
    provides interface StdControl as SamplerControl;
    provides interface Sampler as BufferAnalog;
    provides interface Sampler as BufferRain;
    provides interface Sampler as BufferWind;
  uses {
      interface Leds;
      interface Timer as AnalogTimer;
      interface Timer as RainTimer;
      interface Timer as WindTimer;
      interface Timer as GustTimer;
      interface Timer as debouncer;
      interface StdControl as IBADCcontrol;
      interface ADC as ADC0;
      interface ADC as ADC1;
      interface ADC as ADC2;
      interface ADC as ADC3;
      interface ADC as ADC4;
      interface ADC as ADC5;
      interface ADC as ADC6;
      interface ADC as ADC7;
      interface Excite;
      interface StdControl as BatteryControl;
      interface ADC as BatteryADC;
      interface StdControl as DioControl;
      interface Dio as Rain1;
      interface Dio as Rain2;
      interface Dio as EventSwitch1;
      interface Dio as EventSwitch2;      
      interface Dio as AttentionSwitch;
      interface Dio as WindSpeed;
      interface Dio as WindGust;
      interface StdControl as WindSpeedControl;
  }
}
implementation
{


#define RAIN1_LOCK 0
#define RAIN2_LOCK 1
#define EVENT_SWITCH1_LOCK 2
#define EVENT_SWITCH2_LOCK 3
#define ATTENTION_SWITCH_LOCK 4

    /*since packat size is 29Byte and broadcast header is 6Byte*/
#define NO_EVENT 0
#define EVENT_SWITCH_ONE 0x1
#define EVENT_SWITCH_TWO 0x2
#define DEBOUNCE_LOCK_TIME 30000

#define BUFFER_ANALOG_SIZE 19
#define BUFFER_RAIN_SIZE 11
#define BUFFER_WIND_SIZE 19

#define ONLY_ONE_SAMPLE 0  //if zero normal otherwise it sends each 10sec not wait for packet completion

#define  is_bouncer_locked(var, bit)   ((var) & (1 <<(bit)))      //if zero then return zero and if one not equal zero
#define  lock_bouncer(var, bit)    ((var) |= (1 << (bit)))
#define  unlock_bouncer(var, bit)    ((var) &= ~(1 << (bit)))

    char analog_buf[BUFFER_ANALOG_SIZE],rain_buf[BUFFER_RAIN_SIZE],wind_buf[BUFFER_WIND_SIZE];

    uint8_t rainCounter;
    uint8_t analogCounter;
    uint16_t rainValue1;
    uint16_t rainValue2;
    uint16_t wind;
    uint16_t eventswitch1;
    uint16_t eventswitch2;
    uint8_t gust;
    uint8_t windCounter;
    uint8_t lock;            //to keep debouncer lock for all the necessary digital witches

    enum {
        RELEASED=1,
        LOCKED=0
    };

    enum {
        NO_ATTENTION = 0,
        ATTENTION = 0x55
    };

    enum {
        ANALOG_COUNT = 1,
        RAIN_COUNT = 2,
        WIND_TIME =22500, 
        GUST_TIME =2250, 
        ANALOG_TIME = 10000,
        RAIN_TIME = 30000
    };
        
    command result_t SamplerControl.init() {
        int i;
        call WindSpeedControl.init();
        call DioControl.init();
        call IBADCcontrol.init();
        call BatteryControl.init();
        rainCounter=0;
        analogCounter=0;
        lock=0;
        rainValue1=0;
        rainValue2=0;
        eventswitch1=0;
        eventswitch2=0;
        wind=0;
        windCounter=0;
        gust=0;
        for(i=0;i<BUFFER_ANALOG_SIZE;i++)analog_buf[i]=0;
        for(i=0;i<BUFFER_RAIN_SIZE;i++)rain_buf[i]=0;
        for(i=0;i<BUFFER_WIND_SIZE;i++)wind_buf[i]=0;
       return SUCCESS;
    }
    
    command result_t SamplerControl.start() {
        //setting wind speed channel parameter,
        call WindSpeed.setparam(InputChannel,RisingEdge);
        call WindSpeedControl.start();
        /*This part sets the digital channel to be input 
          sensitive to falling edge and report every single
          count,we can not as the driver to count beacause
          we need debounce*/
        call Rain1.setparam(InputChannel,FallingEdge);
        call Rain1.setCount(1);
        call Rain2.setparam(InputChannel,FallingEdge);
        call Rain2.setCount(1);
        call EventSwitch1.setparam(InputChannel,FallingEdge);
        call EventSwitch1.setCount(1);
        call EventSwitch2.setparam(InputChannel,FallingEdge);
        call EventSwitch2.setCount(1);
        call AttentionSwitch.setparam(InputChannel,FallingEdge);
        call AttentionSwitch.setCount(1);
        call Excite.setPowerMode(POWER_SAVING_MODE);
        call Excite.setCoversionSpeed(SLOW_COVERSION_MODE);
        call Excite.setAvergeMode(SIXTEEN_AVERAGE);
        /*This part start the timers to send data preiodically*/
        call AnalogTimer.start(TIMER_REPEAT, ANALOG_TIME);
        call RainTimer.start(TIMER_REPEAT, RAIN_TIME);
        call WindTimer.start(TIMER_REPEAT, WIND_TIME);
        call GustTimer.start(TIMER_REPEAT, GUST_TIME);
        return SUCCESS;
    }

    command result_t SamplerControl.stop() {
        call AnalogTimer.stop();
        call RainTimer.stop();
        call WindTimer.stop();
        call WindSpeedControl.stop();
        return SUCCESS;
    }

    event result_t AnalogTimer.fired() {
      analogCounter++;
        if(analogCounter==ANALOG_COUNT){
            analog_buf[0]=NO_ATTENTION;
            call Excite.setEx(ALL_EXCITATION);      
            call ADC0.getData();
            analogCounter=0;
            }
        return SUCCESS;
    }
    
  event result_t ADC0.dataReady(uint16_t data) {
      analog_buf[1]=data & 0xff;
      analog_buf[2] = (data >> 8) & 0xff;
      call Excite.setEx(ALL_EXCITATION);
      call ADC1.getData();
      return SUCCESS;
  }
  
  event result_t ADC1.dataReady(uint16_t data) {
      analog_buf[3]=data & 0xff;
      analog_buf[4] = (data >> 8) & 0xff;
      call Excite.setEx(ALL_EXCITATION);
      call ADC2.getData();
      return SUCCESS;
  }
  
  event result_t ADC2.dataReady(uint16_t data) {
      analog_buf[5]=data & 0xff;
      analog_buf[6] = (data >> 8) & 0xff;
      call Excite.setEx(ALL_EXCITATION);
      call ADC3.getData();      return SUCCESS;
  }

  event result_t ADC3.dataReady(uint16_t data) {
      analog_buf[7]=data & 0xff;
      analog_buf[8] = (data >> 8) & 0xff;
      call Excite.setEx(ALL_EXCITATION);
      call ADC4.getData();
      return SUCCESS;
  }

  event result_t ADC4.dataReady(uint16_t data) {
      analog_buf[9]=data & 0xff;
      analog_buf[10] = (data >> 8) & 0xff;
      call Excite.setEx(ALL_EXCITATION);
      call ADC5.getData();
      return SUCCESS;
  }

  event result_t ADC5.dataReady(uint16_t data) {
      analog_buf[11]=data & 0xff;
      analog_buf[12] = (data >> 8) & 0xff;
      call Excite.setEx(ALL_EXCITATION);
      call ADC6.getData();
      return SUCCESS;
  }
  
  event result_t ADC6.dataReady(uint16_t data) {
      analog_buf[13]=data & 0xff;
      analog_buf[14] = (data >> 8) & 0xff;
      call Excite.setEx(ALL_EXCITATION);
      call ADC7.getData();
      return SUCCESS;
  }

  event result_t ADC7.dataReady(uint16_t data) {
      analog_buf[15]=data & 0xff;
      analog_buf[16] = (data >> 8) & 0xff;      
      call BatteryADC.getData();
      //      signal BufferAnalog.dataReady(analog_buf,BUFFER_ANALOG_SIZE);
     //Sending data to Air
      return SUCCESS;
  }

  event result_t BatteryADC.dataReady(uint16_t data) {
      analog_buf[17]=data & 0xff;
      analog_buf[18] = (data >> 8) & 0xff;
      signal BufferAnalog.dataReady(analog_buf,BUFFER_ANALOG_SIZE);
      return SUCCESS;
  }

  command result_t BufferAnalog.done(char *Mymsg){
      return SUCCESS;
  }

  event result_t RainTimer.fired() {
      rainCounter++;
      if(rainCounter==RAIN_COUNT) {
      rain_buf[0]=NO_ATTENTION;
      rain_buf[1]=NO_EVENT;

      rain_buf[2]=rainValue1 & 0xff;
      rain_buf[3]=(rainValue1 >> 8) & 0xff;

      rain_buf[4]=rainValue2 & 0xff;
      rain_buf[5]=(rainValue2 >> 8) & 0xff;

      rain_buf[6]=eventswitch1 & 0xff;
      rain_buf[7]=(eventswitch1 >> 8) & 0xff;

      rain_buf[8]=eventswitch2 & 0xff;
      rain_buf[9]=(eventswitch2 >> 8) & 0xff;

      signal BufferRain.dataReady(rain_buf,BUFFER_RAIN_SIZE);
      rainCounter=0;
      }
    return SUCCESS;
  }

  command result_t BufferRain.done(char *Mymsg){
      return SUCCESS;
  }

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

  event result_t Rain1.dataReady(uint16_t data) {
      //if(is_bouncer_locked(lock,RAIN1_LOCK)==0) {
      rainValue1++;
      //signiture();
      //lock_bouncer(lock,RAIN1_LOCK);
      //call debouncer.start(TIMER_ONE_SHOT , DEBOUNCE_LOCK_TIME);
      //}
      return SUCCESS;
  }

  event result_t Rain2.dataReady(uint16_t data) {      
      //if(is_bouncer_locked(lock,RAIN2_LOCK)==0) {
      rainValue2++;
      //lock_bouncer(lock,RAIN2_LOCK);
      //call debouncer.start(TIMER_ONE_SHOT , DEBOUNCE_LOCK_TIME);
      //}
      return SUCCESS;
  }

static inline void  transmitevent(){
      rain_buf[2]=rainValue1 & 0xff;
      rain_buf[3]=(rainValue1 >> 8) & 0xff;
      rain_buf[4]=rainValue2 & 0xff;
      rain_buf[5]=(rainValue2 >> 8) & 0xff;
      rain_buf[6]=eventswitch1 & 0xff;
      rain_buf[7]=(eventswitch1 >> 8) & 0xff;
      rain_buf[8]=eventswitch2 & 0xff;
      rain_buf[9]=(eventswitch2 >> 8) & 0xff;
      signal BufferRain.dataReady(rain_buf,BUFFER_RAIN_SIZE);
      return;
  }

  event result_t EventSwitch1.dataReady(uint16_t data) {
      eventswitch1++;
      if(is_bouncer_locked(lock,EVENT_SWITCH1_LOCK)==0) {
      lock_bouncer(lock,EVENT_SWITCH1_LOCK);
      rain_buf[0]=NO_ATTENTION;
      rain_buf[1]=EVENT_SWITCH_ONE | rain_buf[1];
      transmitevent();
      call debouncer.start(TIMER_ONE_SHOT , DEBOUNCE_LOCK_TIME);
      }
      return SUCCESS;
  }

  event result_t EventSwitch2.dataReady(uint16_t data) {
      eventswitch2++;
      if(is_bouncer_locked(lock,EVENT_SWITCH2_LOCK)==0) {
      lock_bouncer(lock,EVENT_SWITCH2_LOCK);
      rain_buf[0]=NO_ATTENTION;
      rain_buf[1]=EVENT_SWITCH_TWO | rain_buf[1];
      transmitevent();
      call debouncer.start(TIMER_ONE_SHOT , DEBOUNCE_LOCK_TIME);
      }
      return SUCCESS;
  }

  event result_t WindTimer.fired() {
      call WindSpeed.getData();
      return SUCCESS;
          }
  event result_t GustTimer.fired() {
      call WindGust.getData();
      return SUCCESS;
          }
  
  event result_t WindGust.dataReady(uint16_t data) {
      uint8_t d;
      d = (uint8_t) data;
      if(d>gust) {
          gust=d;
          wind_buf[1]=gust;
      }
      return SUCCESS;
  }

  event result_t WindSpeed.dataReady(uint16_t data) {
      windCounter++;
      switch(windCounter){
      case 1:
          wind_buf[2]=data & 0xff;
          wind_buf[3]=(data >> 8) & 0xff;

          if(ONLY_ONE_SAMPLE){   //this is test
              wind_buf[0]=NO_ATTENTION;
              wind_buf[1]=gust;
              gust=0;
              windCounter=0;
              signal BufferWind.dataReady(wind_buf,BUFFER_WIND_SIZE);
          }

          break;
      case 2:
          wind_buf[4]=data & 0xff;
          wind_buf[5]=(data >> 8) & 0xff;
          break;
      case 3:
          wind_buf[6]=data & 0xff;
          wind_buf[7]=(data >> 8) & 0xff;
          break;
      case 4:
          wind_buf[8]=data & 0xff;
          wind_buf[9]=(data >> 8) & 0xff;
          break;
      case 5:
          wind_buf[10]=data & 0xff;
          wind_buf[11]=(data >> 8) & 0xff;
          break;
      case 6:
          wind_buf[12]=data & 0xff;
          wind_buf[13]=(data >> 8) & 0xff;
          break;
      case 7:
          wind_buf[14]=data & 0xff;
          wind_buf[15]=(data >> 8) & 0xff;
          break;
      case 8:
          wind_buf[16]=data & 0xff;
          wind_buf[17]=(data >> 8) & 0xff;
          wind_buf[0]=NO_ATTENTION;
          wind_buf[1]=gust;
          gust=0;
          windCounter=0;
          signal BufferWind.dataReady(wind_buf,BUFFER_WIND_SIZE);
          break;
      default:
      }
      return SUCCESS;
  }

  command result_t BufferWind.done(char *Mymsg){
      return SUCCESS;
  }


  event result_t AttentionSwitch.dataReady(uint16_t data) {
      //starting ADC chain with Attention flag
      analog_buf[0]=ATTENTION;
      call Excite.setEx(ALL_EXCITATION);      
      call ADC0.getData();
      //sending rain with attention flag
      rain_buf[0]=ATTENTION;
      rain_buf[1]=NO_EVENT;

      rain_buf[2]=rainValue1 & 0xff;
      rain_buf[3]=(rainValue1 >> 8) & 0xff;

      rain_buf[4]=rainValue2 & 0xff;
      rain_buf[5]=(rainValue2 >> 8) & 0xff;

      rain_buf[6]=eventswitch1 & 0xff;
      rain_buf[7]=(eventswitch1 >> 8) & 0xff;

      rain_buf[8]=eventswitch2 & 0xff;
      rain_buf[9]=(eventswitch2 >> 8) & 0xff;

      signal BufferRain.dataReady(rain_buf,BUFFER_RAIN_SIZE);
      //sending wind with attention flag here we only send the most recent buffer
      //once again with attention flag since we do not want to wait for the buffer
      //to be filled up once again but we want to be more interactive
      wind_buf[0]=ATTENTION;      
      signal BufferWind.dataReady(wind_buf,BUFFER_WIND_SIZE);
      return SUCCESS;
  }

  event result_t debouncer.fired() {
      lock=0;                      // release all bouncers lock 
      rain_buf[1]=NO_EVENT;
      return SUCCESS;
  }

}
