/*
 * Author: Brano Kusy, kusy@isis.vanderbilt.edu
 * Date last modified: Dec04
 */

includes TestTimeSyncPollerMsg;

configuration TimeSyncDebuggerC
{
	provides interface StdControl;
}

implementation 
{
	components TimeSyncDebuggerM, TimeSyncC, GenericComm,
		DiagMsgC, TimerC, NoLeds as LedsC,
#ifdef TIMESYNC_SYSTIME
		SysTimeStampingC as TimeStampingC;
#else
		ClockTimeStampingC as TimeStampingC;
#endif

	StdControl = TimeSyncDebuggerM;

	TimeSyncDebuggerM.ReceiveMsg	-> GenericComm.ReceiveMsg[AM_TIMESYNCPOLL];
	TimeSyncDebuggerM.DiagMsg	-> DiagMsgC;
	TimeSyncDebuggerM.Timer		-> TimerC.Timer[unique("Timer")];
	TimeSyncDebuggerM.GlobalTime	-> TimeSyncC;
	TimeSyncDebuggerM.TimeSyncInfo	-> TimeSyncC;
	TimeSyncDebuggerM.Leds		-> LedsC;
	TimeSyncDebuggerM.TimeStamping	-> TimeStampingC;
}
