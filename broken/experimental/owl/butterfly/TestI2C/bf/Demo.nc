module Demo {
  provides interface StdControl;
  uses interface LCD;
  uses interface Joystick;
  uses interface I2CPacket;
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

  void i2cSend(uint8_t n) {
    static uint8_t imsg;

    imsg = n;
    if (!call I2CPacket.writePacket(&imsg, 1, 0))
      msg[2] = 'y';
    else
      msg[2] = ' ';
  }

  event result_t I2CPacket.writePacketDone(char *x, uint8_t l, result_t result) {
    if (!result)
      {
	msg[2] = 'x';
	post message();
      }
    return SUCCESS;
  }

  event result_t I2CPacket.readPacketDone(char *x, uint8_t l, result_t result) { return SUCCESS; }

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
    strcpy(msg + 3, "fi2c");
    i2cSend(4);
    post message();
    return SUCCESS;
  }

  event result_t Joystick.move(uint8_t direction) {
    msg[3] = direction + '0';
    msg[4] = 0;
    i2cSend(direction);
    post message();
    return SUCCESS;
  }
}

