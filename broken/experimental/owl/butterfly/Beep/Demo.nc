module Demo {
  provides interface StdControl;
  uses interface Sound;
  uses interface Timer;
  uses interface Joystick;
  uses interface LCD;
}
implementation {
  uint16_t frequency = 400;
  bool toggle;

  task void beep() {
  }

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t Joystick.fire() {
    char msg[20];

    call Sound.play(frequency);
    call Timer.start(TIMER_ONE_SHOT, 500);

    sprintf(msg, "F%d", (int)frequency);
    call LCD.display(msg);
    return SUCCESS;
  }

  event result_t Joystick.move(uint8_t direction) {
    switch (direction)
      {
      case 0: frequency -= 10; break;
      case 2: frequency += 10; break;
      case 1: frequency += 50; break;
      case 3: frequency -= 50; break;
      }
    return SUCCESS;
  }

  event result_t Timer.fired() {
    call LCD.display("");
    call Sound.stop();
    return SUCCESS;
  }
}
