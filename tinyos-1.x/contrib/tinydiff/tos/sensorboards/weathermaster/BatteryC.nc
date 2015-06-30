//Mohammad Rahimi
configuration BatteryC
{
  provides interface ADC as ExternalBatteryADC;
  provides interface StdControl;
}
implementation
{
  components BatteryM, ADCC;
  
  StdControl = BatteryM;
  ExternalBatteryADC = BatteryM.ExternalBatteryADC;
  BatteryM.InternalBatteryADC -> ADCC.ADC[TOS_ADC_VOLTAGE_PORT];

  BatteryM.ADCControl -> ADCC;
  
}
