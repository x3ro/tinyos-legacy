module Sounder {
  provides {
    interface StdControl;
    interface Sound;
  }
}
implementation {
  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    // Setup timer
    // Using mode 4, toggle (atmel was doing funky pwm stuff, which doesn't
    // seem to work particularly well, or bring any real benefits - the
    // volume stuff definitely didn't work)
    outp(1 << COM1A0, TCCR1A);
    outp(1 << WGM12, TCCR1B);
    sbi(DDRB, 5);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    cbi(DDRB, 5);
    return SUCCESS;
  }

  command result_t Sound.play(uint16_t frequency) {
    uint16_t interval;

    call Sound.stop();
    atomic 
      {
	interval = 500000L / frequency;
	outp(0, TCNT1H);
	outp(0, TCNT1L);
	outp(interval >> 8, OCRA1H);
	outp(interval, OCRA1L);
	sbi(TCCR1B, CS10);
      }
    return SUCCESS;
  }

  command result_t Sound.stop() {
    cbi(TCCR1B, CS10);
    sbi(PORTB, 5);
    
    return SUCCESS;
  }
}
