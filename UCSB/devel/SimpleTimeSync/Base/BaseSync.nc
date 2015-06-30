includes TimeSync;

configuration BaseSync {
}
implementation {
  components Main, BaseSyncM, RadioCRCPacket as Comm;
  components LedsC, TimerC, SimpleTime; 
  
  Main.StdControl -> BaseSyncM;
  BaseSyncM.Timer -> TimerC.Timer[unique("Timer")];
  BaseSyncM.RadioControl -> Comm;
  BaseSyncM.RadioSend -> Comm;
  BaseSyncM.RadioReceive -> Comm;
  BaseSyncM.Leds -> LedsC;
  BaseSyncM.SimpleTime -> SimpleTime;
}