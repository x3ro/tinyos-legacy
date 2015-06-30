/*
 * Author: Brano Kusy
 * Date last modified: Dec 04
 */

includes TimeSyncMsg;

configuration TimeSyncC
{
	provides interface StdControl;
	provides interface GlobalTime;
	provides interface TimeSyncInfo;
}

implementation 
{
	components LedsC, Main, DiagMsgC,
	            FloodRoutingSyncC as FloodRoutingC, BroadcastPolicyM,
	            TimeSyncM, 
#ifdef TIMESYNC_SYSTIME
		SysTimeC;
#else
    #ifdef PLATFORM_TELOS
		TimerC;
	#else
	    ClockC;
	#endif
#endif

	GlobalTime = TimeSyncM;
	StdControl = TimeSyncM;
	TimeSyncInfo = TimeSyncM;
	
	Main.StdControl -> FloodRoutingC;

    TimeSyncM.TimeStamp -> FloodRoutingC;
	TimeSyncM.FloodRouting -> FloodRoutingC.FloodRouting[TIMESYNC_ID];
	FloodRoutingC.FloodingPolicy[TIMESYNC_ID] -> BroadcastPolicyM;
	TimeSyncM.Leds			-> LedsC;
	TimeSyncM.DiagMsg       -> DiagMsgC;
#ifdef TIMESYNC_SYSTIME
	TimeSyncM.SysTime		-> SysTimeC;
#else
    #ifdef PLATFORM_TELOS
        TimeSyncM.LocalTime     -> TimerC;
    #else
    	TimeSyncM.LocalTime		-> ClockC;
    #endif
#endif

}
