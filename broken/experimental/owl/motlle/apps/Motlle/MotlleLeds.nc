includes Motlle;
module MotlleLeds {
  uses interface MotlleControl;
  uses interface Leds;
}
implementation {
  uint16_t sleeptime;

  event result_t MotlleControl.init() {
    call Leds.set(0);
    return SUCCESS;
  }

  void motlle_req_leds(uint8_t cmd) __attribute__((C, spontaneous)) {
    switch (cmd) {
    case led_y_toggle:
      call Leds.yellowToggle();
      break;
    case led_y_on:
      call Leds.yellowOn();
      break;
    case led_y_off:
      call Leds.yellowOff();
      break;
    case led_r_toggle:
      call Leds.redToggle();
      break;
    case led_r_on:
      call Leds.redOn();
      break;
    case led_r_off:
      call Leds.redOff();
      break;
    case led_g_toggle:
      call Leds.greenToggle();
      break;
    case led_g_on:
      call Leds.greenOn();
      break;
    case led_g_off:
      call Leds.greenOff();
      break;
    }
  }
}
