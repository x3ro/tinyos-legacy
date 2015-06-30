
configuration BlinkC
{
  provides interface StdControl;
}
implementation
{
  components BlinkM, TimerC, LedsC;

  StdControl = BlinkM;

  BlinkM.Timer -> TimerC.Timer[unique("Timer")];
  BlinkM.Leds -> LedsC;
}

