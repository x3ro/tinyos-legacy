//$Id: TimerJiffyAsyncC.nc,v 1.2 2004/06/08 22:41:40 jdprabhu Exp $
// @author Cory Sharp <cssharp@eecs.berkeley.edu>

configuration TimerJiffyAsyncC
{
  provides interface StdControl;
  provides interface TimerJiffyAsync;
}
implementation
{
  components TimerJiffyAsyncM, HPLTimer2 as CPUClockTimer;

  StdControl = TimerJiffyAsyncM;
  TimerJiffyAsync = TimerJiffyAsyncM;
  TimerJiffyAsyncM.Timer -> CPUClockTimer;

}

