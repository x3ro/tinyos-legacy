configuration RadioPacket {
  provides {
    interface ServiceControl;
    interface ServiceStatus;

    interface Packet;
    interface Send;
    interface Receive;
  }
}
implementation {
  // Some kind of wiring stuff here

}
