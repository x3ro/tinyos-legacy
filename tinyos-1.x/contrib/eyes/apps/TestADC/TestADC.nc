includes InternalVoltage;
configuration TestADC {
}
implementation {
  components Main, TestADCM, MSP430ADC12C, HPLUSART0M, LedsC, TimerC, RefVoltC, ADCC,
             InternalTempC;

  Main.StdControl -> TestADCM;
  Main.StdControl -> MSP430ADC12C;
  Main.StdControl -> TimerC;
  Main.StdControl -> InternalTempC;
  
  TestADCM.ADC -> ADCC.ADC[TOS_ADC_INTERNAL_VOLTAGE_PORT];
  TestADCM.ADCControl -> ADCC.ADCControl;
  
  TestADCM.HALADCSingle -> MSP430ADC12C.MSP430ADC12Single[unique("MSP430ADC12")];
  TestADCM.HALADCMultiple -> MSP430ADC12C.MSP430ADC12Multiple[unique("MSP430ADC12")];
  TestADCM.ADCSingle -> InternalTempC;
  TestADCM.ADCMultiple -> InternalTempC;
    
  TestADCM.RefVolt -> RefVoltC;
  TestADCM.Leds -> LedsC;
}


