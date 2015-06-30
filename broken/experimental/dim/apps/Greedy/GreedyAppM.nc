includes Greedy;
includes GreedyApp;

module GreedyAppM {
  provides {
    interface StdControl;
  }
  uses {
    interface StdControl as GreedyCtrl;
    interface Greedy;
    interface Leds;
    interface Timer as PktTimer;
    interface Random as PktRandom;
  }
}

implementation {
  TOS_Msg pkt, fpkt;
  uint8_t err, sending;
  uint16_t random;
  uint16_t *pktData;
  uint16_t *recvData;
  uint16_t pktSeqNo;
  GreedyHeaderPtr ghp;
  Coord dst, myCoord;
  
  void reportErr() {
    call Leds.redToggle();
    call Leds.yellowToggle();
    call Leds.greenToggle();
  }

  command result_t StdControl.init() {
    call Leds.init();
    call PktRandom.init();
    call GreedyCtrl.init();
    err = 0;
    pktData = (uint16_t *)&(pkt.data);
    myCoord = Address[TOS_LOCAL_ADDRESS];
    pktSeqNo = 0;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call GreedyCtrl.start();
    call PktTimer.start(TIMER_REPEAT, 10000);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call PktTimer.stop();
    call GreedyCtrl.stop();
    return SUCCESS;
  }

  event result_t PktTimer.fired() {
    if (err) {
      reportErr();
    }
    else if (pktSeqNo == 0xffff) {
      return SUCCESS;
    }
    else {
      random = call PktRandom.rand();
      //dbg(DBG_USR2, "Generate random number %hd\n", random);
      if ((random % 100 >= 50) && ((random % MAX_NODE_NUM) != TOS_LOCAL_ADDRESS)) {
        dst = Address[random % MAX_NODE_NUM];
        // *pktData = random;
        dbg(DBG_USR2, "SEND [%hd] %hd to %hd/(%hd, %hd)\n", pktSeqNo, random, random%MAX_NODE_NUM, dst.x, dst.y);
        *pktData = TOS_LOCAL_ADDRESS;
        *(pktData + 1) = pktSeqNo ++;
        *(pktData + 2) = random;
        if (call Greedy.send(dst, 6, (void *)pktData) == FAIL) {
          err ++;
        }
        //dbg(DBG_USR2, "call Greedy.send() done\n");
      }
    }
    return SUCCESS;
  }

  event result_t Greedy.recv(TOS_MsgPtr rawMsg) {

    //dbg(DBG_USR2, "message pushed from the router\n");
    
    ghp = (GreedyHeader *)(&(rawMsg->data));
    if (ghp->mode_ == BEACON) {
      // Do nothing with beacons.
      return SUCCESS;
    }
    
    recvData = (uint16_t *)((char *)ghp + sizeof(GreedyHeader));
    if (ghp->coord_.x == myCoord.x && ghp->coord_.y == myCoord.y) {
      // This packet is destined for me, Absorb it.
      dbg(DBG_USR2, "ABSORB [%hd] %hd from %hd\n", *(recvData + 1), *(recvData + 2), *recvData);
    }
    else {

    //dbg(DBG_USR2, "not for me\n");
      dbg(DBG_USR2, "FORWARD [%hd] %hd from %hd\n", *(recvData + 1), *(recvData + 2), *recvData);

      // This packet is destined for somebody else, Forward it.
      if (call Greedy.send(ghp->coord_, 6, (void *)recvData) == FAIL) {
        err ++;
      }
    }

    //dbg(DBG_USR2, "forward done\n");
    
    return SUCCESS;
  }
}
