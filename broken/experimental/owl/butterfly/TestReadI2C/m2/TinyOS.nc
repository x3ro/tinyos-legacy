configuration TinyOS { }
implementation {
  components Main, I2CPacketSlaveC, Fun, LedsC;

  Main.StdControl -> Fun;
  Main.StdControl -> I2CPacketSlaveC;

  Fun.I2CPacketSlave -> I2CPacketSlaveC;
  Fun.Leds -> LedsC;
}
