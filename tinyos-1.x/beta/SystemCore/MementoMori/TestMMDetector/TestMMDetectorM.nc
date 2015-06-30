module TestMMDetectorM {
  provides {
    interface StdControl;

    interface TimeSyncAuthority;

    // Bridge the two
    interface PiggyBack;
    interface HeartBeatHandler;

    interface RouteControl as DummyRC;
    interface SourceAddress as DummySA;
  }

  uses {
    interface Timer;

    interface RouteControl;

    interface SourceAddress;
  }
}
implementation {

  command result_t StdControl.init() {

    return SUCCESS;
  }

  command result_t StdControl.start() {


    return SUCCESS;
  }

  command result_t StdControl.stop() {

    return SUCCESS;
  }

  event result_t Timer.fired() {

    return SUCCESS;
  }

  command bool TimeSyncAuthority.isAuthoritative(uint16_t addr) {

    if (addr == call RouteControl.getParent()) {
      dbg(DBG_USR1, 
	  "Round AUTH: srcAddr = %u (parent node %u, depth %u)\n",
	  addr,
	  call RouteControl.getParent(),
	  call RouteControl.getDepth());

      return TRUE;
    } else {
      return FALSE;
    }
  }

  command uint32_t HeartBeatHandler.getPeriod() {
    return 2048;
  }
  
  command bool PiggyBack.piggySuppress(TOS_MsgPtr msg,
				       uint8_t *buf,
				       uint8_t lenRemaining) {
    
    return FALSE;
  }

  command result_t PiggyBack.piggySend(TOS_MsgPtr msg,
				       uint8_t *buf,
				       uint8_t *len,
				       uint8_t lenRemaining) {

    dbg(DBG_USR1, "* Sending hb as alive\n\n");

    return SUCCESS;
  }

  command result_t PiggyBack.piggyReceive(TOS_MsgPtr msg,
					  uint8_t *buf,
					  uint8_t lenRemaining) {

    signal HeartBeatHandler.receiveHeartBeat(call SourceAddress.getAddress(msg),
					     NULL);

    return SUCCESS;
  }

  command uint16_t DummyRC.getParent() {
    return 0xFFFF;
  }

  command uint8_t DummyRC.getDepth() {
    return 0xFF;
  }

  command uint16_t DummyRC.getSender(TOS_MsgPtr msg) {
    return 0xFFFF;
  }

  command uint8_t DummyRC.getOccupancy() {
    return 0;
  }          

  command uint8_t DummyRC.getQuality() {
    return 0;
  }
 
  command result_t DummyRC.setUpdateInterval(uint16_t Interval) {
    return SUCCESS;
  }

  command result_t DummyRC.manualUpdate() {
    return SUCCESS;
  }

  command uint16_t DummySA.getAddress(TOS_MsgPtr msg) {
    return 0xFFFF;
  }
}
