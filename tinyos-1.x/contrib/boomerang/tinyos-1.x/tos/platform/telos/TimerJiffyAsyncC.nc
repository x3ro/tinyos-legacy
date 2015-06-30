//$Id: TimerJiffyAsyncC.nc,v 1.1.1.1 2007/11/05 19:10:38 jpolastre Exp $
// @author Cory Sharp <cssharp@eecs.berkeley.edu>

configuration TimerJiffyAsyncC
{
  provides interface StdControl;
  provides interface TimerJiffyAsync;
}
implementation
{
  components TimerJiffyAsyncM
	   , MSP430TimerC
	   ;

  StdControl = TimerJiffyAsyncM;
  TimerJiffyAsync = TimerJiffyAsyncM;

  TimerJiffyAsyncM.AlarmControl -> MSP430TimerC.ControlB4;
  TimerJiffyAsyncM.AlarmCompare -> MSP430TimerC.CompareB4;
}

