/** MULE's Photo driver
  */

/**
  * @author David Watson
  */

configuration Photo
{
  provides interface ADC as PhotoADC;
  provides interface StdControl;
}
implementation
{
  components MULEPhotoM;

  StdControl = MULEPhotoM;
  PhotoADC = MULEPhotoM.PhotoADC;
}
