includes mcuToRadioPorts;
	
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
	components mc13192RadioC as RadioCRCPacketC,
	           HPLSPIM as McuSPI,
	           LedsC; 

	Control = McuSPI.StdControl;
	Control = RadioCRCPacketC.Control;
	Send = RadioCRCPacketC.Send;
	Receive = RadioCRCPacketC.Receive;
	
	RadioCRCPacketC.SPI -> McuSPI.SPI;
	McuSPI.Leds -> LedsC;
}
