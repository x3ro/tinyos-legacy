#define BEACON_INTERVAL 1000
#define BEACON_JITTER 1000
module BeaconM {
  uses {
    interface StdControl as BeaconComm;
    interface Timer as BeaconTimer;
    interface SendMsg as BeaconSend;
    interface ReceiveMsg as BeaconRcv;
    interface Random as BeaconRandom; 
  }
  provides {
    interface StdControl;
    interface Beacon;
  }
}
implementation {
  uint8_t sendingBeacon;
  TOS_Msg beaconMsg;
  Coord myCoord, *beaconData;
  uint16_t jitter;
  uint16_t interval;
  
  command result_t StdControl.init() {
    call BeaconComm.init();
    call BeaconRandom.init();
    sendingBeacon = 0;
    interval = BEACON_INTERVAL;
    jitter = BEACON_JITTER;
    myCoord = Address[TOS_LOCAL_ADDRESS];
    beaconData = (CoordPtr)(beaconMsg.data);
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call BeaconComm.start();
    call BeaconTimer.start(TIMER_ONE_SHOT, interval + call BeaconRandom.rand() % jitter);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call BeaconTimer.stop();
    call BeaconComm.stop();
    return SUCCESS;
  }

  event result_t BeaconTimer.fired() {
    if (!sendingBeacon) {
      sendingBeacon = 1;
      beaconData->x = myCoord.x;
      beaconData->y = myCoord.y;
      if (call BeaconSend.send(TOS_BCAST_ADDR, sizeof(Coord), &beaconMsg) == FAIL) {
        sendingBeacon = 0;
      } 
    }

    call BeaconTimer.start(TIMER_ONE_SHOT, interval + call BeaconRandom.rand() % jitter);

    return SUCCESS;
  }

  command result_t Beacon.setTimer(int16_t bint, int16_t bjit) {
    interval = bint;
    jitter = bjit;
    return SUCCESS;
  }

  command result_t Beacon.getCoord(CoordPtr coordPtr) {
    coordPtr->x = myCoord.x;
    coordPtr->y = myCoord.y;
    return SUCCESS;
  }

  event result_t BeaconSend.sendDone(TOS_MsgPtr msg, result_t success) {
    sendingBeacon = 0;
    // dbg(DBG_USR1, "SENT: coordPtr->x = %d coordPtr->y = %d jitter = %d\n", coordPtr->x, coordPtr->y, jitter);
    signal Beacon.sent(msg, success);
    return SUCCESS;
  }

  event TOS_MsgPtr BeaconRcv.receive(TOS_MsgPtr msg) {
    // dbg(DBG_USR1, "RCVED: coordPtr->x = %d coordPtr->y = %d\n", coordPtr->x, coordPtr->y);
    signal Beacon.arrive(msg);
    return msg;
  }
}
