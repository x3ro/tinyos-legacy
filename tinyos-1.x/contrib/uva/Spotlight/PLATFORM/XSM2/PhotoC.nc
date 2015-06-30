/*
 *
 * Authors: Mike Grimmer
 * Date last modified:  2-19-04
 *
 */
includes sensorboard;
configuration PhotoC
{
  provides interface ADC as PhotoADC;
  provides interface StdControl;
  provides interface Photo;
}
implementation
{
  components PhotoM, ADCC;

  StdControl = PhotoM;
  PhotoADC = ADCC.ADC[TOS_ADC_PHOTO_PORT];
  Photo = PhotoM;
  PhotoM.ADCControl -> ADCC;
}
