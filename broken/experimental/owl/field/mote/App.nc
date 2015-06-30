includes Field;
configuration App { }
implementation 
{
  components Field, Main, TimerC, UARTComm as Comm, LedsC;

  Main.StdControl -> Field;
  Main.StdControl -> TimerC;
  Main.StdControl -> Comm;

  Field.WakeupMsg -> Comm.ReceiveMsg[AM_WAKEUPMSG];
  Field.FieldMsg -> Comm.ReceiveMsg[AM_FIELDMSG];
  Field.FieldReplyMsg -> Comm.SendMsg[AM_FIELDREPLYMSG];
  Field.Timer -> TimerC.Timer[unique("Timer")];
  Field.Leds -> LedsC;
}

