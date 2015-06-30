/** MULE's Microphone driver
  */

/**
  * @author David Watson
  */

configuration MicC
{
  provides interface ADC as MicADC;
  provides interface StdControl;
  provides interface Mic;
  provides interface MicInterrupt;
}
implementation
{
  components MULEMicM;
  //components MicM, ADCC, I2CPotC;

  StdControl = MULEMicM;
  MicInterrupt = MULEMicM;
  //MicADC = ADCC.ADC[TOS_ADC_MIC_PORT];
  MicADC = MULEMicM.MicADC;
  Mic = MULEMicM.Mic;
}
