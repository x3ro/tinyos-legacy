/*
 *
 * Authors: Mike Grimmer
 * Date last modified:  2-19-04
 *
 */
includes sensorboard;
configuration ThermC
{
  provides interface ADC as ThermADC;
  provides interface StdControl;
  provides interface Therm;
}
implementation
{
  components ThermM, ADCC;

  StdControl = ThermM;
  ThermADC = ADCC.ADC[TOS_ADC_PHOTO_PORT];
  Therm = ThermM;
  ThermM.ADCControl -> ADCC;
}
