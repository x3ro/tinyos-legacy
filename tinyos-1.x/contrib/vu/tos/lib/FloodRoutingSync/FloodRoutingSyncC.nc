 /** 
 * FloodRoutingSync is an implementation of the Routing Integrated Time Synchronization (RITS) protocol.
 * RITS extends FloodRouting engine by aggregating time information into the data packets (e.g. local time
 * of an event) and converting the timing information from the local time of the sender to the receiver's
 * local time as the packets are routed in the network. If converge cast is used towards base station, the 
 * base station can convert event times of all received packets into its local time.
 *
 * For more information on FloodRouting, please see FloodRoutingM.nc.
 *
 *   @author Miklos Maroti
 *   @author Brano Kusy, kusy@isis.vanderbilt.edu
 *   @modified Jan05 doc fix
 */

includes FloodRoutingSyncMsg;

configuration FloodRoutingSyncC
{
	provides
	{
		interface StdControl;
		interface FloodRouting[uint8_t id];
		interface TimeStamp;	//timing extension of routing
	}
	uses
	{
		interface FloodingPolicy[uint8_t id];
	}
}

implementation
{
	components FloodRoutingSyncM, TimerC, GenericComm, NoLeds as LedsC, 

#ifdef LOGICAL_IDS
//allows to impose logical grid on top of hardwired TOS addresses
        IDsM,
#endif

#ifdef TIMESYNC_SYSTIME					
		SysTimeStampingC as TimeStampingC;	// fast clock source for time extension
#else							
		ClockTimeStampingC as TimeStampingC;	// slow clock source for time extension
#endif							

	StdControl = FloodRoutingSyncM;
	FloodRouting = FloodRoutingSyncM;
	TimeStamp = FloodRoutingSyncM;
	FloodingPolicy = FloodRoutingSyncM;

#ifdef LOGICAL_IDS
    FloodRoutingSyncM.IDs -> IDsM;
#endif

	FloodRoutingSyncM.SendMsg -> GenericComm.SendMsg[AM_FLOODROUTINGSYNC];
	FloodRoutingSyncM.ReceiveMsg -> GenericComm.ReceiveMsg[AM_FLOODROUTINGSYNC];
	FloodRoutingSyncM.Timer -> TimerC.Timer[unique("Timer")];

	FloodRoutingSyncM.SubControl -> GenericComm;
	FloodRoutingSyncM.SubControl -> TimerC;

	FloodRoutingSyncM.Leds -> LedsC;
	FloodRoutingSyncM.TimeStamping -> TimeStampingC;
}
