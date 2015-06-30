module NA {
  provides {
    interface Init;
    interface Alarm<TMilli, uint32_t>;
    interface Counter<TMilli, uint32_t>;
    interface McuPowerOverride;
  }
}
implementation
{
  uint8_t set;
  uint32_t t0, dt;
  uint32_t base, lastNow;

  void oopsT0() {
  }

  void oopsNow() {
  }

  enum {
    MINDT = 2,
    MAXT = 230
  };

  void stabiliseTimer0() {
    TCCR0 = TCCR0;
    while (ASSR & 1 << TCR0UB)
      ;
  }

  void setOcr0(uint8_t n) {
    while (ASSR & 1 << OCR0UB)
      ;
    if (n == TCNT0)
      n++;
    OCR0 = n; 
  }

  void setInterrupt() {
    bool fired = FALSE;

    atomic
      {
	uint8_t interrupt_in = 1 + OCR0 - TCNT0;
	uint8_t newOcr0;

	if (interrupt_in < MINDT || TIFR & 1 << OCF0)
	  return; // wait for next interrupt
	if (!set)
	  newOcr0 = MAXT;
	else
	  {
	    uint32_t now = call Counter.get();
	    if (now < t0) 
	      {
		oopsT0();
		t0 = now;
	      }
	    if (now - t0 >= dt)
	      {
		set = FALSE;
		fired = TRUE;
		newOcr0 = MAXT;
	      }
	    else
	      {
		uint32_t alarm_in = (t0 + dt) - base;

		if (alarm_in > MAXT)
		  newOcr0 = MAXT;
		else if (alarm_in < MINDT)
		  newOcr0 = MINDT;
		else
		  newOcr0 = alarm_in;
	      }
	  }
	newOcr0--; // interrupt is 1ms late
	setOcr0(newOcr0);
      }
    if (fired)
      signal Alarm.fired();
  }

  AVR_ATOMIC_HANDLER(SIG_OUTPUT_COMPARE0) {
    stabiliseTimer0();
    base += OCR0 + 1;
    setInterrupt();
  }  

  command error_t Init.init() {
    atomic
      {
	ASSR |= 1 << AS0;
	TIMSK |= 1 << OCIE0;
	TCCR0 = ATM128_CLK8_DIVIDE_32 | 1 << WGM01;
	OCR0 = MAXT;
	setInterrupt();
      }
    return SUCCESS;
  }

  async command uint32_t Counter.get() {
    uint32_t now;

    atomic
      {
	uint8_t now8 = TCNT0;

	if (TIFR & 1 << OCF0)
	  now = base + OCR0 + TCNT0;
	else
	  now = base + now8;

	if (now < lastNow)
	  {
	    oopsNow();
	    now = lastNow;
	  }
	lastNow = now;
      }
    return now;
  }

  async command bool Counter.isOverflowPending() {
    return FALSE;
  }

  async command void Counter.clearOverflow() { }

  async command void Alarm.start(uint32_t ndt) {
    call Alarm.startAt(call Counter.get(), ndt);
  }

  async command void Alarm.stop() {
    atomic set = FALSE;
  }

  async command bool Alarm.isRunning() {
    atomic return set;
  }

  async command void Alarm.startAt(uint32_t nt0, uint32_t ndt) {
    atomic
      {
	set = TRUE;
	t0 = nt0;
	dt = ndt;
      }
    setInterrupt();
  }

  async command uint32_t Alarm.getNow() {
    return call Counter.get();
  }

  async command uint32_t Alarm.getAlarm() {
    atomic return t0 + dt;
  }

  async command mcu_power_t McuPowerOverride.lowestState() {
    uint8_t diff;
    // We need to make sure that the sleep wakeup latency will not
    // cause us to miss a timer. POWER_SAVE 
    if (TIMSK & (1 << OCIE0 | 1 << TOIE0)) {
      // need to wait for timer 0 updates propagate before sleeping
      // (we don't need to worry about reentering sleep mode too early,
      // as the wake ups from timer0 wait at least one TOSC1 cycle
      // anyway - see the stabiliseTimer0 function in HplAtm128Timer0AsyncC)
      while (ASSR & (1 << TCN0UB | 1 << OCR0UB | 1 << TCR0UB))
	;
      diff = OCR0 - TCNT0;
      if (diff < EXT_STANDBY_T0_THRESHOLD ||
	  TCNT0 > 256 - EXT_STANDBY_T0_THRESHOLD) 
	return ATM128_POWER_EXT_STANDBY;
      return ATM128_POWER_SAVE;
    }
    else {
      return ATM128_POWER_DOWN;
    }
  }
}
