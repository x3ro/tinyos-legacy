/** MULETestM.nc
 *
 * This app sends counter values out over the radio, and tracks the number
 * of packets that have been lost.
 * Probably on works under TOSSIM, which is fine because I don't care if it
 * doesn't work on real motes.
 * 
**/

includes IntMsg;

module MULESendLineM {
  provides interface StdControl;

  uses {
    interface StdControl as CounterControl;
    interface StdControl as Counter2Control;
    interface ReceiveMsg as ReceiveIntMsg;
    interface StdControl as CommControl;
    interface Leds;
  }
} implementation {

  command result_t StdControl.init() {
    call CounterControl.init();
    call Counter2Control.init();
    call Leds.init();
    return call CommControl.init();
  }

  command result_t StdControl.start() {
    if (NODE_NUM == 0) {
      call CounterControl.start();
      call Leds.redOn();
    }
    if (NODE_NUM == tos_state.num_nodes-1) {
      call Counter2Control.start();
      call Leds.yellowOn();
    }
    return call CommControl.start();
  }

  command result_t StdControl.stop() {
    return call CommControl.stop();
  }

  event TOS_MsgPtr ReceiveIntMsg.receive(TOS_MsgPtr m) {
    IntMsg *message = (IntMsg *)m->data;
    int src = message->src;

    dbg(DBG_USR2, "Received from %d\n", src);

    if (src == NODE_NUM -1) {
      call Leds.redOn();
      call CounterControl.start();
    } else if (src == NODE_NUM +1) {
      call Leds.yellowOn();
      call Counter2Control.start();
    }

    return m;
  }

}
