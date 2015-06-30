// $Id: Accel.nc,v 1.1 2004/11/22 14:33:34 husq Exp $
includes sensorboard;

configuration Accel
{
  provides {
    interface StdControl;
    interface mADC;
  }
}
implementation
{
  components AccelM;

  StdControl = AccelM;
  mADC = AccelM;
}

