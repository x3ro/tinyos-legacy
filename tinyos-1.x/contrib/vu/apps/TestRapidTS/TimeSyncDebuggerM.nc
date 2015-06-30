/*
 * Author: Brano Kusy, kusy@isis.vanderbilt.edu
 * Date last modified: Dec04
 */

includes Timer;
includes DiagMsg;
includes TestTimeSyncPollerMsg;

module TimeSyncDebuggerM
{
	provides
		interface StdControl;
	uses
	{
		interface GlobalTime;
		interface TimeSyncInfo;
		interface ReceiveMsg;
		interface DiagMsg;
		interface Timer;
		interface Leds;
		interface TimeStamping;
	}
}

implementation
{
	struct data_t{
		uint16_t	msgID;
		uint32_t	globalClock;
		uint32_t	localClock;
		int32_t     offset;
        uint32_t    syncPt;
		float		skew;
		uint8_t		is_synced;
		uint8_t		seqNum;
		uint8_t		numEntries;
	} data_t;

	struct data_t d;
	bool reporting = 0;

	command result_t StdControl.init() {
        call Leds.init();
		reporting = FALSE;
		return SUCCESS;
	}

	command result_t StdControl.start() {
	    call Leds.yellowOn();
		return call Timer.start(TIMER_REPEAT, 3000);	// every ten seconds
	}

	command result_t StdControl.stop() {
		return call Timer.stop();
	}

	task void report() {
		if( reporting && call DiagMsg.record() == SUCCESS )
		{
			call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
			call DiagMsg.uint16(d.msgID);

			call DiagMsg.uint32(d.globalClock);
			call DiagMsg.uint32(d.localClock);
			
			call DiagMsg.uint32(d.offset);
			call DiagMsg.uint32(d.syncPt);
			call DiagMsg.real(d.skew);
//			call DiagMsg.uint8(d.is_synced);

//			call DiagMsg.uint8(d.seqNum);
			call DiagMsg.uint8(d.numEntries);

			call DiagMsg.send();
		}
		reporting = FALSE;
	}

	event result_t Timer.fired() {
		if( reporting )
			post report();
		return SUCCESS;
	}

	event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr p)
	{
		call Leds.yellowToggle();

		if( !reporting )
		{
			d.msgID = ((TimeSyncPoll*)(p->data))->msgID;

			d.localClock = call TimeStamping.getStamp();
			d.globalClock = d.localClock;
			d.is_synced = call GlobalTime.local2Global(&d.globalClock);
				
			d.skew = call TimeSyncInfo.getSkew();
			d.offset = call TimeSyncInfo.getOffset();
            d.syncPt = call TimeSyncInfo.getSyncPoint();
			d.seqNum = call TimeSyncInfo.getSeqNum();
			d.numEntries = call TimeSyncInfo.getNumEntries();

			reporting = TRUE;
		}

		return p;
	}
 }
