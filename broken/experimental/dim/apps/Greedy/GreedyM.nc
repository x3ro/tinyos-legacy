
module GreadyApp {
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
  uint16_t pktData;
  uint16_t *recvData;
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
    sending = 0;
    pktData = (uint16_t *)pkt.data;
    myCoord = Address[TOS_LOCAL_ADDRESS];
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call GreedyCtrl.start();
    call PktTimer.start(TIMER_REPEAT, 2000);
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
    else {
      if (sending == 0) {
        sending = 1;
        random = call PktRandom.rand();
        if (random % 100 >= 50) {
          dst = Address[random % MAX_NODE_NUM];
          pktData = random;
          dbg(DBG_USR1, "Send data %d to (%d, %d)\n", random, dst.x, dst.y);
          if (call Greedy.send(dst, 2, (void *)&pktData) == FAIL) {
            err ++;
          }
        }
      }
    }
    return SUCCESS;
  }

  event result_t Greedy.sent() {
    sending = 0;
    return SUCCESS;
  }

  task void forwardPacket() {
    if (sending > 0) {
      post forwardPacket();
    } else {
      sending = 1;
      ghp = (GreedyHeaderPtr)&(fpkt->data);
      recvData = (int *)((char *)fpkt->data + sizeof(GreedyHeader));
      if (call Greedy.send(ghp->coord_, 2, (void *)recvData) == FAIL) {
        err ++;
      }
    }
  }
  
  event result_t Greedy.recv(TOS_MsgPtr rawMsg) {
    ghp = (GreedyHeaderPtr)&(rawMsg->data);
    recvData = (int *)((char *)rawMsg->data + sizeof(GreedyHeader));
    if (ghp->coord_ == myCoord) {
      // This packet is destined for me, Absorb it.
      dbg(DBG_USR1, "Received data %d from %d\n", *recvData, ghp->src_addr_);
    }
    else {
      // This packet is destined for somebody else, Forward it.
      memcpy(&fpkt, rawMsgm, sizeof(TOS_Msg));
      post forwardPacket();
    }
    return SUCCESS;
  }
}
