includes Greedy;
/*
* Three message buffers are used; sendMsg is for sending, recvMsg
* is for receiving, and pSendMsg is for pending outbound message.
* Suppose message sending/forwarding frequence is not high; 
* otherwise, we have to use a queue to hold outbound messages.
*/

/*
 * Need a beacon queue in case multiple beacon arrives at the same
 * time as well as data packets.
 */
/*
#define BEACON_INTERVAL 2000
#define BEACON_JITTER 1000
#define ROUTER_NIL 0xff
#define ROUTER_READY 0
#define ROUTER_BUSY 1
*/
module GreedyM {
  provides {
    interface StdControl;
    interface Greedy;
  }
  uses {
    interface StdControl as RouterCtrl;
    interface Timer as BeaconTimer;
    interface SendMsg as RouterSend;
    interface ReceiveMsg as RouterRecv;
    //interface Leds;
  }
}

implementation {
  Coord myCoord;
  TOS_Msg sendMsg, recvMsg, pSendMsg, beaconMsg;
  //uint16_t interval;
  uint8_t routerSendSt;
  uint8_t routerErr;
  Neighb ne;
  Neighb neTab[MAX_NEIGHBNUM];
  uint8_t neNum;
  bool pendingSend;
  
  command result_t StdControl.init() {
    GreedyHeaderPtr gh;

    myCoord = Address[TOS_LOCAL_ADDRESS];

    gh = (GreedyHeaderPtr)(beaconMsg.data);
    gh->mode_ = BEACON;
    gh->src_addr_ = TOS_LOCAL_ADDRESS;
    gh->coord_ = myCoord;
    
    pendingSend = FALSE;

    routerErr = 0;
    routerSendSt = ROUTER_NIL;
    //interval = BEACON_INTERVAL;
    neNum = 0;

    //call Leds.init();
    call RouterCtrl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call RouterCtrl.start();
    call BeaconTimer.start(TIMER_REPEAT, BEACON_INTERVAL);
    routerSendSt = ROUTER_READY;
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    routerSendSt = ROUTER_NIL;
    call BeaconTimer.stop();
    call RouterCtrl.stop();
    return SUCCESS;
  }

#if 0
  void nextHopLeds(uint16_t nextHop) 
  {
    call Leds.redOff();
    call Leds.greenOff();
    call Leds.yellowOff();

    if (nextHop & 0x01) { call Leds.redOn(); }
    if (nextHop & 0x02) { call Leds.greenOn(); }
    if (nextHop & 0x04) { call Leds.yellowOn(); }
  }
#endif
  
  void reportError() 
  {
#if 0
    call Leds.redToggle();
    call Leds.greenToggle();
    call Leds.yellowToggle();
#endif
  }

  event result_t BeaconTimer.fired() {
    uint8_t beaconGo;

    if (routerErr) {
      reportError();
    } else {

#if 1
    if (routerSendSt == ROUTER_READY && !routerErr) {
      atomic {
        routerSendSt = ROUTER_BUSY;
        beaconGo = 1;
      }
    } else if (routerSendSt == ROUTER_BUSY) {
      atomic {
        beaconGo = 0;
      } 
    } else {
      atomic {
        beaconGo = 0xff;
      }
    }
#endif

#if 1
    if (beaconGo == 1) {
      // dbg(DBG_USR2, "BEACONING\n");
      
      //call Leds.greenToggle();
      
      if (call RouterSend.send(TOS_BCAST_ADDR, sizeof(GreedyHeader), &beaconMsg) == FAIL) {
        // Sending beacon failed
        dbg(DBG_USR2, "FAILED TO BEACON\n");
        routerErr ++;
      } 
    } else {
      // Skip this beaconing
      dbg(DBG_USR2, "\nSSSSSSSSSSSSSSSSSSSKIP BEACONING\n\n");
    } 
#endif
    }
    return SUCCESS;
  }

  /*
  * Parameter dst is the end-to-end destination. Parameter buf does
  * contain the GreedyHeader which has been filled in by PIR shim.
  * No need of source as it has been set up in *buf*.
  */
  command result_t Greedy.send(Coord dst, uint8_t len, uint8_t *buf) {
    uint32_t minDistance;
    uint32_t curDistance;
    GreedyHeaderPtr gh;
    uint8_t greedyGo;
    uint16_t dest_addr_;
    uint8_t i, nextHopPtr;

    //dbg(DBG_USR2, "Greedy.send() called with dst = (%x, %x)\n", dst.x, dst.y);

    if (routerErr || routerSendSt == ROUTER_NIL) {
      dbg(DBG_USR2, "GreedyM.nc: Greedy.send(): ROUTER OUT OF SERVICE!\n");
      return FAIL;
    }
    gh = (GreedyHeaderPtr)buf;
    if (gh->mode_ > GREEDY) {
      dbg(DBG_USR2, "Deliver to console!\n");

      //call Leds.yellowToggle();
    
      dest_addr_ = TOS_UART_ADDR;
    } else if (dst.x == 0xffff && dst.y == 0xffff) {
      // Broadcast

      //call Leds.redToggle();
    
      dbg(DBG_USR2, "Broadcast\n");
      dest_addr_ = TOS_BCAST_ADDR;
    } else {
      //dbg(DBG_USR2, "Forward to location (%d, %d)\n", dst.x, dst.y);

      //call Leds.greenToggle();

      if (neNum == 0) {
        // I am an isolated node. Do nothing.
        dbg(DBG_USR2, "NO NEIGHBORS, GIVE UP SENDING!\n");
        return NO_ROUTE;
      }
    
      /*
      * Pick the best next hop in terms of coordinates.
      */
      minDistance = (myCoord.x - dst.x) * (myCoord.x - dst.x) +
                    (myCoord.y - dst.y) * (myCoord.y - dst.y);
      //dbg(DBG_USR2, "minDistance  = %d\n", minDistance);
    
      nextHopPtr = 0xff;
      for (i = 0; i < neNum; i ++) {
        if (neTab[i].coord_.x == dst.x && neTab[i].coord_.y == dst.y) {
          // The destination is my neighbor, choose it as the next hop.
          //dbg(DBG_USR2, "One hop from the destination %hd\n", np->addr_);
          nextHopPtr = i;
          break;
        } else {
          curDistance = (neTab[i].coord_.x - dst.x) * (neTab[i].coord_.x - dst.x) +
                        (neTab[i].coord_.y - dst.y) * (neTab[i].coord_.y - dst.y);
          //dbg(DBG_USR2, "curDistance  = %d\n", curDistance);
          if (curDistance < minDistance) {
            minDistance = curDistance;
            nextHopPtr = i;
          }
        }
      }
      if (nextHopPtr == 0xff) {
        // No neighbor is closer to the destination than me.
        //dbg(DBG_USR2, "GREEDY FAILED ON PACKET #%hd from %hd to (%hd, %hd)!!!\n", 
        //              gh->seqno_, gh->src_addr_, dst.x, dst.y);
        //signal Greedy.sendDone(SUCCESS);
        return NO_ROUTE;
      } else {
        dest_addr_ = neTab[nextHopPtr].addr_;
        //dbg(DBG_USR2, "pick best neighbor %hd\n", dest_addr_);
      }
    }

    if (routerSendSt == ROUTER_BUSY) {
      atomic {
        greedyGo = 0;
      }
    } else {
      atomic {
        routerSendSt = ROUTER_BUSY;
        greedyGo = 1;
      }
    }
    if (greedyGo == 0) {
    
      //call Leds.redToggle();

      // Router is busy sending another packet, pending this one.
      // Copy the entire buf, since it has the GreedyHeader already.
      
      memcpy(pSendMsg.data, buf, len);
      /*
      if (dest_addr_ != TOS_UART_ADDR) {
        gh = (GreedyHeaderPtr)(pSendMsg.data);
        gh->mode_ = GREEDY;
      }
      */
      pSendMsg.length = len;
      pSendMsg.addr = dest_addr_;
      pendingSend = TRUE; 
    } else {
      memcpy(sendMsg.data, buf, len);
      /*
      if (dest_addr_ != TOS_UART_ADDR) {
        gh = (GreedyHeaderPtr)sendMsg.data;
        gh->mode_ = GREEDY;
      }
      */
      //nextHopLeds(dest_addr_);

      if (call RouterSend.send(dest_addr_, len, &sendMsg) == FAIL) {
        //call Leds.yellowOn();
        //call Leds.redOn();
        //call Leds.greenOn();

        routerErr ++;
        dbg(DBG_USR2, "Cannot send to %d!\n", dest_addr_);
        return FAIL;
      }//}
    }
    return SUCCESS;
  }
      
  task void sendPending() {
    //memcpy(&sendMsg, &pSendMsg, sizeof(TOS_Msg));
    atomic {
      sendMsg = pSendMsg;
      pendingSend = FALSE;
    }
    if (call RouterSend.send(sendMsg.addr, sendMsg.length, &sendMsg) == FAIL) {
      dbg(DBG_USR2, "FAILED TO SEND USER DATA\n");
      routerErr ++;
    }
  }
    
  event result_t RouterSend.sendDone(TOS_MsgPtr msg, result_t success) {
    GreedyHeaderPtr gh = (GreedyHeaderPtr)(msg->data);
    
    /*
    if (gh->mode_ != BEACON) {
      if (msg->length != (sizeof(DimCreateMsg) + sizeof(GreedyHeader))) {
        call Leds.yellowToggle();
      } else {
        call Leds.redToggle();
      }
    }
    */

    if (success != SUCCESS) {
      dbg(DBG_USR2, "RouterSend.sendDone() return FAIL\n");
    } else {
      /*
      if (gh->mode_ != BEACON) {
        signal Greedy.sendDone(success);
      }
      */
      if (pendingSend) {
        post sendPending();
      } else {
        atomic {
          routerSendSt = ROUTER_READY;
        }
        if (gh->mode_ != BEACON) {
          signal Greedy.sendDone(success);
        }
      }
    }
    return SUCCESS;
  }

  event TOS_MsgPtr RouterRecv.receive(TOS_MsgPtr msg) {
    GreedyHeaderPtr gh = (GreedyHeaderPtr)(msg->data);

    if (gh->mode_ == BEACON) {
      uint8_t i;
      for (i = 0; i < MAX_LINK_NUM; i ++) {
        if ((NeighbHood[i].x == TOS_LOCAL_ADDRESS && NeighbHood[i].y == gh->src_addr_) |
            (NeighbHood[i].x == gh->src_addr_ && NeighbHood[i].y == TOS_LOCAL_ADDRESS)) {
          break;
        }
      }
      if (i == MAX_LINK_NUM) {
        // Should ignore this neighbor.
        return msg;
      }

      
      for (i = 0; i < neNum; i ++) {
        if (neTab[i].addr_ == gh->src_addr_) {
          // This neighbor has been identified.
          return msg;
        }
      }

      // This is a new neighbor
      dbg(DBG_USR2, "Found a new neighbor %d at (%d, %d)\n", gh->src_addr_, gh->coord_.x, gh->coord_.y);
      neTab[neNum].addr_ = gh->src_addr_;
      neTab[neNum].coord_ = gh->coord_;
      neNum ++;
    } 

    signal Greedy.recv(msg);
    /*
    if (gh->mode_ != BEACON) {
      uint8_t i;
      for (i = 0; i < sizeof(TOS_Msg); i ++) {
        dbg(DBG_USR2, "::%x ", (uint8_t)((char *)msg)[i]);
      }
      dbg(DBG_USR2, "\n");
    }
    */
    return msg;
  }
}
