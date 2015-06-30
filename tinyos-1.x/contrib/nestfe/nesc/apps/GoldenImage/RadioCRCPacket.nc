configuration RadioCRCPacket
{
  provides {
    interface StdControl as Control;
    interface BareSendMsg as Send;
    interface ReceiveMsg as Receive;
  }
}
implementation
{
  components RadioCRCPacketM;
  components CC2420RadioC;
  components NoLeds as Leds;

  Control = RadioCRCPacketM;
  Send = RadioCRCPacketM.Send;
  Receive = RadioCRCPacketM.Receive;

  RadioCRCPacketM.Leds -> Leds;

  RadioCRCPacketM.LowerControl -> CC2420RadioC;
  RadioCRCPacketM.LowerSend -> CC2420RadioC.Send;
  RadioCRCPacketM.LowerReceive -> CC2420RadioC.Receive;
}



