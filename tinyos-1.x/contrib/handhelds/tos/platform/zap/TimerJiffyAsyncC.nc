//$Id: TimerJiffyAsyncC.nc,v 1.1 2005/07/29 18:29:30 adchristian Exp $
// @author Cory Sharp <cssharp@eecs.berkeley.edu>

configuration TimerJiffyAsyncC
{
  provides interface StdControl;
  provides interface TimerJiffyAsync;
}
implementation
{
  components TimerJiffyAsyncM
	   , C55xxTimerC
	   ;

  StdControl = TimerJiffyAsyncM;
  TimerJiffyAsync = TimerJiffyAsyncM;

  TimerJiffyAsyncM.Alarm -> C55xxTimerC.Alarm;
}

