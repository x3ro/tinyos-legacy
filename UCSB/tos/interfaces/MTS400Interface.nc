/*********************************************************
**	Author: 	Greg Moore - UCSB SensorNetProject
**
**	FileName:	MTS400Interface.nc
**
**	Purpose:	Provides the Interface for MTS400 sensing.
*********************************************************/
includes CmdMsg;

interface MTS400Interface {
	command result_t startSensing();
	event result_t sensingDone(MTS400DataMsgPtr msg);
}

