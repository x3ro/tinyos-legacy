// $Id: FloatMsgSenderM.nc,v 1.1 2007/04/05 07:58:05 chien-liang Exp $

/**
 * @author Chien-Liang Fok
 */

includes FloatMsg;


module FloatMsgSenderM
{
  provides interface StdControl;
  uses {
    interface Timer;
    interface Leds;
    interface StdControl as CommControl;
    interface SendMsg as DataMsg;
  }
}
implementation
{
  TOS_Msg msg;
  float x;

  /**
   * Used to initialize this component.
   */
  command result_t StdControl.init() {
    call Leds.init();
    call Leds.yellowOff(); call Leds.redOff(); call Leds.greenOff();
    call CommControl.init();
    return SUCCESS;
  }

  /**
   * Starts the CommControl components and a timer that fires 1 per second..
   * @return Always returns SUCCESS.
   */
  command result_t StdControl.start() {
    x = 0;
    call Timer.start(TIMER_REPEAT, 1024);
    call CommControl.start();
    return SUCCESS;
  }

  /**
   * Stops the SensorControl and CommControl components.
   * @return Always returns SUCCESS.
   */
  command result_t StdControl.stop() {
    call Timer.stop();
    call CommControl.stop();
    return SUCCESS;
  }

  task void dataTask() {
    struct FloatMsg *fm;
    atomic {
      fm = (struct FloatMsg *)msg.data;
      fm->f = x;
    }
    x += 0.25;
    
    /* Try to send the packet. Note that this will return
     * failure immediately if the packet could not be queued for
     * transmission.
     */
    if (call DataMsg.send(TOS_UART_ADDR, sizeof(struct FloatMsg), &msg))
      {
        call Leds.greenToggle();
      } else call Leds.redToggle();
  }
  
 

  /**
   * Signalled when the clock ticks.
   * @return The result of calling ADC.getData().
   */
  event result_t Timer.fired() {
    return post dataTask();
  }
  
  /**
   * Signalled when the previous packet has been sent.
   * @return Always returns SUCCESS.
   */
  event result_t DataMsg.sendDone(TOS_MsgPtr sent, result_t success) {
    return SUCCESS;
  }
}
