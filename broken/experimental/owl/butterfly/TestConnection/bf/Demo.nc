module Demo {
  provides interface StdControl;
  uses interface LCD;
  uses interface Joystick;
}
implementation {

  uint8_t msg[] = "00 I2C ";
  

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
    TOSH_MAKE_I2C_BUS1_SDA_OUTPUT();
    TOSH_MAKE_I2C_BUS1_SCL_OUTPUT();
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
    strcpy(msg + 3, "con");
    post message();
    return SUCCESS;
  }

  event result_t Joystick.move(uint8_t direction) {
    msg[3] = direction + '0';
    msg[4] = 0;
    if (direction & 1)
      TOSH_SET_I2C_BUS1_SCL_PIN();
    else
      TOSH_CLR_I2C_BUS1_SCL_PIN();
    if (direction & 2)
      TOSH_SET_I2C_BUS1_SDA_PIN();
    else
      TOSH_CLR_I2C_BUS1_SDA_PIN();

    post message();
    return SUCCESS;
  }
}

