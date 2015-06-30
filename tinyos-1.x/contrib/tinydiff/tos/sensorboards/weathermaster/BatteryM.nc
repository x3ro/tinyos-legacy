module BatteryM {
  provides interface StdControl;
  provides interface ADC as ExternalBatteryADC;
  uses {
    interface ADCControl;
    interface ADC as InternalBatteryADC;
  }
}

implementation {


  command result_t StdControl.init() {
    call ADCControl.bindPort(TOS_ADC_VOLTAGE_PORT, TOSH_ACTUAL_VOLTAGE_PORT);
    return call ADCControl.init();
  }
  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
      return SUCCESS;
  }

  command result_t ExternalBatteryADC.getData(){
      return call InternalBatteryADC.getData();
  }
    
  command result_t ExternalBatteryADC.getContinuousData(){
      return call InternalBatteryADC.getContinuousData();     
  }
  
  default event result_t ExternalBatteryADC.dataReady(uint16_t data) {
      return SUCCESS;
  }

  event result_t InternalBatteryADC.dataReady(uint16_t data){
      return signal ExternalBatteryADC.dataReady(data);
   }

}
