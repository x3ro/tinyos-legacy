/*
 *
 * Authors:  Mike Grimmer
 * Date last modified:  6/25/02
 *
 */

includes sensorboard;
configuration Photo
{
  provides interface ADC as PhotoADC;
  provides interface StdControl;
}
implementation
{
  components PhotoTemp;

  StdControl = Photo.PhotoStdControl;
  PhotoADC = Photo.ExternalPhotoADC;
}
