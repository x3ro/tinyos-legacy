/*********************************************************
**	Author: 	Greg Moore - UCSB SensorNetProject
**
**	FileName:	MTS310Interface.nc
**
**	Purpose:	Provides the Interface for MTS310/MTS300
**				sensing.
*********************************************************/
includes CmdMsg;

interface MTS310Interface {
	command result_t startSensing();
	event result_t sensingDone(MTS310DataMsgPtr msg);
}

