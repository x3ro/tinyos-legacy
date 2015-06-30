module ZoneAppM {
  provides {
    interface StdControl;
  }
  uses {
    interface StdControl as BeaconControl;
    interface Zone;
    interface Beacon;
    interface Leds;
  }
}
implementation {
  uint16_t networkBound[4];
  Coord myCoord, *coordPtr, coord;
  Code myCode;
  
  command result_t StdControl.init() {
    call Leds.init();
    call BeaconControl.init();
    
    networkBound[0] = 0;
    networkBound[1] = MAXX;
    networkBound[2] = 0;
    networkBound[3] = MAXY;

    dbg(DBG_USR1, "ZoneAppM.StdControl.init()\n");

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call BeaconControl.start();
    call Beacon.getCoord(&myCoord);
    call Zone.init(myCoord, networkBound);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call BeaconControl.stop();
    return SUCCESS;
  }

  event result_t Beacon.sent(TOS_MsgPtr msg, result_t success) {
    call Leds.yellowToggle();
    call Zone.getCode(&myCode);  
    dbg(DBG_USR1, "my zone code is %x(%d)\n", myCode.word, myCode.length);
    return SUCCESS;
  }

  event result_t Beacon.arrive(TOS_MsgPtr msg) {
    call Leds.greenToggle();
    coordPtr = (CoordPtr)(msg->data);
    coord.x = coordPtr->x;
    coord.y = coordPtr->y;
    dbg(DBG_USR1, "call Zone.adjust((%d, %d))\n", coord.x, coord.y);
    call Zone.adjust(coord);
    return SUCCESS;
  }
}
