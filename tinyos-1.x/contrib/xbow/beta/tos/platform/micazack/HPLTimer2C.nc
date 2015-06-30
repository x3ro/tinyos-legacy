//$Id: HPLTimer2C.nc,v 1.1 2004/08/04 15:50:42 jdprabhu Exp $
// @author Cory Sharp <cssharp@eecs.berkeley.edu>

configuration HPLTimer2C
{
  provides interface StdControl;
  provides interface Clock;
}
implementation
{
  components HPLTimer2,LedsC;

  StdControl = HPLTimer2;
  Clock = HPLTimer2;
  HPLTimer2.Leds -> LedsC;

}

