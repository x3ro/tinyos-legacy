/*
 *
 * Authors: Mike Grimmer
 * Date last modified:  2-19-04
 *
 */
includes sensorboard;
configuration Mag
{
  provides interface ADC as MagX;
  provides interface ADC as MagY;

  provides interface StdControl;
  provides interface XSMMagSetting;
}
implementation
{
  components MagM, ADCC, I2CPotC;

  StdControl = MagM;
  XSMMagSetting = MagM;

  MagX = ADCC.ADC[TOS_ADC_MAG_X_PORT];
  MagY = ADCC.ADC[TOS_ADC_MAG_Y_PORT];
  MagM.ADCControl -> ADCC;
  MagM.PotControl -> I2CPotC;
  MagM.I2CPot -> I2CPotC;
}
