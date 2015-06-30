//$Id: TimerJiffyAsyncC.nc,v 1.2 2004/07/06 18:54:57 jdprabhu Exp $
// @author Cory Sharp <cssharp@eecs.berkeley.edu>

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

