configuration UARTPacket {
  provides {
    interface MinTransDBPacket;
  }
}
implementation {
  components RouteHelper, VirtualComm, UARTPacketM;
  MinTransDBPacket = UARTPacketM.MinTransDBPacket;
  UARTPacketM.RouteHelp -> RouteHelper.RouteHelp;
  UARTPacketM.MinTransDBSend -> VirtualComm.VCSend[RS_DB_TYPE];

}
