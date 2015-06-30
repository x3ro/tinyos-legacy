/*********************************************************
**	Author: 	Greg Moore - UCSB SensorNetProject
**
**	FileName:	Snoop.nc
**
**	Purpose:	Set up wiring for Snoop.nc
**				For more information look at SnoopM.nc.
**
**	Future:
*********************************************************/
configuration Snoop {
}
implementation {
	components Main, SnoopM, RadioCRCPacket as Comm;
	components FramerM, UART, LedsC;
	
	Main.StdControl -> SnoopM;
	SnoopM.UARTControl -> FramerM;
	SnoopM.UARTSend -> FramerM;
	SnoopM.UARTReceive -> FramerM;
	
	SnoopM.RadioSend -> Comm;
	SnoopM.RadioControl -> Comm;
	SnoopM.RadioReceive -> Comm;
	
	SnoopM.Leds -> LedsC;
	
	FramerM.ByteControl -> UART;
	FramerM.ByteComm -> UART;
}