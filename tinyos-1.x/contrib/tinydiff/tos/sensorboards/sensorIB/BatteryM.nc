//Mohammad Rahimi


//Note:This components return the battery voltage * 100 so u should have a resolution of
//about 0.01V in the measurement.

//NOTE THAT JTAG SHOULD BE DISABLED FOR THIS COMPONENT TO WORK.
//This is beacause of a hardware problem.U should get the laest version of uisp(u can get it
//from tinyos website  and try to run

//fuse_dis--->"uisp -dprog=dapa --wr_fuse_h=0xD9"
//fuse_en --->"uisp -dprog=dapa --wr_fuse_h=0x19"


module BatteryM {
  provides interface StdControl;
  provides interface ADC as Battery;
  uses {
    interface ADCControl;
    interface ADC;
  }
}

implementation {


#define MAKE_BAT_MONITOR_OUTPUT() sbi(DDRA, 5)
#define MAKE_ADC_INPUT() cbi(DDRF, 5)
#define SET_BAT_MONITOR() sbi(PORTA, 5)
#define CLEAR_BAT_MONITOR() cbi(PORTA, 5)

void delay() {
    asm volatile  ("nop" ::);
    asm volatile  ("nop" ::);
    asm volatile  ("nop" ::);
    asm volatile  ("nop" ::);
}

    
    uint16_t voltage;

  command result_t StdControl.init() {
      MAKE_BAT_MONITOR_OUTPUT();
      MAKE_ADC_INPUT();
      call ADCControl.bindPort(BATTERY_PORT,BATTERY_PORT);
    return call ADCControl.init();
  }
  command result_t StdControl.start() {
      voltage =0;  
    return SUCCESS;
  }

  command result_t StdControl.stop() {
      return SUCCESS;
  }

  command result_t Battery.getData(){
      //MAKE_ADC_INPUT();
      SET_BAT_MONITOR();      
      delay();
      return call ADC.getData();
  }
    
  command result_t Battery.getContinuousData(){
      return call ADC.getContinuousData();     
  }
  
  default event result_t Battery.dataReady(uint16_t data) {
      return SUCCESS;
  }

  event result_t ADC.dataReady(uint16_t data){
      float x;
      CLEAR_BAT_MONITOR();
      x=(float)data; 
      x=  125440 / x ;
      voltage = (uint16_t ) x ;
      return signal Battery.dataReady(voltage);
   }

}
