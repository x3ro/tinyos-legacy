configuration Flicker {
}
implementation {
  components Main, FlickerM, TimerC, LedsC;
  Main.StdControl -> TimerC;
  Main.StdControl -> FlickerM.StdControl;
  FlickerM.Timer -> TimerC.Timer[unique("Timer")];
  FlickerM.Timer2 -> TimerC.Timer[unique("Timer")];
  FlickerM.Timer3 -> TimerC.Timer[unique("Timer")];
  FlickerM.Timer4 -> TimerC.Timer[unique("Timer")];
  FlickerM.Leds -> LedsC;
}

