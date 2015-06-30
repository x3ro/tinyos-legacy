/*
 * Author: Brano Kusy (branislav.kusy@vanderbilt.edu)
 * Date last modified: Dec04
 */

includes Timer;
includes TestTimeSyncPollerMsg;
includes TimeSyncMsg;

module TestTimeSyncPollerM
{
	provides 
	{
		interface StdControl;
	}
	uses 
	{
		interface SendMsg;
		interface Timer;
		interface Leds;
		interface DiagMsg;
	}
}

implementation
{
	TOS_Msg msg;
		 	
	#define TimeSyncPollMsg ((TimeSyncPoll *)(msg.data))

	#ifndef TS_POLLER_RATE
	#define TS_POLLER_RATE 30
	#endif

    enum{
        INITIAL_RATE = 3, //TS_POLLER_RATE>>2
        INITIAL_COUNT = 20,
        PHASE2_RATE = 3,
        PHASE2_COUNT = 0,
    };
	
	uint32_t ticks;

	command result_t StdControl.init(){
		call Leds.init();
		TimeSyncPollMsg->senderAddr = TOS_LOCAL_ADDRESS;
		TimeSyncPollMsg->msgID = 0;
		return SUCCESS;
	}

	command result_t StdControl.start(){
	    ticks = 10;
	    ticks |= (uint32_t)(INITIAL_COUNT+PHASE2_COUNT)<<16;
		call Timer.start(TIMER_REPEAT, (uint32_t)1000);
		return SUCCESS;
	}

	command result_t StdControl.stop(){
		return SUCCESS;
	}
	
	event result_t SendMsg.sendDone(TOS_MsgPtr p, result_t success){
		return SUCCESS;
	}

	event result_t Timer.fired(){
        if ( (--ticks & 0xFFFF) != 0)
            return SUCCESS;
        
        if (ticks == 0)
            ticks = TS_POLLER_RATE;
        else{
            uint32_t remaining_ticks = (ticks>>16)-1;
            ticks = remaining_ticks<<16;
            if ( remaining_ticks < PHASE2_COUNT )
                ticks += PHASE2_RATE;
            else
                ticks += INITIAL_RATE;
        }
 	    call SendMsg.send(TOS_BCAST_ADDR, TIMESYNCPOLL_LEN, &msg);
        ++TimeSyncPollMsg->msgID;
		
		return SUCCESS;
	}
}
