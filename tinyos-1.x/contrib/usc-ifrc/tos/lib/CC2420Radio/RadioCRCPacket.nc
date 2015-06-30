
/**
 * Wrapper for GenericComm/AM to interface with the platform specific radio
 * @author Joe Polastre
 */
configuration RadioCRCPacket
{
  provides {
    interface StdControl as Control;
    interface BareSendMsg as Send;
    interface ReceiveMsg as Receive;
#ifdef CONG_CONTROL
    interface MacBackoff;
    interface MacControl;
#endif
  }
}
implementation
{
  components CC2420RadioC as RadioCRCPacketM; 

  Control = RadioCRCPacketM;
  Send = RadioCRCPacketM.Send;
  Receive = RadioCRCPacketM.Receive;
  MacBackoff = RadioCRCPacketM.MacBackoff;
  MacControl = RadioCRCPacketM.MacControl;
}



