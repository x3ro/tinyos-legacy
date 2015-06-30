//Mohammad Rahimi
includes IB;

configuration BatteryC
{
  provides interface ADC as Battery;
  provides interface StdControl;
}
implementation
{
  components BatteryM, ADCC;
  
  StdControl = BatteryM;
  Battery = BatteryM.Battery;

  BatteryM.ADC -> ADCC.ADC[BATTERY_PORT];
  BatteryM.ADCControl -> ADCC;
  
}
