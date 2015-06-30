

module BatVoltM
{
  provides interface BatVolt;
  provides interface ParamView;
  
  uses {
    interface Leds;
    interface MSP430Interrupt as ADCInterrupt;

  }
}
implementation 
{
  MSP430REG_NORACE(ADC12CTL0);
  MSP430REG_NORACE(ADC12CTL1);
  MSP430REG_NORACE(ADC12IFG);
  MSP430REG_NORACE(ADC12IE);
  MSP430REG_NORACE(ADC12IV);

  // this is where we set up the ADC for our battery
  command result_t BatVolt.setup() {
    // ADC control 0
    /* default 8 clock cycles per sample
     * no ref voltage, adc off,
     * time overflow interrupt enabled (if request start new sample beofre old finished)
     * mem overflow interrupt enabled  (if new sample written to adc mem before old one is read out)
     */    
    ADC12CTL0 = SHT0_1 | ADC12TOVIE | ADC12OVIE; 
    

  }
  async command result_t BatVolt.setPower(int state) {
  if (state){

  
  
  }
  // this is where we start a conversion
  command result_t BatVolt.startConversion() {
  ADC12CTL0 |= ADC12SC + ENC;
  }



    /*****************************************************************/

  const struct Param s_BV[] = {
    { "voltage",    PARAM_TYPE_UINT16, &gVoltage },
    { NULL, 0, NULL }
  };

  struct ParamList g_BVList  = { "batvolt",  &s_BV[0] };

  command result_t ParamView.init()
    {
      signal ParamView.add( &g_BVList );
      return SUCCESS;
    }

  TOSH_SIGNAL(ADC_VECTOR) {
    uint16_t iv = ADC12IV;
    switch(iv)
    {
      case  2: signal HPLADC12.memOverflow(); return;
      case  4: signal HPLADC12.timeOverflow(); return;
    }
    iv >>= 1;
    if (iv && iv < 19)
      signal HPLADC12.converted(iv-3);
  }

  
}

  
