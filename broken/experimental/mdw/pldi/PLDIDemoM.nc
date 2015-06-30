/* Author: Matt Welsh
 * Last updated: 1 Nov 2002
 * 
 */

includes AM;
includes Multihop;

/**
 * 
 **/
module PLDIDemoM {
  provides interface StdControl;
  uses {
    interface ADC;
    interface Timer;
    interface Leds;
    interface Send;
  }
}
implementation {

  enum {
    TIMER_RATE = 1000,
    TIMER_GETADC_COUNT = 5
  };

  struct TOS_Msg adc_packet, forward_packet;
  uint16_t sensor_reading;
  int timer_ticks;
  bool send_busy;

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    send_busy = FALSE;
    return call Timer.start(TIMER_REPEAT, TIMER_RATE);
  }

  command result_t StdControl.stop() {
    return call Timer.stop();
  }

  event result_t Timer.fired() {
    timer_ticks++;
    if (timer_ticks % TIMER_GETADC_COUNT == 0) {
      call ADC.getData();
    }
    return SUCCESS;
  }

  event result_t ADC.dataReady(uint16_t data) {
    uint16_t length;
    uint16_t *outdata = (uint16_t *)call Send.getBuffer(&adc_packet, &length);

    if (!send_busy) {
      outdata[0] = data;
      if (call Send.send(&adc_packet, length) == SUCCESS) {
	send_busy = TRUE;
      }
    }
    return SUCCESS;
  }

  event result_t Send.sendDone(TOS_MsgPtr msg, bool success) {
    call Leds.greenToggle();
    send_busy = FALSE;
    return SUCCESS;
  }

}


