configuration AlarmC {
  provides interface Alarm[uint8_t id];
  provides interface StdControl;
  }
  
implementation {
  components AlarmM, TimerC;
  AlarmM.Timer -> TimerC.Timer[unique("Timer")];
  AlarmM.TimerControl -> TimerC.StdControl;

  StdControl = AlarmM;
  Alarm = AlarmM;
  }

