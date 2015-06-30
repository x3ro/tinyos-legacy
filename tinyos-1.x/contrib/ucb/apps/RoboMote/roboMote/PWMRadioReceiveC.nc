// @author John Breneman <johnyb_4@berkeley.edu>
 
includes PWMMessage;
 
configuration PWMRadioReceiveC
{
}
 
implementation
{
  components Main, PWMRadioReceiveM, GenericComm, TelosPWMC, LedsC, TimerC;
 
  Main.StdControl -> GenericComm;
  Main.StdControl -> TimerC;
  Main.StdControl -> TelosPWMC;
  Main.StdControl -> PWMRadioReceiveM;

  PWMRadioReceiveM.Leds -> LedsC;
  PWMRadioReceiveM.Timer -> TimerC.Timer[unique("Timer")];
  PWMRadioReceiveM.TelosPWM -> TelosPWMC;
  PWMRadioReceiveM.ReceiveMsg -> GenericComm.ReceiveMsg[AM_PWMMSG];
}
