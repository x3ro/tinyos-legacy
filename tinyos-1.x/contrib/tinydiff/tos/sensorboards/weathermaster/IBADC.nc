 configuration IBADC
{
  provides {
    interface StdControl;
    interface Excite;
    interface ADC[uint8_t port];
    
  }
}
implementation
{
  components I2CPacketC,IBADCM,LedsC,TimerC;

  StdControl = IBADCM;
  ADC = IBADCM;
  Excite = IBADCM;
  IBADCM.Leds -> LedsC;
  IBADCM.I2CPacket -> I2CPacketC.I2CPacket[74];
  IBADCM.I2CPacketControl -> I2CPacketC.StdControl; 
  IBADCM.PowerStabalizingTimer -> TimerC.Timer[unique("Timer")];
}
