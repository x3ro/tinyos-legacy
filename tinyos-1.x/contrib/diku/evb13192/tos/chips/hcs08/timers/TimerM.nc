
// @author Jan Flora <janflora@diku.dk>

includes Timer;

module TimerM
{
	provides
	{
		interface StdControl;
		interface Timer[uint8_t timer];
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
		NUM_TIMERS = uniqueCount("Timer"),
	};
	
	typedef struct {
		bool isset;
		bool fired;
		bool isperiodic;
		TimerTicks_t period;
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
			atomic {
				m_timers[i].isset = FALSE;
				m_timers[i].fired = FALSE;
			}
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
			Timer_t* tt = m_timers+channelMap[channel];
			// Signal the right alarm.
			call HPLTimer.stop(channel);
			channelFree[channel] = TRUE;
			tt->fired = TRUE;
			if (tt->isperiodic) {
				// Reinitialize the timer.
				uint32_t alarm = (tt->period*1000);
				armTimer(alarm>>16, alarm&0xFFFF, channelMap[channel]);
			}
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
				signal Timer.fired[timer]();
			}
		}
		atomic timerCheckPosted = FALSE;
	}

	command result_t Timer.setOneShot[uint8_t timer]( TimerTicks_t millis )
	{
		uint16_t nowLow = (call LocalTime.getLow16()&0xFFFF);
		uint32_t alarm = (millis*1000)+nowLow;
		uint16_t upper = alarm>>16;
		uint16_t lower = alarm&0xFFFF;
		
		m_timers[timer].isperiodic = FALSE;
		
		return armTimer(upper, lower, timer);
	}

	command result_t Timer.setPeriodic[uint8_t timer]( TimerTicks_t millis )
	{
		uint32_t alarm = (millis*1000);
		uint16_t upper = alarm>>16;
		uint16_t lower = alarm&0xFFFF;
		
		atomic {
			m_timers[timer].isperiodic = TRUE;
			m_timers[timer].period = millis;
		}
		
		return armTimer(upper, lower, timer);
	}

	command result_t Timer.stop[uint8_t timer]()
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

	command bool Timer.isSet[uint8_t timer]()
	{
		return m_timers[timer].isset;
	}

	command bool Timer.isPeriodic[uint8_t timer]()
	{
		return m_timers[timer].isperiodic;
	}

	command bool Timer.isOneShot[uint8_t timer]()
	{
		return !m_timers[timer].isperiodic;
	}

	command TimerTicks_t Timer.getPeriod[uint8_t timer]()
	{
		return m_timers[timer].period;
	}

	command result_t Timer.start[uint8_t timer]( uint8_t type, TimerTicks_t millis )
	{
		switch( type ) {
			case TIMER_REPEAT:
				return call Timer.setPeriodic[timer]( millis );
			case TIMER_ONE_SHOT:
				return call Timer.setOneShot[timer]( millis );
		}
		return FAIL;
	}

	default event result_t Timer.fired[uint8_t timer]()
	{
		dbg("Timer %d fired but not connected",timer);
		return SUCCESS;
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
}
