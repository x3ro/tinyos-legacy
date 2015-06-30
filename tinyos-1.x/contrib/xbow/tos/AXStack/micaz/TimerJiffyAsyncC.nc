//$Id: TimerJiffyAsyncC.nc,v 1.1 2005/04/19 02:56:03 husq Exp $
// @author Cory Sharp <cssharp@eecs.berkeley.edu>

/***************************************************************************** 
$Log: TimerJiffyAsyncC.nc,v $
Revision 1.1  2005/04/19 02:56:03  husq
Import the micazack and CC2420RadioAck

Revision 1.2  2005/03/02 22:45:01  jprabhu
Added Log CVS-Tag

*****************************************************************************/
configuration TimerJiffyAsyncC
{
  provides interface StdControl;
  provides interface TimerJiffyAsync;
}
implementation
{
  components TimerJiffyAsyncM, HPLTimer2C as CPUClockTimer;

  StdControl = TimerJiffyAsyncM;
  TimerJiffyAsync = TimerJiffyAsyncM;
  TimerJiffyAsyncM.Timer -> CPUClockTimer;

}

