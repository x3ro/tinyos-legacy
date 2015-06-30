//Mohammad Rahimi
configuration SwitchC
{
  provides {
    interface StdControl as SwitchControl;
    interface Switch;
  }
}
implementation
{
  components I2CPacketC,SwitchM;
  Switch = SwitchM;
  SwitchControl = SwitchM;
  SwitchM.I2CPacket -> I2CPacketC.I2CPacket[75];
}
