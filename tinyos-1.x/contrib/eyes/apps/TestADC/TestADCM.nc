/* 
 * Testing the ADC components.
 * All three LEDs should flash (takes some time).
 */
includes InternalVoltage;
includes MSP430Timer;

includes MSP430ADC12;
module TestADCM {
  provides interface StdControl;
  uses {
    interface MSP430ADC12Single as HALADCSingle;
    interface MSP430ADC12Multiple as HALADCMultiple;
    interface ADCSingle;
    interface ADCMultiple;
    interface Leds;
    interface RefVolt;
    interface ADC;
    interface ADCControl;
   }
}
implementation {
  #define BUFFERSIZE 800 
  uint16_t seqdata[BUFFERSIZE];
  norace int count;

  command result_t StdControl.init() {
    call Leds.init(); 
    call HALADCSingle.bind(ADC12_SETTINGS(INPUT_CHANNEL_A1, 
                                                 REFERENCE_VREFplus_AVss,
                                                 SAMPLE_HOLD_4_CYCLES,
                                                 SHT_SOURCE_ADC12OSC,
                                                 SHT_CLOCK_DIV_1,
                                                 SAMPCON_SOURCE_SMCLK,
                                                 SAMPCON_CLOCK_DIV_1,
                                                 REFVOLT_LEVEL_1_5));
    call HALADCMultiple.bind(ADC12_SETTINGS(INPUT_CHANNEL_A1, 
                                                 REFERENCE_VREFplus_AVss,
                                                 SAMPLE_HOLD_4_CYCLES,
                                                 SHT_SOURCE_ADC12OSC,
                                                 SHT_CLOCK_DIV_1,
                                                 SAMPCON_SOURCE_SMCLK,
                                                 SAMPCON_CLOCK_DIV_1,
                                                 REFVOLT_LEVEL_1_5));
    
    call ADCControl.init();
    call ADCControl.bindPort(TOS_ADC_INTERNAL_VOLTAGE_PORT, 
                             TOSH_ACTUAL_ADC_INTERNAL_VOLTAGE_PORT);
    return SUCCESS;  
  }
  
  command result_t StdControl.stop() { return SUCCESS; }
  
  command result_t StdControl.start() {
    call HALADCSingle.getData();
    return SUCCESS;
  }

  task void task1();
  task void task2();
  task void task3();
  task void task4();
  async event result_t HALADCSingle.dataReady(uint16_t data)
  {
    if (!count){
      call HALADCMultiple.reserve(seqdata, BUFFERSIZE, 50); 
      call HALADCMultiple.unreserve();
      call HALADCSingle.reserve();
      call HALADCMultiple.reserve(seqdata, BUFFERSIZE, 50); // FAIL
      call HALADCMultiple.getData(seqdata, BUFFERSIZE, 50); // FAIL
      call HALADCSingle.getDataRepeat(50); // FAIL
      call HALADCSingle.getData(); // SUCCESS!
    }
    if (count == 1)
      call HALADCSingle.getDataRepeat(0);
    if (count > 50){
      count = 0;
      post task1();
      return FAIL;
    }
    count++;
    return SUCCESS;
  }
  
  task void task1(){call HALADCMultiple.getData(seqdata, BUFFERSIZE, 12);}
  
  async event uint16_t* HALADCMultiple.dataReady(uint16_t *buf, uint16_t length)
  {
    if (!count){
      call HALADCMultiple.reserve(seqdata, BUFFERSIZE, 50);
      call HALADCSingle.getData(); // FAIL
      call HALADCMultiple.getDataRepeat(seqdata, 16, 50); // FAIL
      call HALADCMultiple.getData(0, 0, 0); // SUCCESS!
    }
    if (count == 1)
      call HALADCMultiple.getDataRepeat(seqdata, 16, 50);
    if (count > 50){
      count = 0;
      call Leds.yellowToggle();
      post task2();
      return (uint16_t*) 0;
    }
    count++;
    return buf;
  }

  task void task2(){call ADCSingle.getData();}
  
  async event result_t ADCSingle.dataReady(adcresult_t result, uint16_t data)
  {
    if (!count){
      call ADCSingle.reserve();
      call ADCMultiple.getData(seqdata, BUFFERSIZE); // FAIL
      call ADCSingle.getDataContinuous(); // FAIL
      call ADCSingle.getData();// SUCCESS!
    }
    if (count == 1)
      call ADCSingle.getDataContinuous();
    if (count > 50){
      count = 0;
      post task3();
      return FAIL;
    }
    count++;
    return SUCCESS;
  }

  task void task3(){call ADCMultiple.getData(seqdata, BUFFERSIZE);}

  async event uint16_t* ADCMultiple.dataReady(adcresult_t result, 
               uint16_t *buf, uint16_t length)
  {
    if (!count){
      call ADCMultiple.reserve(seqdata, BUFFERSIZE);
      call HALADCSingle.getData(); // FAIL
      call HALADCMultiple.getDataRepeat(seqdata, 16, 50); // FAIL
      call ADCMultiple.getData(seqdata, BUFFERSIZE); // SUCCESS!
    }
    if (count == 1)
      call ADCMultiple.getDataContinuous(seqdata, BUFFERSIZE);
    if (count > 50){
      count = 0;
      call Leds.redToggle();
      post task4();
      return (uint16_t*) 0;
    }
    count++;
    return buf;
  }

  task void task4(){call ADC.getData();}
  
  async event result_t ADC.dataReady(uint16_t data) {
    if (!count)
      call ADC.getData();
    if (count == 1)
      call ADC.getContinuousData();
    if (count > 50){
      count = 0;
      call Leds.greenToggle();
      return FAIL;
    }
    count++;
    return SUCCESS;
  }        
 
  event void RefVolt.isStable(RefVolt_t vref){
  }

  /*
  int count;
  async event uint16_t* HALADCMultiple.dataReady(uint16_t *buf, uint16_t length)
  {
    if (count){
      count = 0;
      TOSH_CLR_DEBUG_PIN1_PIN();
    } else {
      count = 1;
      TOSH_SET_DEBUG_PIN1_PIN();
    }
    call HALADCMultiple.getData(seqdata, BUFFERSIZE, 12);
    return 0;
  }
  */
 
}


