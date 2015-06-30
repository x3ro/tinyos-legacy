module AggressiveSendM {
  provides {
    interface StdControl;

    interface SendMsg[uint8_t id];

    interface AggressiveSendControl;

  }
  uses {
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
    interface MacControl;
#endif

    interface Leds;

    interface SendMsg as SendExt[uint8_t id];
  }
}
implementation {

 // This data structure is imposed onto TOS_Msg
  // following the portion of it that actually
  // gets transmitted.

  // This saves precious resources, as these fields
  // such as the CRC, and signal strength are not even
  // used until the packet enters the
  typedef struct {    
    TOS_Msg *next;

    uint8_t retriesLeft;
    
  } MsgStub;
  
  // Recast the portion of TOS_Msg not used
  // prior to sending the packet into a useful data structure
  MsgStub *getStub(TOS_MsgPtr msg) {
    return (MsgStub *)(((uint8_t *)msg) + MSG_DATA_SIZE);
  }

  // Heads of the queue
  // The queues store freshest items eraliest to be
  // removed first (i.e. headFifoQ points to the next
  // item to be dequeued)
  
  // Head of the FIFO queue fo packets
  TOS_MsgPtr headFifoQ = NULL;


#define AGGRESSIVE_INIT_RETRIES 2

  uint8_t maxRetries = AGGRESSIVE_INIT_RETRIES;
  uint8_t maxBcastRetries = 0;

  // Data essage being set, currently
  uint8_t retriesLeft = 0;
  TOS_MsgPtr _msg = NULL;

  void printPacket(TOS_MsgPtr msg) {
#ifdef PLATFORM_PC
    MsgStub *stub = getStub(msg);
    
    // Pointer:AM type:ptr to next:timeout
    dbg_clear(DBG_USR2, "[%p:%d:%u:%p]",
	      msg, msg->type, stub->retriesLeft, stub->next);
#endif
  }
 
 void printQueue() {
#ifdef PLATFORM_PC
   TOS_MsgPtr head = headFifoQ;

   dbg(DBG_USR2, "SendQ: head is %p (of type %u)",
       _msg,
       (_msg == NULL ? 0 : _msg->type)
       );  
 
   if (head == NULL) {
     dbg_clear(DBG_USR2, "[EMPTY]\n");
   } else {
     TOS_MsgPtr cur = head;
     
     while (cur != NULL) {
       printPacket(cur);
       
       cur = getStub(cur)->next;
     }
   }
   dbg_clear(DBG_USR2, "\n");
#endif
 }

 bool sendInvoked = FALSE;

 void doSend() {
   
   dbg(DBG_USR1, "doSend()\n");
   printQueue();
   
   // If we are currently not sending any message,
   // popo another one from the queue
   if (_msg == NULL) {
     if (headFifoQ == NULL)
       return;
     else {
       MsgStub *stub = getStub(headFifoQ);
       
       _msg = headFifoQ;
       retriesLeft = stub->retriesLeft;
       
       headFifoQ = stub->next;
      }
   }
   
   // Msg is all set
   if (call SendExt.send[_msg->type](_msg->addr,
				     _msg->length,
				     _msg) == SUCCESS) {
     call Leds.greenToggle();
   } else {
     call Leds.redToggle();
   }
   
 }
 
 task void invokeSend() {
   sendInvoked = FALSE;
   doSend();
 }
   
 void postponeSend() {
     if (!sendInvoked) {
       sendInvoked = TRUE;
       
       if ((post invokeSend()) == FAIL)
	 sendInvoked = FALSE;
     }
   }

 command result_t StdControl.init() {

   return SUCCESS;
 }

 command result_t StdControl.start() {
   
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
   atomic {
     call MacControl.enableAck();
   }
#endif

   return SUCCESS;
 }

 command result_t StdControl.stop() {
   return SUCCESS;
 }



  command void AggressiveSendControl.setRetries(uint8_t numRetries) {
    maxRetries = numRetries;
  }

  command uint8_t AggressiveSendControl.getRetries() {
    return maxRetries;
  }

  command void AggressiveSendControl.setBcastRetries(uint8_t numRetries) {
    maxBcastRetries = numRetries;
  }

  command uint8_t AggressiveSendControl.getBcastRetries() {
    return maxBcastRetries;
  }

  command result_t SendMsg.send[uint8_t id](uint16_t addr,
					    uint8_t length,
					    TOS_MsgPtr msg) {
    MsgStub *stub;

    // Assure uniqueness in the queue
    TOS_MsgPtr cur = headFifoQ;

    call Leds.yellowToggle();

    if (msg == _msg)
      return FAIL;

    while (cur != NULL &&
	   (stub = getStub(cur))) {
      if (cur == msg)
	return FAIL;

      cur = stub->next;
    }

    stub = getStub(msg);

    // Enqueue
    msg->addr = addr;
    msg->length = length;
    msg->type = id;

    msg->ack = 0;

    stub->next = NULL;

    if (addr == TOS_BCAST_ADDR)
      stub->retriesLeft = maxBcastRetries;
    else
      stub->retriesLeft = maxRetries;

    // Enqueue to tail
    if (headFifoQ == NULL)
      headFifoQ = msg;
    else {
      cur = headFifoQ;
      
      while (cur != NULL &&
	     (stub = getStub(cur)) &&
	     (stub->next != NULL)) {
	cur = stub->next;
      }

      stub->next = msg;
    }

    doSend();

    return SUCCESS;
  }

  result_t finish(uint8_t id, TOS_MsgPtr msg, result_t success) {

    _msg = NULL;

    doSend();

    return signal SendMsg.sendDone[id](msg, success);
  }

  default event result_t SendMsg.sendDone[uint8_t id](TOS_MsgPtr msg,
						      result_t success) {

    dbg(DBG_USR1, "DEFAULT SendDone[%d]!\n", id);

    return SUCCESS;
  }
  
  default command result_t SendExt.send[uint8_t id](uint16_t addr,
						    uint8_t length,
						    TOS_MsgPtr msg) {

    dbg(DBG_USR1, "DEFAULT Send[%d]!\n", id);

    return SUCCESS;
  }

  event result_t SendExt.sendDone[uint8_t id](TOS_MsgPtr msg, 
					      result_t success) {

    if (msg != _msg) {
      // Another process finished, we should now try
      doSend();

      //      call Leds.greenToggle();
      
      dbg(DBG_USR1, "*** ANOTHER: type %d\n", id);

      return signal SendMsg.sendDone[id](msg, success);
    } else if (success == FAIL) {
      postponeSend();

      return SUCCESS;
    } else if (msg->addr == TOS_UART_ADDR) {
      dbg(DBG_USR1, "*** RETRIES RESET: UART\n");

      return finish(id, msg, success);
	
    } else if (msg->addr == TOS_BCAST_ADDR ||
	       !msg->ack) {
      
      // call Leds.redToggle();

      signal AggressiveSendControl.transmitted(msg);

      if (retriesLeft == 0) {

	dbg(DBG_USR1, "*** FAILED/BROADCAST AFTER %d RETRIES\n", maxRetries);
	
	return finish(id, msg, msg->addr == TOS_BCAST_ADDR ? SUCCESS : FAIL);
	
      } else {
	--retriesLeft;

	doSend();

	return SUCCESS;
      }
    } else {

      dbg(DBG_USR1, "*** SUCCESS AT %d RETRIES\n", maxRetries - retriesLeft);

      signal AggressiveSendControl.transmitted(msg);

      return finish(id, msg, success);
    }

  }


}
