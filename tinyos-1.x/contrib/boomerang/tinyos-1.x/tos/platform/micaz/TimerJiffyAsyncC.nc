//$Id: TimerJiffyAsyncC.nc,v 1.1.1.1 2007/11/05 19:10:12 jpolastre Exp $
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

