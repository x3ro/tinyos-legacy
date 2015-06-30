/*
 *
 * Authors: Mike Grimmer
 * Date last modified:  2-19-04
 *
 */
includes sensorboard;
configuration PIRC
{
  provides interface ADC as PIRADC;
  provides interface StdControl;
  provides interface PIR;
}
implementation
{
  components PIRM, ADCC, I2CPotC;

  StdControl = PIRM;
  PIRADC = ADCC.ADC[TOS_ADC_PIR_PORT];
  PIR = PIRM;
  PIRM.ADCControl -> ADCC;
  PIRM.PotControl -> I2CPotC;
  PIRM.I2CPot -> I2CPotC;
}
