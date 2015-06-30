includes TimeSync;

configuration ReceiverSync {
}
implementation {
  components Main, ReceiverSyncM, LedsC;
  components RadioCRCPacket as Comm, SimpleTime as SimpleTime;
  components SimpleTime as TimeSet, TimerC;
  
  Main.StdControl -> ReceiverSyncM;
  ReceiverSyncM.RadioReceive -> Comm;
  ReceiverSyncM.RadioControl -> Comm;
  ReceiverSyncM.RadioSend -> Comm;
  ReceiverSyncM.Leds -> LedsC;
  ReceiverSyncM.Timer -> TimerC.Timer[unique("Timer")];
  ReceiverSyncM.SimpleTime -> SimpleTime;
  ReceiverSyncM.TimeSet -> SimpleTime;
}