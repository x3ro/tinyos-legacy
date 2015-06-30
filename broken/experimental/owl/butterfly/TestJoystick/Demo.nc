module Demo {
  provides interface StdControl;
  uses interface LCD;
  uses interface Joystick;
}
implementation {

  uint8_t msg[] = "00 Joy ";
  

  task void message() {
    call LCD.display(msg);

    msg[1]++;
    if (msg[1] > '9') 
      {
	msg[1] = '0';
	msg[0]++;
      }
  }

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    post message();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t Joystick.fire() {
    strcpy(msg + 3, "fire");
    post message();
    return SUCCESS;
  }

  event result_t Joystick.move(uint8_t direction) {
    msg[3] = direction + '0';
    msg[4] = 0;
    post message();
    return SUCCESS;
  }
}
