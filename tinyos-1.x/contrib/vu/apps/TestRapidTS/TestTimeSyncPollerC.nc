/*
 * Author: Brano Kusy, kusy@isis.vanderbilt.edu
 * Date last modified: Dec04
 */

includes TestTimeSyncPollerMsg;
includes TimeSyncMsg;

configuration TestTimeSyncPollerC
{
}

implementation 
{
	components TestTimeSyncPollerM, Main, GenericComm, TimerC, DiagMsgC, LedsC;

	Main.StdControl -> TestTimeSyncPollerM;
	Main.StdControl -> GenericComm;
	Main.StdControl -> TimerC;

	TestTimeSyncPollerM.SendMsg		-> GenericComm.SendMsg[AM_TIMESYNCPOLL];
	TestTimeSyncPollerM.Timer		-> TimerC.Timer[unique("Timer")];
	TestTimeSyncPollerM.Leds		-> LedsC;
	TestTimeSyncPollerM.DiagMsg		-> DiagMsgC;
		
}
