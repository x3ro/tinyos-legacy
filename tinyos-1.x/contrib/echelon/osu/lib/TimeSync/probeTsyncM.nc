includes Beacon;

module probeTsyncM
{
  provides interface StdControl;
  uses {
    interface StdControl as CommControl;
    interface StdControl as AlarmControl;
    interface SendMsg; 
    interface Leds;
    interface Alarm;
  }
}
implementation
{

  /* Buffers, switches, etc */
  TOS_Msg msg;        // used only for send
  bool msgFree;
  uint16_t count;     // counter on each probe msg

  command result_t StdControl.init() {
    call CommControl.init();
    call AlarmControl.init();
    msgFree = TRUE;
    count = 0;
    return SUCCESS;
    }

  command result_t StdControl.start() {
    call CommControl.start();
    call AlarmControl.start();
    call Alarm.set(1,10);
    call Alarm.set(0,10);
    return SUCCESS;
    }

  command result_t StdControl.stop() {
    call CommControl.stop();
    call Alarm.clear();
    call AlarmControl.stop();  // ? This is questionable
    return SUCCESS;
    }

  task void launch() {
    beaconProbeMsgPtr p;
    if (!msgFree) return;
    msgFree = FALSE;
    p = (beaconProbeMsgPtr) msg.data;
    p-> count = count++;
    call SendMsg.send(TOS_BCAST_ADDR, sizeof(beaconProbeMsg), &msg); 
    call Leds.redToggle();
    }

  task void mainTask() {
    // schedule probe and restart 
    call Alarm.set(1,10);
    call Alarm.set(0,10);
    }

  event result_t SendMsg.sendDone(TOS_MsgPtr sent, result_t success) {
    msgFree = TRUE;
    return SUCCESS;
    }
 
  /**
   * Alarm wakeup.  Here's where we use the index feature of wakeups
   * to post the appropriate task for the event.  
   * @author herman@cs.uiowa.edu
   */
  event result_t Alarm.wakeup(uint8_t indx, uint32_t wake_time) {
    switch (indx) {
      case 0: post mainTask(); break;
      case 1: post launch(); break;
      }
    return SUCCESS;
    }

}

