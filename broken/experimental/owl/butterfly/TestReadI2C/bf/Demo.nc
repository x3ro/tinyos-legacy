module Demo {
  provides interface StdControl;
  uses interface LCD;
  uses interface I2CPacket;
  uses interface Timer;
}
implementation {
  uint8_t msg[] = "Get";
  
  task void message() {
    call LCD.display(msg);
  }

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    post message();
    call Timer.start(TIMER_REPEAT, 2000);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t Timer.fired() {
    static char buf;
    if (!call I2CPacket.readPacket(&buf, 1, 3))
      ;//call Leds.yellowToggle();
    return SUCCESS;
  }

  event result_t I2CPacket.writePacketDone(char *x, uint8_t l, result_t result) {
    return SUCCESS;
  }

  event result_t I2CPacket.readPacketDone(char *data, uint8_t l, result_t result) {
    uint8_t n = *data;

    msg[0] = n / 10 + '0';
    msg[1] = n % 10 + '0';
    post message();
    return SUCCESS; 
  }
}

