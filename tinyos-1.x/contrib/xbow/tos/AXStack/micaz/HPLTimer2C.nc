//$Id: HPLTimer2C.nc,v 1.1 2005/04/19 02:56:03 husq Exp $
// @author Cory Sharp <cssharp@eecs.berkeley.edu>
/***************************************************************************** 
$Log: HPLTimer2C.nc,v $
Revision 1.1  2005/04/19 02:56:03  husq
Import the micazack and CC2420RadioAck

Revision 1.2  2005/03/02 22:45:00  jprabhu
Added Log CVS-Tag

*****************************************************************************/

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

