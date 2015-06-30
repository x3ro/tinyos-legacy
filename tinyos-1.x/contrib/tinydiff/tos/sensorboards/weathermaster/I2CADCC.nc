//Mohammad Rahimi
configuration I2CADCC
{
  provides {
    interface StdControl as IBADCcontrol;
    interface IBADC[uint8_t port];
  }
}
implementation
{
    components I2CPacketC,I2CADCM,I2CADCC,LedsC;//,GenericComm as Comm;
    I2CADCM.Leds -> LedsC;
    IBADCcontrol = I2CADCM.IBADCcontrol;
    IBADC=I2CADCM;
    /*X10010A1A0 which x i do not care and all inputs high*/
    /*In our circuit case A1=Vcc and A0=GND 01001010 or 0x4a 0r 74 bcd*/
    //    I2CADCM.I2CPacket -> I2CPacketC.I2CPacket[74];  //original by mhr
    I2CADCM.I2CPacket -> I2CPacketC.I2CPacket[74];
    I2CADCM.I2CPacketControl -> I2CPacketC.StdControl; 
    
    //CmstestM.SendtestMsg -> Comm.SendMsg[10];
    //CmstestM.ReceivetestMsg -> Comm.ReceiveMsg[10];
}
