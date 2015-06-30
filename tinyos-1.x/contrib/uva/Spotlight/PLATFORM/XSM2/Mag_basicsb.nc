includes sensorboard;
configuration Mag 
{
  provides interface ADC as MagX;
  provides interface ADC as MagY;
  provides interface MagSetting;
  provides interface StdControl;
}
implementation
{
  components MagM;
#ifndef PLATFORM_PC
  components ADCC, I2CPotC;
#endif //PLATFORM_PC

  StdControl = MagM;
  MagSetting = MagM;
#ifndef PLATFORM_PC
  MagX = ADCC.ADC[TOS_ADC_MAG_X_PORT];
  MagY = ADCC.ADC[TOS_ADC_MAG_Y_PORT];
  MagM.ADCControl -> ADCC;
  MagM.PotControl -> I2CPotC;
  MagM.I2CPot -> I2CPotC;
#else //PLATFORM_PC
  MagX = MagM.MagX;
  MagY = MagM.MagY;
#endif //PLATFORM_PC
}

