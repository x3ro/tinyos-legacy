module TestTimeSyncM {
  provides {
    interface StdControl;
    interface TimeSyncAuthority;
  }
  uses {
    interface RouteControl;
    interface Time;
    interface TimeSetListener;
    interface TimeSync;

    interface Leds;

    interface EpochScheduler as Epoch;

  }
} 
implementation {

  command result_t StdControl.init() {
    dbg(DBG_USR1, "StdControl: init\n");

    return SUCCESS;
  }

  command result_t StdControl.start() {
    dbg(DBG_USR1, "StdControl: start\n");

    call Epoch.addSchedule(2048, 1024);
    call Epoch.start();

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    dbg(DBG_USR1, "StdControl: stop\n");

    return SUCCESS;
  }

  event void Epoch.beginEpoch() {

    dbg(DBG_USR1, "* BEGIN at %lu\n", call Time.getLow32());

    call Leds.greenOn();
  }

  event void Epoch.epochOver() {

    dbg(DBG_USR1, "* END at %lu\n", call Time.getLow32());

    call Leds.greenOff();
  }


  command bool TimeSyncAuthority.isAuthoritative(uint16_t addr) {

    dbg(DBG_USR1, "AUTH = (parent node %u, depth %u)\n",
	call RouteControl.getParent(),
	call RouteControl.getDepth());

    return (call RouteControl.getDepth() == 0 ||
	    call RouteControl.getParent() == addr);
  }

  event void TimeSetListener.timeAdjusted(int64_t msTicks) {
    dbg(DBG_USR1, "TSL: Time adjusted by %lld\n", msTicks); 

    dbg(DBG_USR1, "TSL:  Confidence is now %lu\n", 
	call TimeSync.getConfidence());
  }

}
