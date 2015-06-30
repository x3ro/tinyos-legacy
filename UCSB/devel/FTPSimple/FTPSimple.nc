/*********************************************************
**	Author: 	Greg Moore - UCSB SensorNetProject
**
**	FileName:	FTPSimple.nc
**
**	Purpose:	Set up wiring for FTPSimpleM.nc
**				Allow user to transfer whole files to mote
**
**	Future:		Finish!!!!!
**
*********************************************************/
configuration FTPSimple {
}
implementation {
	components Main, TimerC, PageEEPROMC, EEPROM; // Logger;
	components LedsC, FTPSimpleM, RadioCRCPacket as Comm;
	
	Main.StdControl -> FTPSimpleM;
	Main.StdControl -> TimerC;
	
	FTPSimpleM.Timer -> TimerC.Timer[unique("Timer")];
	FTPSimpleM.RadioControl -> Comm;
	FTPSimpleM.RadioReceive -> Comm;
	FTPSimpleM.RadioSend -> Comm;
	
	FTPSimpleM.EEPROMControl -> EEPROM;
	FTPSimpleM.EEPROMRead -> EEPROM;
	FTPSimpleM.EEPROMWrite -> EEPROM.EEPROMWrite[unique("EEPROMWrite")];
	
	/*
	FTPSimpleM.LoggerRead -> Logger.LoggerRead;
	FTPSimpleM.LoggerWrite -> Logger.LoggerWrite;
	*/
	
	FTPSimpleM.Leds -> LedsC;
}