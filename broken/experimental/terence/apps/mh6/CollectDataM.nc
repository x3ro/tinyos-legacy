/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: CollectDataM.nc,v 1.6 2003/03/04 23:43:59 wetoasis Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * This is an example of a general applicaiton using the Routing Stack to send message to
 * basestation. It store a message in its frame, call getUsablePortion to get the right location
 * to add in its own data. passed the data down the stack with the send command. A Send done
 * command will come back. A recomment way to send another message is to have a one shot
 * Time. When the clock fired, we make another attemp to send again
 * author: Terence Tong, Alec Woo
 */
/*////////////////////////////////////////////////////////*/
includes RoutingStackShared;

module CollectDataM {
  provides {
    interface StdControl;
  }
  uses {
    interface MultiHopSend as MultiHopSend;
    interface Timer as Timer;
    interface Leds;
    interface HandleBcast;
  }
}

implementation {

  TOS_Msg msgToSend;

  struct DataFormat_t {
    uint8_t addr;
    uint8_t cnt;
  };
  uint8_t counter;
  uint8_t sending;
  command result_t StdControl.init() {
    return SUCCESS;
  }
  command result_t StdControl.start() {
    int i;
    counter = 0;
    for (i = 0; i < 29; i++) {
      msgToSend.data[i] = 0;
    }
    call Timer.start(TIMER_REPEAT, DATA_FREQ);
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  /*////////////////////////////////////////////////////////*/
  /**
   * When the clock fired we are ready to send, collectdata ask the stack 
   * where in the data payload we can safely put our data. We then call 
   * Multihop passed the pointer down the stack
   * @author: terence
   * @param: void  
   * @return: always return success
   */
  event result_t Timer.fired() {
    uint8_t result;
    // struct DataFormat_t *dataPortion;
    uint8_t *dataPortion;
    struct DataFormat_t *df;
    if (sending == 1) return SUCCESS;
    dataPortion = call MultiHopSend.getUsablePortion(msgToSend.data);
    df = (struct DataFormat_t *) dataPortion;
    df->addr = TOS_LOCAL_ADDRESS;
    df->cnt = counter++;
    sending = 1;

    result = call MultiHopSend.send(&msgToSend, sizeof(struct DataFormat_t));
    return SUCCESS;

  }

  /*////////////////////////////////////////////////////////*/
  /**
   * When a message is sent, send done event is trigger. We then schedule the
   * time to generate another message to send
   * @author: terence
   * @param: void 
   * @return: void
   */

  event void MultiHopSend.sendDone(TOS_MsgPtr msg, uint8_t success) {
    sending = 0;
  }

  event void HandleBcast.execute(TOS_MsgPtr msg) {
    //    uint8_t *cmdmsg = call HandleBcast.extractData(msg);
    // do whatever we want to this message 
  }
}
