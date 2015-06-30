/*
 *
 * Authors: Mike Grimmer
 * Date last modified:  2-19-04
 *
 */
includes sensorboard;
configuration MicC
{
  provides interface ADC as MicADC;
  provides interface StdControl;
  provides interface Mic;
}
implementation
{
  components MicM, ADCC, I2CPotC;

  StdControl = MicM;
  MicADC = ADCC.ADC[TOS_ADC_MIC_PORT];
  Mic = MicM;
  MicM.ADCControl -> ADCC;
  MicM.PotControl -> I2CPotC;
  MicM.I2CPot -> I2CPotC;
}
