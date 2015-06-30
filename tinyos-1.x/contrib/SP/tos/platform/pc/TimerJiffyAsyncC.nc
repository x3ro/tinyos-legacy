//$Id: TimerJiffyAsyncC.nc,v 1.1 2006/04/14 00:19:14 binetude Exp $
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

