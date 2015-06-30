/*
 *
 * Systemic Realtime Design, LLC.
 * http://www.sysrtime.com
 *
 * Authors:  Qingwei Ma
 *           Michael Li
 *
 * Date last modified:  9/30/04
 *
 */


configuration SGDriver
{
  provides interface ADC as SGData;
  provides interface StdControl;
}
implementation
{
  components SGDriverM, ADCC;

  StdControl = SGDriverM;
  SGData = ADCC.ADC[2];
  SGDriverM.ADCControl -> ADCC;
}
