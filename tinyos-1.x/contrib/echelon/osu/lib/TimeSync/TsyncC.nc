includes OTime;
includes Beacon;

configuration TsyncC {
  provides interface StdControl;
  provides interface OTime;
  }

implementation
{
  components TsyncM, AlarmC, OTimeC;
  components GenericComm;
  components LedsC;
  components SysTimeStampingC;

  StdControl = TsyncM;
  OTime = OTimeC;
  TsyncM.CommControl -> GenericComm;
  TsyncM.Alarm -> AlarmC.Alarm[unique("Alarm")];
  TsyncM.AlarmControl -> AlarmC.StdControl;
  TsyncM.OTimeControl -> OTimeC.StdControl;
  TsyncM.OTime -> OTimeC.OTime;
  TsyncM.BeaconSendMsg -> GenericComm.SendMsg[AM_BEACON];
  TsyncM.BeaconReceiveMsg -> GenericComm.ReceiveMsg[AM_BEACON];
  TsyncM.ProbeSendMsg -> GenericComm.SendMsg[AM_PROBE_ACK];
  TsyncM.ProbeReceiveMsg -> GenericComm.ReceiveMsg[AM_BEACON_PROBE];
  TsyncM.Leds -> LedsC;
  TsyncM.TimeStamping -> SysTimeStampingC;
}

