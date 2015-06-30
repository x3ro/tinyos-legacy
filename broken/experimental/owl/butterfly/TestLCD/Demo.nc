module Demo {
  provides interface StdControl;
  uses interface LCD;
  uses interface Timer;
  uses interface Joystick;
}
implementation {
  int n;

  task void message() {
    call LCD.display("TinyOS");
  }

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Timer.start(TIMER_REPEAT, 1000);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  bool on;

  event result_t Timer.fired() {
    if (on = !on) 
      {
	static char msg[] = "seg   ";
	msg[3] = n / 100 + '0';
	msg[4] = (n % 100) / 10 + '0';
	msg[5] = n % 10 + '0';
	call LCD.display(msg);
      }
    else
      {
	call LCD.clear();
	call LCD.setSegment(n, TRUE);
	call LCD.update();
      }
  }

  event result_t Joystick.fire() {
    return SUCCESS;
  }

  event result_t Joystick.move(uint8_t direction) {
    switch (direction)
      {
      case 0: n -= 1; break;
      case 1: n += 16; break;
      case 2: n += 1; break;
      case 3: n -= 16; break;
      }
    if (n < 0)
      n = 0;
    if (n >= 160)
      n = 159;
  }
}
