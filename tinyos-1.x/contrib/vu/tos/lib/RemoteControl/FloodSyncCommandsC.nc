/*
 *
 * @author Brano Kusy, kusy@isis.vanderbilt.edu
 * @modified jan05
 */
includes FloodSyncCommands;

configuration FloodSyncCommandsC
{
}

implementation
{
	components Main, FloodSyncCommandsM, RemoteControlC, TimerC, NoLeds as LedsC, 
#ifdef TIMESYNC_SYSTIME		
		SysTimeStampingC as TimeStampingC,
#else 
		ClockTimeStampingC as TimeStampingC,
#endif	
	FloodRoutingSyncC, GradientPolicyC, GenericComm;

	Main.StdControl -> FloodRoutingSyncC;
	Main.StdControl -> FloodSyncCommandsM;
	RemoteControlC.IntCommand[FLOODSYNC_CTLID] -> FloodSyncCommandsM;

	FloodSyncCommandsM.TimeStamping -> TimeStampingC;
	FloodSyncCommandsM.FloodRouting		-> FloodRoutingSyncC.FloodRouting[FLOODSYNCCMD_ID];
    FloodSyncCommandsM.TimeStamp         -> FloodRoutingSyncC.TimeStamp;
    FloodRoutingSyncC.FloodingPolicy[FLOODSYNCCMD_ID] 	-> GradientPolicyC;

	FloodSyncCommandsM.SendMsg	-> GenericComm.SendMsg[AM_FLOODSYNCCMDPOLL];
	FloodSyncCommandsM.ReceiveMsg	-> GenericComm.ReceiveMsg[AM_FLOODSYNCCMDPOLL];
	FloodSyncCommandsM.Timer		-> TimerC.Timer[unique("Timer")];
	FloodSyncCommandsM.Leds		-> LedsC.Leds;
}
