includes sensorboard;
configuration Accel 
{
  provides interface ADC as AccelX;
  provides interface ADC as AccelY;
  provides interface StdControl;
}
implementation
{
  components AccelM, ADCC;

  StdControl = AccelM;
  AccelX = ADCC.ADC[TOS_ADC_ACCEL_X_PORT];
  AccelY = ADCC.ADC[TOS_ADC_ACCEL_Y_PORT];
  AccelM.ADCControl -> ADCC;
}
