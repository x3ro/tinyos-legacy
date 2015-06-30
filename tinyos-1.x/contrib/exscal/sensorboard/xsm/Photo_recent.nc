/*
 *
 * Authors:  Mike Grimmer
 * Date last modified:  2-19-04
 *
 */
includes sensorboard;
configuration Photo
{
  provides interface ADC as ExternalPhotoADC;
  provides interface StdControl as PhotoStdControl;
}
implementation
{
  components PhotoM, ADCC;

  PhotoStdControl = PhotoM.PhotoStdControl;
  ExternalPhotoADC = PhotoM.ExternalPhotoADC;
  PhotoM.InternalPhotoADC -> ADCC.ADC[TOS_ADC_PHOTO_PORT];
  PhotoM.ADCControl -> ADCC;
}
