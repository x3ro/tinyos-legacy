//$Id: KrakenWatchdogC.nc,v 1.3 2005/08/08 22:47:47 jwhui Exp $

configuration KrakenWatchdogC
{
  provides interface StdControl;
}
implementation
{
  components MSP430TimerC;
  components KrakenWatchdogM;
  components TimerC;

  StdControl = KrakenWatchdogM;

  KrakenWatchdogM.MSP430TimerControl -> MSP430TimerC.ControlB6;
  KrakenWatchdogM.MSP430Compare -> MSP430TimerC.CompareB6;
  KrakenWatchdogM.Timer -> TimerC.Timer[unique("Timer")];
}

