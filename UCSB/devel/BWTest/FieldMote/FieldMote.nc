/*********************************************************
**	Author: 	Greg Moore - UCSB SensorNetProject
**
**	FileName:	FieldMote.nc
**
**	Purpose:	Set up wiring for FieldMoteM.nc
**				Allow user to test the bandwidth between 
**				two motes
**
**	Future:		Make sure this still works
**
*********************************************************/
configuration FieldMote {
}
implementation {
	components Main, FieldMoteM, RadioCRCPacket as Comm, LedsC;
	
	Main.StdControl -> FieldMoteM;
	
	FieldMoteM.RadioReceive -> Comm;
	FieldMoteM.RadioSend -> Comm;
	FieldMoteM.RadioControl -> Comm;
	
	FieldMoteM.Leds -> LedsC;
}