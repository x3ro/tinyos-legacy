/*
emit message 
  every n msecs
  on a beacon message id
  with a unique id
  with a time stamp

receive message
  delay m ticks
  record id and time stamp
  send to parent
*/

includes RFTag;

module RFTagM {
  provides interface StdControl;
  uses {
    interface StdControl as RadioControl;
    interface SendMsg as Send;
    // interface Pot;
    interface Random;

    interface Leds;
    interface Timer;
    interface CC1000Control;
  }
}

implementation {
  enum {
    MAX_PAYLOAD  = 29,
  };

  TOS_Msg tag_packet;

  long time;

  command result_t StdControl.init() {
    time = 0;
    call CC1000Control.SetRFPower(1);
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Leds.greenToggle();
    // call Timer.start(TIMER_REPEAT, 64); // tick16ps
    call Timer.start(TIMER_REPEAT, 16*64); // tick16ps
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
    return success;
  }

  event result_t Timer.fired() {
    tag_msg* msg = (tag_msg*)tag_packet.data;
    call Leds.redToggle();
    msg->id   = TOS_LOCAL_ADDRESS;
    msg->time = time++;
    call Send.send(TOS_BCAST_ADDR, MAX_PAYLOAD, &tag_packet);
    return SUCCESS;
  }

}

