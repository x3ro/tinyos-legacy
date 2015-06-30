/*
 *
 * Authors: Mike Grimmer
 * Date last modified:  2-19-04
 *
 */
includes sensorboard;
configuration MagC
{
  provides interface ADC as MagX;
  provides interface ADC as MagY;

  provides interface StdControl;
  provides interface MagSetting;
}
implementation
{
  components MagM, ADCC, I2CPotC;

  StdControl = MagM;
  MagX = ADCC.ADC[TOS_ADC_MAG_X_PORT];
  MagY = ADCC.ADC[TOS_ADC_MAG_Y_PORT];
  MagSetting = MagM;
  MagM.ADCControl -> ADCC;
  MagM.PotControl -> I2CPotC;
  MagM.I2CPot -> I2CPotC;
}
