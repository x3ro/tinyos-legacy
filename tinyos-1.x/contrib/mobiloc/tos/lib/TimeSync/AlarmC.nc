configuration AlarmC {
  provides interface Alarm[uint8_t id];
  provides interface StdControl;
  }
  
implementation {
  components AlarmM, TimerC, LedsC;
  AlarmM.Timer -> TimerC.Timer[unique("Timer")];
  AlarmM.TimerControl -> TimerC.StdControl;
  AlarmM.Leds -> LedsC;
  StdControl = AlarmM;
  Alarm = AlarmM;
  }

