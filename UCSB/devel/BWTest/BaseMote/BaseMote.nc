/*********************************************************
**	Author: 	Greg Moore - UCSB SensorNetProject
**
**	FileName:	BaseMote.nc
**
**	Purpose:	Set up wiring for BaseMoteM.nc
**				Allow user to test the bandwidth between 
**				two motes
**
**	Future:		Make sure this still works
**
*********************************************************/
configuration BaseMote {
}
implementation {
	components Main, BaseMoteM, RadioCRCPacket as Comm;
	components FramerM, UART, LedsC, SysTimeC; 
	components TimerC;
	
	Main.StdControl -> BaseMoteM;
	
	BaseMoteM.UARTControl -> FramerM;
	BaseMoteM.UARTSend -> FramerM;
	BaseMoteM.UARTReceive -> FramerM;
	BaseMoteM.UARTTokenReceive -> FramerM;
	BaseMoteM.RadioControl -> Comm;
	BaseMoteM.RadioSend -> Comm;
	BaseMoteM.RadioReceive -> Comm;
	BaseMoteM.Timer -> TimerC.Timer[unique("Timer")];
	
	BaseMoteM.Leds -> LedsC;
	BaseMoteM.SysTime -> SysTimeC;
	FramerM.ByteControl -> UART;
	FramerM.ByteComm -> UART;
}