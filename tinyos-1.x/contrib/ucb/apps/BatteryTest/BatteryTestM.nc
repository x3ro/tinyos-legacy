module BatteryTestM {
  provides interface StdControl;
  uses {
    interface ADC as VoltageADC;
    interface SendMsg;
    interface Leds;
    interface Timer;
  }
}
implementation {

  TOS_Msg msg;
  bool msgBufBusy;

  task void sendTask();

  command result_t StdControl.init() {
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Timer.start(TIMER_REPEAT, 512);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call Timer.stop();
    return SUCCESS;
  }

  event result_t Timer.fired() {
    call Leds.set(0);
    TOSH_uwait(1000);
    call VoltageADC.getData();
    return SUCCESS;
  }

  async event result_t VoltageADC.dataReady(uint16_t data) {
    BatteryTestMsg *btMsg = (BatteryTestMsg*) &msg.data[0];

    if (data >= BATTERYTEST_3V) {
      call Leds.set(0x7);
    } else if (data >= BATTERYTEST_2_7V) {
      call Leds.set(0x3);
    } else if (data >= BATTERYTEST_2_2V) {
      call Leds.set(0x1);
    }

    if (post sendTask()) {
      atomic msgBufBusy = TRUE;
      btMsg->voltage = data;
    }

    return SUCCESS;
  }

  task void sendTask() {
    if (!call SendMsg.send(TOS_BCAST_ADDR, sizeof(uint16_t), &msg)) {
      atomic msgBufBusy = FALSE;
    }
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msgBuf, result_t success) {
    atomic msgBufBusy = FALSE;
    return SUCCESS;
  }
}
