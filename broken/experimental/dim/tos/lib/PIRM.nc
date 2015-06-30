#define COMM_NIL 0xff
#define COMM_READY 0
#define COMM_BUSY 1

/** 
 * No fragmentation consideration for now, i.e. assume
 * every DIM message can be fitted into a TOS_Msg.
 */
/**
 * A Protocol Independent Routing shim. It provides an interface
 * between TOS messages and user specific messages such as tuple,
 * and queries. Sending queue and receiving queue which previously
 * were handled by user applications are now moved here.
 */
module PIRM {
  provides {
    interface StdControl;
    interface PIR;
  }
  uses {
    interface StdControl as PIRControl;
    interface Greedy;
  }
}

implementation {
  TOS_Msg msgRecvQ[MAX_QLENGTH], msgSendQ[MAX_QLENGTH];
  uint8_t msgSendQHead, msgSendQTail;
  uint8_t msgRecvQHead, msgRecvQTail;
  uint8_t msgSeqNo;
  uint8_t sendingBusy;
  
  command result_t StdControl.init() {
    msgSendQHead = 0;
    msgSendQTail = 0;
    msgRecvQHead = 0;
    msgRecvQTail = 0;
    msgSeqNo = 0;
    sendingBusy = 0;
    
    call PIRControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return call PIRControl.start();
  }

  command result_t StdControl.stop() {
    return call PIRControl.stop();
  }

  void task sending();

  /**
   * *msg* contains pure user data. *len* <= TOSH_DATA_LENGTH - sizeof(GreadyHeader);
   */
  command result_t PIR.send(uint16_t saddr, Coord dest, uint8_t len, uint8_t *msg) {
    GreedyHeaderPtr gh;

    //dbg(DBG_USR2, "PIR.send() called\n");
    
    if (len > TOSH_DATA_LENGTH - sizeof(GreedyHeader)) {
      dbg(DBG_USR2, "Sorry, I am unable to deliver such large message yet\n");
      return FAIL;
    }
    // Enqueue and do fragmentation if needed
    if ((msgSendQTail + 1) % MAX_QLENGTH == msgSendQHead) {
      // Sending queue is full.
      dbg(DBG_USR2, "PIR sending queue is full!\n");
      return FAIL;
    }
    atomic {
      msgSendQ[msgSendQTail].length = len + sizeof(GreedyHeader);
      gh = (GreedyHeaderPtr)(msgSendQ[msgSendQTail].data);
      gh->mode_ = GREEDY;
      gh->src_addr_ = saddr;
      gh->coord_ = dest;
      gh->seqno_ = (msgSeqNo ++) % 256;
      memcpy(gh->data_, msg, len);
      msgSendQTail = (msgSendQTail + 1) % MAX_QLENGTH;
      
      //dbg(DBG_USR2, "PIR.send(): msgSendQHead = %d, msgSendQTail = %d\n", msgSendQHead, msgSendQTail);
    }

    if (sendingBusy == 0) {
      atomic {
        sendingBusy = 1;
      }
      post sending();
    }
    return SUCCESS;
  }

  void task sending() {
    GreedyHeaderPtr gh;

    if (!(msgSendQHead == msgSendQTail)) {
      // Send queue is not empty
      gh = (GreedyHeaderPtr)(msgSendQ[msgSendQHead].data);
      // Greedy.send() deals with TOS_Msg packets
      //dbg(DBG_USR2, "task sending() calls Greedy.send()!\n");
      if (call Greedy.send(gh->coord_, msgSendQ[msgSendQHead].length, (uint8_t *)gh) == FAIL) {
        dbg(DBG_USR2, "Invocation of Greedy.send() failed!\n");
      }
    }
  }

  event result_t Greedy.sendDone(result_t success) {
    if (success != SUCCESS) {
      dbg(DBG_USR2, "Greeady.sendDone() failed!\n");
    } else {
      // Dequeue
      atomic {
        msgSendQHead = (msgSendQHead + 1) % MAX_QLENGTH;
      }
      /*
      if (TOS_LOCAL_ADDRESS == 1) {
        dbg(DBG_USR2, "Greedy.sendDone(): msgSendQHead = %d, msgSendQTail = %d\n", msgSendQHead, msgSendQTail);
      } 
      */
      if (!(msgSendQHead == msgSendQTail)) {
        // Keep sending if sending queue is not empty.
        post sending();
      } else {
        atomic { sendingBusy = 0; }
      }
    }
    return success;
  }

  void task receiving();

  event result_t Greedy.recv(TOS_MsgPtr rawMsg)
  {
    //dbg(DBG_USR2, "Greedy.recv() captured!\n");
    
    // Enqueue
    if ((msgRecvQTail + 1) % MAX_QLENGTH == msgRecvQHead) {
      // Receiving queue is full.
      dbg(DBG_USR2, "PIR receiving queue is full!\n");
      return FAIL;
    }
    atomic {
      msgRecvQ[msgRecvQTail] = *rawMsg;
      msgRecvQTail = (msgRecvQTail + 1) % MAX_QLENGTH;
      //dbg(DBG_USR2, "msgRecvQTail = %d\n", msgRecvQTail);
    }
    post receiving();
    return SUCCESS;
  }
  
  void java2tos(TOS_MsgPtr javamsg, TOS_MsgPtr tosmsg, uint8_t type);
  
  void task receiving() {
    GreedyHeaderPtr gh;
    TOS_Msg tos;
    uint16_t length;
    
    if (!(msgRecvQHead == msgRecvQTail)) {
      // Receive queue is not emtpy
      gh = (GreedyHeaderPtr)(msgRecvQ[msgRecvQHead].data);
      length = msgRecvQ[msgRecvQHead].length;

      if (gh->mode_ == CONSOLE_QUERY || gh->mode_ == CONSOLE_ZONE) {
        java2tos(&msgRecvQ[msgRecvQHead], &tos, gh->mode_);  
        gh = (GreedyHeaderPtr)(tos.data);
        length = tos.length;
      } else {
        length = msgRecvQ[msgRecvQHead].length;
      }
      
      signal PIR.arrive(gh->src_addr_, gh->coord_, length, (uint8_t *)gh);
      atomic {
        msgRecvQHead = (msgRecvQHead + 1) % MAX_QLENGTH;
      }
      post receiving();
    }
  }

  /*
   * Used for converting console query messages to tos compact format.
   */
  void java2tos(TOS_MsgPtr javamsg, TOS_MsgPtr tosmsg, uint8_t type)
  {
    GreedyHeaderPtr gh = (GreedyHeaderPtr)(tosmsg->data);
    GenericQueryPtr gQueryPtr = (GenericQueryPtr)(gh->data_);
    ConsoleQueryMsgPtr consQueryPtr = (ConsoleQueryMsgPtr)(javamsg->data);
    uint8_t i;

    gh->mode_ = GREEDY;
    // Location (0, 0) stands for console.
    gQueryPtr->issuer.x = 0;
    gQueryPtr->issuer.y = 0;
    if (type == CONSOLE_QUERY) {
      gQueryPtr->type = 'q';
      for (i = 0; i < MAX_FIELDNUM; i ++) {
        gQueryPtr->queryField[i].attrID = consQueryPtr->queryField[i].attrID;
        gQueryPtr->queryField[i].lowerBound = consQueryPtr->queryField[i].lowerBound;
        gQueryPtr->queryField[i].upperBound = consQueryPtr->queryField[i].upperBound;
      }
      dbg(DBG_USR2, "Console Query: %hd %hd <%d:%hd--%hd, %d:%hd--%hd, %d:%hd--%hd, %d:%hd--%hd>\n",
                     gQueryPtr->issuer.x, gQueryPtr->issuer.y,
                     gQueryPtr->queryField[0].attrID, gQueryPtr->queryField[0].lowerBound, gQueryPtr->queryField[0].upperBound,
                     gQueryPtr->queryField[1].attrID, gQueryPtr->queryField[1].lowerBound, gQueryPtr->queryField[1].upperBound,
                     gQueryPtr->queryField[2].attrID, gQueryPtr->queryField[2].lowerBound, gQueryPtr->queryField[2].upperBound,
                     gQueryPtr->queryField[3].attrID, gQueryPtr->queryField[3].lowerBound, gQueryPtr->queryField[3].upperBound
        );
    } else if (type == CONSOLE_ZONE) {
      uint16_t *moteID = (uint16_t *)(gQueryPtr->queryField);
      
      dbg(DBG_USR2, "Console zone inquiry\n");
      gQueryPtr->type = 'z';
      *moteID = consQueryPtr->queryField[0].attrID;
    }
    tosmsg->length = sizeof(GreedyHeader) + sizeof(GenericQuery);
  }
}
