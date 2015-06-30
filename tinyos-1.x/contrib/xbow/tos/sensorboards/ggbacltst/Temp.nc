// $Id: Temp.nc,v 1.1 2004/11/22 14:33:34 husq Exp $
includes sensorboard;

configuration Temp
{
  provides {
    interface StdControl;
    interface ADC;
  }
}
implementation
{
  components TempM;

  StdControl = TempM;
  ADC = TempM;
}

