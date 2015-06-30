//Mohammad Rahimi
includes IB;

configuration DioC {
  provides {
      interface StdControl;
      interface Dio[uint8_t channel];
  }
}
implementation {
    components LedsC,DioC,I2CPacketC,DioM;
    StdControl =  DioM.StdControl;
    Dio = DioM;
    DioM.Leds -> LedsC.Leds;
    /*X0111A2A1A0 which x i do not care and all inputs high*/
    DioM.I2CPacket -> I2CPacketC.I2CPacket[63];      
    DioM.I2CPacketControl -> I2CPacketC.StdControl;
}

