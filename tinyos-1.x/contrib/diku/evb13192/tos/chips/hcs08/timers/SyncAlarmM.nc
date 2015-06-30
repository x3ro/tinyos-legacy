
module SyncAlarmM
{
	provides
	{
		interface SyncAlarm<uint32_t> as Alarm[uint8_t timer];
		interface StdControl;
	}
	uses
	{
		interface LocalTime;
		interface HPLTimer<uint16_t> as HPLTimer;
	}

}
implementation
{
	#define NUM_CHANNELS 5
	enum {
		NUM_TIMERS = uniqueCount("SyncAlarm"),
	};
	
	typedef struct {
		bool isset;
		bool fired;
		uint16_t highStamp;
		uint16_t lowStamp;
	} Timer_t;

	Timer_t m_timers[NUM_TIMERS];

	uint8_t maxChannel = NUM_CHANNELS;
	
	uint8_t channelMap[NUM_CHANNELS];
	bool channelFree[NUM_CHANNELS];

	bool timerCheckPosted = FALSE;
	task void timerCheck();
	inline result_t armTimer(uint16_t highStamp, uint16_t lowStamp, uint8_t timer);

	command result_t StdControl.init()
	{
		uint8_t i;
		for (i=0;i<NUM_TIMERS;i++) {
			m_timers[i].isset = FALSE;
			m_timers[i].fired = FALSE;
		}
		for (i=0;i<maxChannel;i++) {
			atomic channelFree[i] = TRUE;
		}
		atomic channelFree[4] = FALSE;
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		call HPLTimer.arm(0x7FFF, 4);
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		return SUCCESS;
	}


	command result_t Alarm.armCountdown[uint8_t timer](uint32_t timeout)
	{
		uint16_t nowLow = (call LocalTime.getTimeL()&0xFFFF);
		uint32_t alarm = timeout+nowLow;
		uint16_t upper = alarm>>16;
		uint16_t lower = alarm&0xFFFF;
		
		return armTimer(upper, lower, timer);
	}
	
	command result_t Alarm.armAlarmClock[uint8_t timer](uint32_t time)
	{	
		uint32_t now = call LocalTime.getTimeL();
		uint32_t alarm = time - now;
		uint16_t upper = alarm>>16;
		uint16_t lower = alarm&0xFFFF;
		
		if (time < now) {
			return FAIL;
		}
		return armTimer(upper, lower, timer);
	}
	
	inline result_t armTimer(uint16_t highStamp, uint16_t lowStamp, uint8_t timer)
	{
		result_t res = FAIL;
		if ((highStamp == 1 && (lowStamp > 0x7FFF)) || highStamp > 1) {
			atomic {
				m_timers[timer].isset = TRUE;
				m_timers[timer].highStamp = highStamp;
				m_timers[timer].lowStamp = lowStamp;
			}
			res = SUCCESS;
		} else {
			// Program hw timer immediately.
			atomic {
				uint8_t channel;
				for (channel=0; channel < maxChannel; channel++) {
					if (channelFree[channel]) {
						channelFree[channel] = FALSE;
						channelMap[channel] = timer;
						call HPLTimer.arm(lowStamp, channel);
						res = SUCCESS;
						break;
					}
				}
			}
		}
		return res;
	}
	
	command result_t Alarm.stop[uint8_t timer]()
	{
		uint8_t i;
		if (m_timers[timer].isset) {
			m_timers[timer].isset = FALSE;
			return SUCCESS;
		}
		for (i=0;i<maxChannel;i++) {
			if (channelMap[i] == timer) {
				// Timer is programmed, stop hw timer.
				call HPLTimer.stop(i);
				channelFree[i] = TRUE;
				return SUCCESS;	
			}
		}
		return FAIL;
	}
	
	async event void HPLTimer.wrapped()
	{
		atomic {
		// Decrement highstamps on all timers and enable hw timer if 0
		uint8_t timer;
		for (timer=0;timer<NUM_TIMERS;timer++) {
			Timer_t* tt = m_timers+timer;
			if (tt->isset) {
				tt->highStamp--;
				if (tt->highStamp == 0 && tt->lowStamp > 0x7FFF) {
					uint8_t channel;
					tt->isset = FALSE;
					for (channel=0; channel<maxChannel; channel++) {
						if (channelFree[channel]) {
							channelFree[channel] = FALSE;
							channelMap[channel] = timer;
							call HPLTimer.arm(tt->lowStamp, channel);
							break;
						}
					}
				}
			}
		}
		}
	}
	
	async event void HPLTimer.fired(uint8_t channel)
	{
		atomic {
		if (channel == 4) {
			// We use channel 4 for signalling programming periods
			uint8_t timer;
			for (timer=0;timer<NUM_TIMERS;timer++) {
				Timer_t* tt = m_timers+timer;
				if (tt->isset) {
					if (tt->highStamp == 1 && tt->lowStamp <= 0x7FFF) {
						uint8_t c;
						tt->isset = FALSE;
						for (c=0; c<maxChannel; c++) {
							if (channelFree[c]) {
								channelFree[c] = FALSE;
								channelMap[c] = timer;
								call HPLTimer.arm(tt->lowStamp, c);
								break;
							}
						}
					}
				}
			}
		} else {
			// Signal the right alarm.
			call HPLTimer.stop(channel);
			channelFree[channel] = TRUE;
			m_timers[channelMap[channel]].fired = TRUE;
			if (!timerCheckPosted) {
				if (post timerCheck()) {
					timerCheckPosted = TRUE;
				}
			}
		}
		}
	}

	task void timerCheck()
	{
		uint8_t timer;
		for (timer=0;timer<NUM_TIMERS;timer++) {
			Timer_t* tt = m_timers+timer;
			if (tt->fired) {
				tt->fired = FALSE;
				signal Alarm.alarm[timer]();
			}
		}
		timerCheckPosted = FALSE;
	}

	default event result_t Alarm.alarm[uint8_t timer]()
	{
		dbg("Timer %d fired but not connected",timer);
		return SUCCESS;
	}

}
