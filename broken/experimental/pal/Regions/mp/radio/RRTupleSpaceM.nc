module RRTupleSpaceM {
  provides {
    interface StdControl;
    interface TupleSpace[uint8_t type];
  }
  uses {
    interface Tuning;
    interface SendMsg;
    interface ReceiveMsg;
  }

} implementation {

  struct TOS_Msg send_task_packet, reply_task_packet, reply_packet;
  bool send_busy;
  
  enum {
    TUPLESPACE_EMPTY_CMD = 0,
    TUPLESPACE_CMD_GET = 1,
    TUPLESPACE_REPLY_GET = 2,
    REQ_QUEUE_LEN = 10,
  };

  typedef struct {
    uint8_t len;
    uint8_t buf[TUPLESPACE_BUFLEN];
  } sharedvar_value_t;
  sharedvar_value_t values[TUPLESPACE_MAX_KEY];

  typedef struct request {
    TOS_Msg cmd_packet;
    RadioRegion_TSMsg *cmd_msg;
    uint8_t type;
    uint16_t destaddr;
    void *user_buf;
  } request;
  
  request reqqueue[REQ_QUEUE_LEN];

  /* For sendDataTask() */
  struct send_task_data {
    RadioRegion_TSMsg *msg;
  } send_task_data;
  bool send_task_busy;

  /* For procReplyTask() */
  struct reply_task_data {
    RadioRegion_TSMsg *msg;
  } reply_task_data;
  bool reply_task_busy;

  static void initialize() {
    int i;

    send_busy = FALSE;
    for (i = 0; i < REQ_QUEUE_LEN; i++) {
      reqqueue[i].cmd_msg = (RadioRegion_TSMsg *)reqqueue[i].cmd_packet.data;
      reqqueue[i].cmd_msg->cmd = TUPLESPACE_EMPTY_CMD;
    }
  }

  command result_t StdControl.init() {
    initialize();
    return SUCCESS;
  }
  command result_t StdControl.start() {
    initialize();
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  // XXX Should use an aging/timeout mechanism
  static request *getRequestSlot(uint8_t type, uint16_t destaddr, uint8_t cmd) {
    int i;
    // Only allow one outstanding request per destination
    for (i = 0; i < REQ_QUEUE_LEN; i++) {
      if (reqqueue[i].destaddr == destaddr && reqqueue[i].type == type) {
	reqqueue[i].cmd_msg->cmd = cmd; 
	return &(reqqueue[i]);
      }
    }
    for (i = 0; i < REQ_QUEUE_LEN; i++) {
      if (reqqueue[i].cmd_msg->cmd == TUPLESPACE_EMPTY_CMD) {
	reqqueue[i].type = type;
	reqqueue[i].destaddr = destaddr;
	reqqueue[i].cmd_msg->cmd = cmd; 
	return &(reqqueue[i]);
      }
    }
    return NULL;
  }

  static void freeRequestSlot(request *req) {
    req->cmd_msg->cmd = TUPLESPACE_EMPTY_CMD;
  }

  /* XXX Use QueuedSend with retransmission for sending messages -
   * return failure to user if no ack received after N retries
   * (node may not be available).
   */
  static result_t sendCmd(uint8_t type, uint8_t cmd, uint16_t dest, uint8_t key,
      void *data, int data_len, result_t success) {
    request *req;
    RadioRegion_TSMsg *cmd_msg;
    TOS_MsgPtr cmd_packet;

    dbg(DBG_USR1, "RRTS: sendCmd: cmd %d key %d dest %d data_len %d\n",
	cmd, key, dest, data_len);

    if (key >= TUPLESPACE_MAX_KEY) return FAIL;
    if (data_len > TUPLESPACE_BUFLEN) return FAIL;

    switch (cmd) {
      case TUPLESPACE_CMD_GET:
	if ((req = getRequestSlot(type, dest, cmd)) == NULL) return FAIL;
	cmd_msg = req->cmd_msg;
	cmd_packet = &req->cmd_packet;
	cmd_msg->cmd = cmd;
	cmd_msg->sourceaddr = TOS_LOCAL_ADDRESS;
	cmd_msg->key = key;
	req->user_buf = data;
	break;

      case TUPLESPACE_REPLY_GET:
	cmd_msg = (RadioRegion_TSMsg*)reply_packet.data;
	cmd_msg->cmd = cmd;
	cmd_msg->sourceaddr = TOS_LOCAL_ADDRESS;
	cmd_packet = &reply_packet;
	cmd_msg->key = key;
	cmd_msg->data_len = data_len;
	if (success) memcpy(cmd_msg->data, (char *)data, data_len);
	cmd_msg->success = success;
	break;

      default:
	return FAIL;
    }

    // XXX Since we are using queued send, don't need a "send busy" flag
    // here - just push it through
    if (call SendMsg.send(dest, sizeof(RadioRegion_TSMsg), cmd_packet) == SUCCESS) {
      return SUCCESS;
    } else {
      dbg(DBG_USR1, "RRTS: Can't enqueue outgoing message\n");
      return FAIL;
    }
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, bool success) {
    return SUCCESS;
  }

  task void sendDataTask() {
    RadioRegion_TSMsg *msg = send_task_data.msg;
    if (msg->key >= TUPLESPACE_MAX_KEY) {
      dbg(DBG_USR1, "RRTS: sendDataTask: Bad key %d\n", msg->key);
      return;
    }
    dbg(DBG_USR1, "RRTS: sendDataTask: Sending reply to node %d, key %d, len %d\n", msg->sourceaddr, msg->key, values[msg->key].len);
    if (!sendCmd(/* Ignored */ 0, TUPLESPACE_REPLY_GET, msg->sourceaddr, msg->key, 
	values[msg->key].buf, values[msg->key].len, SUCCESS)) {
      dbg(DBG_USR1, "RRTS: sendDataTask: Cannot send reply\n");
    } else {
      dbg(DBG_USR1, "RRTS: sendDataTask: Sent reply to %d\n", msg->sourceaddr);
    }
    send_task_busy = FALSE;
  }

  task void procReplyTask() {
    RadioRegion_TSMsg *msg = reply_task_data.msg;
    RadioRegion_TSMsg *req_msg;
    request *req;
    int n;

    dbg(DBG_USR1, "RRTS: processing reply, source %d key %d success %d\n", msg->sourceaddr, msg->key, msg->success);
    dbg(DBG_USR1, "RRTS: data 0x%lx\n", (uint32_t)*((uint32_t *)msg->data));

    if (msg->key >= TUPLESPACE_MAX_KEY) goto done;
    if (msg->data_len > TUPLESPACE_BUFLEN) goto done;

    /* Find all outstanding requests matching reply */
    for (n = 0; n < REQ_QUEUE_LEN; n++) {
      req = &(reqqueue[n]);
      req_msg = req->cmd_msg;
      dbg(DBG_USR1, "RRTS: req[%d] dest %d key %d\n", n, req->destaddr, req_msg->key);
      if ((msg->cmd == TUPLESPACE_REPLY_GET && 
	    req_msg->cmd == TUPLESPACE_CMD_GET) &&
	  msg->key == req_msg->key &&
	  msg->sourceaddr == req->destaddr) {
	/* Found a request slot */
	if (msg->success) {
	  memcpy(req->user_buf, msg->data, msg->data_len);
	}
	dbg(DBG_USR1, "RRTS: Get done: mote %d key %d type %d success %d\n", req->destaddr, msg->key, req->type, msg->success);
	signal TupleSpace.getDone[req->type](msg->key, req->destaddr, req->user_buf, msg->data_len, msg->success);
	freeRequestSlot(req);
      }
    }

done:

    reply_task_busy = FALSE;
    return;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr recv_packet) {
    RadioRegion_TSMsg *msg = (RadioRegion_TSMsg*)recv_packet->data;

    /* Drop messages from self */
    if (msg->sourceaddr == TOS_LOCAL_ADDRESS) return recv_packet;

    switch (msg->cmd) {
      case TUPLESPACE_CMD_GET:
	dbg(DBG_USR1, "RRTS: Received CMD_GET from %d\n", msg->sourceaddr);
	if (send_task_busy) {
	  dbg(DBG_USR1, "RRTS: Dropping CMD_GET due to send_task_busy\n");
	  return recv_packet;
	}
	send_task_data.msg = msg;
	send_task_busy = TRUE;
	dbg(DBG_USR1, "RRTS: Posting sendDataTask()\n");
	post sendDataTask();
	return &send_task_packet;
	break;

      /* Process replies */
      case TUPLESPACE_REPLY_GET:
	dbg(DBG_USR1, "RRTS: Received REPLY_GET from %d\n", msg->sourceaddr);
	if (reply_task_busy) {
	  dbg(DBG_USR1, "RRTS: Dropping REPLY_GET from %d\n", msg->sourceaddr);
	  return recv_packet;
	}
	reply_task_data.msg = msg;
	reply_task_busy = TRUE;
	dbg(DBG_USR1, "RRTS: Posting procReplyTask()\n");
	post procReplyTask();
	return &reply_task_packet;
	break;

      default:
	return recv_packet;

    } // End of switch
  }

  result_t getLocal(uint8_t type, uint8_t key, void *buf) {
    dbg(DBG_USR1, "RRTS: getLocal key %d\n", key);
    if (key >= TUPLESPACE_MAX_KEY) return FAIL;
    if (values[key].len == 0) {
      // This is the appropriate behavior for a remote get() when unset
      signal TupleSpace.getDone[type](key, TOS_LOCAL_ADDRESS, buf, 0, FAIL);
      return SUCCESS;
    }
    memcpy(buf, values[key].buf, values[key].len);
    dbg(DBG_USR1, "RRTS: getLocal done: key %d len %d\n", key, values[key].len);
    signal TupleSpace.getDone[type](key, TOS_LOCAL_ADDRESS, buf, values[key].len, 
	SUCCESS);
    return SUCCESS;
  }

  // XXX Potentially broadcast to nearby motes
  result_t putLocal(ts_key_t key, void *buf, int buflen) {
    dbg(DBG_USR1, "RRTS: putLocal key %d len %d\n", key, buflen);
    if (key >= TUPLESPACE_MAX_KEY) return FAIL;
    if (buflen > TUPLESPACE_BUFLEN) return FAIL;
    memcpy(values[key].buf, buf, buflen);
    values[key].len = buflen;
    dbg(DBG_USR1, "RRTS: putLocal done: key %d len %d\n", key, buflen);
    return SUCCESS;
  }

  command result_t TupleSpace.get[uint8_t type](ts_key_t key, uint16_t moteaddr, void *buf) {
    dbg(DBG_USR1, "RRTS: Reading mote %d key %d\n", moteaddr, key);
    if (moteaddr == TOS_LOCAL_ADDRESS) {
      return getLocal(type, key, buf);
    } else {
      return sendCmd(type, TUPLESPACE_CMD_GET, moteaddr, key, buf, 0, SUCCESS);
    }
  }

  command result_t TupleSpace.put[uint8_t type](ts_key_t key, void *buf, int buflen) {
    // XXX 
    if (buflen == 2) {
      uint16_t td = ((uint16_t*)buf)[0];
      dbg(DBG_USR1, "RRTS: put: data %d\n", td);
    } else if (buflen == 4) {
      uint32_t td = ((uint32_t*)buf)[0];
      dbg(DBG_USR1, "RRTS: put: data %d\n", td);
    }
    return putLocal(key, buf, buflen);
  }


}

