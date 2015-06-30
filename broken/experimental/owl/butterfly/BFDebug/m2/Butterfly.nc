configuration Butterfly {
  provides {
    interface StdControl;
    interface BFDebug;
  }
}
implementation {
  components ButterflyM, I2CPacketC, I2CPacketSlaveC;

  StdControl = I2CPacketC;
  StdControl = I2CPacketSlaveC;
  StdControl = ButterflyM;
  BFDebug = ButterflyM;
  
  ButterflyM.I2CPacket -> I2CPacketC.I2CPacket[0x41];
  ButterflyM.I2CPacketSlave -> I2CPacketSlaveC;
}
