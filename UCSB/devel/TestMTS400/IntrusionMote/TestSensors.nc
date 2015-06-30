/*********************************************************
**	Author: 	Greg Moore - UCSB SensorNetProject
**
**	FileName:	TestSensors.nc
**
**	Purpose:	Set up wiring for TestSensorsM.nc
**				For more information look at TestSensorsM.nc
**
**	Future:
**
*********************************************************/

includes CmdMsg;

configuration TestSensors {
// this module does not provide any interface
}
implementation {
  components Main, TestSensorsM, GenericComm as Comm;
  components TimerC, LedsC, PotC;
  components CC1000RadioIntM, CC1000ControlM, HPLPowerManagementM;
  components MTS400;
  
  
  //components DelugeC;

  Main.StdControl -> TestSensorsM;
  Main.StdControl -> TimerC;
  
  TestSensorsM.CommControl -> Comm;
  TestSensorsM.Receive -> Comm.ReceiveMsg[AM_CMDMSG];
  TestSensorsM.Send -> Comm.SendMsg[AM_SENSORMSG400];
  
  TestSensorsM.CC1000Control -> CC1000ControlM;
  
  // Wiring for Radio Power Control
  TestSensorsM.Pot -> PotC;
  
  // Sensing Components
  TestSensorsM.MTS400Interface -> MTS400.MTS400Interface;
  
  TestSensorsM.Leds -> LedsC;    
  
  TestSensorsM.SampleTimer -> TimerC.Timer[unique("Timer")];
  
// Wiring to test stop() functions as sleep counterpart
  TestSensorsM.SleepTimer -> TimerC.Timer[unique("Timer")];
}
