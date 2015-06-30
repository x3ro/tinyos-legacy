/* Copyright (c) 2002 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704. Attention: Intel License Inquiry.  
 * 
 * Author: Matt Welsh <mdw@eecs.harvard.edu>
 */

/**
 * Shared variables that operate within a one-hop radio connectivity region.
 */
module SharedVarOneHopM {
  provides {
    interface StdControl;
    interface SharedVar[uint8_t key];
  }
  uses {
    interface SendMsg;
    interface ReceiveMsg;
  }

} implementation {

  struct TOS_Msg send_task_packet, reply_task_packet, reply_packet;
  bool send_busy;

  enum {
    EMPTY_CMD = 0,
    REQ_QUEUE_LEN = 10,
  };

  typedef struct {
    uint8_t buf[SHAREDVAR_BUFLEN];
  } sharedvar_value_t;
  sharedvar_value_t values[SHAREDVAR_MAX_KEY];

  typedef struct request {
    TOS_Msg cmd_packet;
    SharedVarMsg *cmd_msg;
    uint16_t destaddr;
    void *user_buf;
  } request;
  
  request reqqueue[REQ_QUEUE_LEN];

  /* For sendDataTask() */
  struct send_task_data {
    SharedVarMsg *msg;
  } send_task_data;
  bool send_task_busy;

  /* For procReplyTask() */
  struct reply_task_data {
    SharedVarMsg *msg;
  } reply_task_data;
  bool reply_task_busy;

  static void initialize() {
    int i;

    send_busy = FALSE;
    for (i = 0; i < REQ_QUEUE_LEN; i++) {
      reqqueue[i].cmd_msg = (SharedVarMsg *)reqqueue[i].cmd_packet.data;
      reqqueue[i].cmd_msg->cmd = EMPTY_CMD;
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
  static request *getRequestSlot(uint8_t cmd) {
    int i;
    for (i = 0; i < REQ_QUEUE_LEN; i++) {
      if (reqqueue[i].cmd_msg->cmd == EMPTY_CMD) {
	reqqueue[i].cmd_msg->cmd = cmd; 
	return &(reqqueue[i]);
      }
    }
    return NULL;
  }

  static request *findRequestSlot(SharedVarMsg *msg) {
    int i;

    dbg(DBG_USR1, "SharedVar: findRequestSlot: source %d key %d\n", msg->sourceaddr, msg->key);

    for (i = 0; i < REQ_QUEUE_LEN; i++) {
      request *req = &(reqqueue[i]);
      SharedVarMsg *req_msg = req->cmd_msg;

      dbg(DBG_USR1, "SharedVar: req[%d] dest %d key %d\n", i, req->destaddr, req_msg->key);

      if ((msg->cmd == SHAREDVAR_REPLY_GET && 
	    req_msg->cmd == SHAREDVAR_CMD_GET) &&
	  msg->key == req_msg->key &&
	  msg->data_len == req_msg->data_len &&
	  msg->sourceaddr == req->destaddr)
	return req;
    }
    return NULL;
  }

  static void freeRequestSlot(request *req) {
    req->cmd_msg->cmd = EMPTY_CMD;
  }

  /* XXX Use QueuedSend with retransmission for sending messages -
   * return failure to user if no ack received after N retries
   * (node may not be available).
   */
  static result_t sendCmd(uint8_t cmd, uint16_t dest, uint8_t key,
      void *data, int data_len, result_t success) {
    request *req;
    SharedVarMsg *cmd_msg;
    TOS_MsgPtr cmd_packet;

    if (key > SHAREDVAR_MAX_KEY) return FAIL;
    if (data_len > SHAREDVAR_BUFLEN) return FAIL;

    switch (cmd) {
      case SHAREDVAR_CMD_GET:
	if ((req = getRequestSlot(cmd)) == NULL) return FAIL;
	cmd_msg = req->cmd_msg;
	cmd_packet = &req->cmd_packet;
	cmd_msg->cmd = cmd;
	cmd_msg->sourceaddr = TOS_LOCAL_ADDRESS;
	cmd_msg->key = key;
	cmd_msg->data_len = data_len;
	req->destaddr = dest;
	req->user_buf = data;
	break;

      case SHAREDVAR_REPLY_GET:
	cmd_msg = (SharedVarMsg*)reply_packet.data;
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
    if (call SendMsg.send(dest, sizeof(SharedVarMsg), cmd_packet) == SUCCESS) {
      return SUCCESS;
    } else {
      dbg(DBG_USR1, "SharedVar: Can't enqueue outgoing message\n");
      return FAIL;
    }
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, bool success) {
    return SUCCESS;
  }

  task void sendDataTask() {
    SharedVarMsg *msg = send_task_data.msg;
    if (msg->key > SHAREDVAR_MAX_KEY) {
      dbg(DBG_USR1, "SharedVar: sendDataTask: Bad key %d\n", msg->key);
      return;
    }
    if (msg->data_len > SHAREDVAR_BUFLEN) {
      dbg(DBG_USR1, "SharedVar: sendDataTask: Bad length %d\n", msg->data_len);
      return;
    }
    if (!sendCmd(SHAREDVAR_REPLY_GET, msg->sourceaddr, msg->key, 
	values[msg->key].buf, msg->data_len, SUCCESS)) {
      dbg(DBG_USR1, "SharedVar: sendDataTask: Cannot send reply\n");
    } else {
      dbg(DBG_USR1, "SharedVar: sendDataTask: Sent reply to %d\n", msg->sourceaddr);
    }
    send_task_busy = FALSE;
  }

  task void procReplyTask() {
    SharedVarMsg *msg = reply_task_data.msg;
    request *req;

    dbg(DBG_USR1, "SharedVar: processing reply, source %d key %d success %d\n", msg->sourceaddr, msg->key, msg->success);

    if (msg->key > SHAREDVAR_MAX_KEY) goto done;
    if (msg->data_len > SHAREDVAR_MAX_KEY) goto done;
    if ((req = findRequestSlot(msg)) == NULL) {
      dbg(DBG_USR1, "SharedVar: Can't find request slot\n");
      goto done;
    }
    if (msg->success) {
      memcpy(req->user_buf, msg->data, msg->data_len);
    }
    dbg(DBG_USR1, "SharedVar: Get done: mote %d key %d success %d\n", req->destaddr, msg->key, msg->success);
    signal SharedVar.getDone[msg->key](req->destaddr, req->user_buf, msg->data_len, msg->success);

done:
    reply_task_busy = FALSE;
    if (req != NULL) freeRequestSlot(req);
    return;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr recv_packet) {
    SharedVarMsg *msg = (SharedVarMsg*)recv_packet->data;

    /* Drop messages from self */
    if (msg->sourceaddr == TOS_LOCAL_ADDRESS) return recv_packet;

    switch (msg->cmd) {
      case SHAREDVAR_CMD_GET:
	dbg(DBG_USR1, "SharedVar: Received CMD_GET from %d\n", msg->sourceaddr);
	if (send_task_busy) {
	  dbg(DBG_USR1, "SharedVar: Dropping CMD_GET due to send_task_busy\n");
	  return recv_packet;
	}
	send_task_data.msg = msg;
	send_task_busy = TRUE;
	dbg(DBG_USR1, "SharedVar: Posting sendDataTask()\n");
	post sendDataTask();
	return &send_task_packet;
	break;

      /* Process replies */
      case SHAREDVAR_REPLY_GET:
	dbg(DBG_USR1, "SharedVAR: Received REPLY_GET from %d\n", msg->sourceaddr);
	if (reply_task_busy) {
	  dbg(DBG_USR1, "SharedVAR: Dropping REPLY_GET from %d\n", msg->sourceaddr);
	  return recv_packet;
	}
	reply_task_data.msg = msg;
	reply_task_busy = TRUE;
	dbg(DBG_USR1, "SharedVar: Posting procReplyTask()\n");
	post procReplyTask();
	return &reply_task_packet;
	break;

      default:
	return recv_packet;

    } // End of switch
  }

  default event void SharedVar.getDone[uint8_t key](uint16_t moteaddr, void *buf, int buflen, result_t success) {
  }

  result_t getLocal(uint8_t key, void *buf, int buflen) {
    dbg(DBG_USR1, "SharedVar: getLocal key %d len %d\n", key, buflen);
    if (key > SHAREDVAR_MAX_KEY) return FAIL;
    if (buflen > SHAREDVAR_BUFLEN) return FAIL;
    memcpy(buf, values[key].buf, buflen);
    dbg(DBG_USR1, "SharedVar: getLocal done: key %d len %d\n", key, buflen);
    signal SharedVar.getDone[key](TOS_LOCAL_ADDRESS, buf, buflen, SUCCESS);
    return SUCCESS;
  }

  // XXX Potentially broadcast to nearby motes
  result_t putLocal(uint8_t key, void *buf, int buflen) {
    dbg(DBG_USR1, "SharedVar: putLocal key %d len %d\n", key, buflen);
    if (key > SHAREDVAR_MAX_KEY) return FAIL;
    if (buflen > SHAREDVAR_BUFLEN) return FAIL;
    memcpy(values[key].buf, buf, buflen);
    dbg(DBG_USR1, "SharedVar: putLocal done: key %d len %d\n", key, buflen);
    return SUCCESS;
  }

  command result_t SharedVar.get[uint8_t key](uint16_t moteaddr, void *buf, int buflen) {
    dbg(DBG_USR1, "SharedVar: Reading mote %d key %d len %d\n", moteaddr, key, buflen);
    if (moteaddr == TOS_LOCAL_ADDRESS) {
      return getLocal(key, buf, buflen);
    } else {
      return sendCmd(SHAREDVAR_CMD_GET, moteaddr, key, buf, buflen, SUCCESS);
    }
  }

  command result_t SharedVar.put[uint8_t key](void *buf, int buflen) {
    return putLocal(key, buf, buflen);
  }


}

