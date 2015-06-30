//$Id: TimerJiffyAsyncC.nc,v 1.2 2005/05/16 07:00:51 overbored Exp $
// @author Cory Sharp, Yang Zhang

configuration TimerJiffyAsyncC
{
  provides interface StdControl;
  provides interface TimerJiffyAsync;
}
implementation
{
  components TimerJiffyAsyncM
	   //, TimerC
	   ;

  StdControl = TimerJiffyAsyncM;
//  StdControl = TimerC;

  TimerJiffyAsync = TimerJiffyAsyncM;

  //TimerJiffyAsyncM.Timer -> TimerC.Timer[unique("Timer")];
}

