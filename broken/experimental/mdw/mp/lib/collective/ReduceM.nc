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

includes Collective; 

module ReduceM { 
  provides {
    interface Reduce;
  }
  uses {
    interface SendMsg;
    interface ReceiveMsg;
    interface Spantree;
    interface Command;
    interface Timer;
  }
} implementation {

  enum {
    MAX_CHILDREN = 10,
    COMMAND_REDUCE_DONE = 66,
  };

  int state;
  enum {
    STATE_IDLE,
    STATE_FORMING_SPANTREE,
    STATE_WAIT_CHILD,
    STATE_SENDING,
  };
  uint16_t cur_root;
  operator_t cur_op;
  type_t cur_type;
  bool cur_toall, cur_passthrough;
  void *cur_outbuf;
  uint16_t cur_parent;
  TOS_Msg reduce_packet, recv_packet;
  bool send_busy, recv_busy;
  ReduceMsg *child_msg;

  // Buffer for accumulated child data
  typedef union {
    uint16_t uint16_t_val;
    float float_val;
  } reducebuf;

  reducebuf child_buf[MAX_CHILDREN], cur_buf;
  int num_child_slots;

  static void resetState() {
    dbg(DBG_USR1, "ReduceM: resetState()\n");
    state = STATE_IDLE;
    cur_toall = FALSE;
    cur_passthrough = FALSE;
  }

  static result_t start_reduce(uint16_t root, operator_t op,
      type_t type, void *inbuf, void *outbuf, bool toall) {

    dbg(DBG_USR1, "ReduceM: start_reduce (root 0x%x)\n", root);
    if (state != STATE_IDLE) return FAIL;
    cur_root = root;
    cur_op = op;
    cur_type = type;
    cur_toall = toall;
    cur_outbuf = outbuf;
    cur_passthrough = FALSE;

    switch (type) {
      case TYPE_UINT16:
	memcpy(&cur_buf.uint16_t_val, inbuf, sizeof(uint16_t));
	break;
      case TYPE_FLOAT:
	memcpy(&cur_buf.float_val, inbuf, sizeof(float));
	break;
      default:
	return FAIL;
    }

    dbg(DBG_USR1, "ReduceM: start_reduce done setting up current state\n");

    state = STATE_FORMING_SPANTREE;
    dbg(DBG_USR1, "ReduceM: start_reduce creating spantree\n");
    if (!call Spantree.makeSpantree(root, SPANTREE_TIMEOUT)) {
      dbg(DBG_USR1, "ReduceM: start_reduce failed creating spantree\n");
      return FAIL;
    }
    return SUCCESS;
  }

  command result_t Reduce.reduceToOne(uint16_t root, operator_t op, 
      type_t type, void *inbuf, void *outbuf) {
    dbg(DBG_USR1, "ReduceM: reduceToOne called (root 0x%x op %d type %d)\n", root, op, type);
    resetState(); // Really need to 'key' each reduction 
    return start_reduce(root, op, type, inbuf, outbuf, FALSE);
  }

  command result_t Reduce.reduceToAll(uint16_t root, operator_t op, 
      type_t type, void *inbuf, void *outbuf) {
    dbg(DBG_USR1, "ReduceM: reduceToAll called (root 0x%x op %d type %d)\n", root, op, type);
    resetState(); // Really need to 'key' each reduction 
    return start_reduce(root, op, type, inbuf, outbuf, TRUE);
  }

  command result_t Reduce.passThrough() {
    resetState(); // Really need to 'key' each reduction 
    dbg(DBG_USR1, "ReduceM: passThrough called\n");
    cur_passthrough = TRUE;
    state = STATE_FORMING_SPANTREE;
    return SUCCESS;
  }

  task void sendTask() {
    int i;
    ReduceMsg *msg = (ReduceMsg*)&reduce_packet.data;

    dbg(DBG_USR1, "ReduceM: sendTask() running, send_busy %d, num_child_slots %d\n", send_busy, num_child_slots);

    if (cur_root != TOS_LOCAL_ADDRESS && send_busy) {
      dbg(DBG_USR1, "ReduceM: sendTask(): send_busy is true, resetting state\n");
      resetState();
      return;
    }

    // Reduce child values
    for (i = 0; i < num_child_slots; i++) {
      switch (cur_op) {
	case OP_NOP: 
	  break;

	case OP_ADD:
	  switch (cur_type) {
	    case TYPE_UINT16:
	      cur_buf.uint16_t_val += child_buf[i].uint16_t_val;
	      break;
	    case TYPE_FLOAT:
	      cur_buf.float_val += child_buf[i].float_val;
	      break;
	  }
	  break;

	case OP_PROD:
	  switch (cur_type) {
	    case TYPE_UINT16:
	      cur_buf.uint16_t_val *= child_buf[i].uint16_t_val;
	      break;
	    case TYPE_FLOAT:
	      cur_buf.float_val *= child_buf[i].float_val;
	      break;
	  }
	  break;

	case OP_MIN:
	  switch (cur_type) {
	    case TYPE_UINT16:
	      if (child_buf[i].uint16_t_val < cur_buf.uint16_t_val) {
		cur_buf.uint16_t_val = child_buf[i].uint16_t_val;
	      }
	      break;
	    case TYPE_FLOAT:
	      if (child_buf[i].float_val < cur_buf.float_val) {
		cur_buf.float_val = child_buf[i].float_val;
	      }
	      break;
	  }
	  break;

	case OP_MAX:
	  switch (cur_type) {
	    case TYPE_UINT16:
	      dbg(DBG_USR1, "ReduceM: OP_MAX: child value %d cur_buf %d\n", child_buf[i].uint16_t_val, cur_buf.uint16_t_val);
	      if (child_buf[i].uint16_t_val > cur_buf.uint16_t_val) {
		cur_buf.uint16_t_val = child_buf[i].uint16_t_val;
	      }
	      break;
	    case TYPE_FLOAT:
	      if (child_buf[i].float_val > cur_buf.float_val) {
		cur_buf.float_val = child_buf[i].float_val;
	      }
	      break;
	  }
	  break;
      }
    }

    // If we're the root, signal that we're done
    if (cur_root == TOS_LOCAL_ADDRESS) {
      memcpy(cur_outbuf, &cur_buf, REDUCE_MAX_BUFLEN);
      dbg(DBG_USR1, "ReduceM: sendTask() Done with reduction, result 0x%lx\n", (unsigned long)*(unsigned long *)cur_outbuf);
      if (cur_toall) {
	dbg(DBG_USR1, "ReduceM: Broadcasting result to all\n");
	call Command.broadcast(COMMAND_REDUCE_DONE, cur_outbuf, call Reduce.typeSize(cur_type));
      }
      signal Reduce.reduceDone(cur_outbuf, SUCCESS);
      resetState();
      return;
    }

    // Otherwise, send the message upstream
    msg->sourceaddr = TOS_LOCAL_ADDRESS;
    memcpy(msg->data, &cur_buf, REDUCE_MAX_BUFLEN);

    send_busy = TRUE;
    if (!call SendMsg.send(cur_parent, sizeof(ReduceMsg), &reduce_packet) == SUCCESS) {
      dbg(DBG_USR1, "ReduceM: sendTask() can't send message\n");
      send_busy = FALSE;
      return;
    } else {
      // XXX MDW: Since we are using QueuedSend, don't need to carry send_busy flag
      send_busy = FALSE;
    }
    dbg(DBG_USR1, "ReduceM: sendTask() done sending result to parent 0x%x\n", cur_parent);
  }

  default event void Reduce.reduceDone(void *buf, result_t success) {
  }

  command int Reduce.typeSize(type_t type) {
    switch (type) {
      case TYPE_UINT16:
     	return sizeof(uint16_t);
      	break;
      case TYPE_FLOAT:
	return sizeof(float);
	break;
      default:
	return 0;
    }
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    send_busy = FALSE;
    if (!cur_toall) resetState();
    return SUCCESS;
  }

  event void Spantree.spantreeDone(uint16_t root, spantree_t *stree, result_t res) {
    dbg(DBG_USR1, "ReduceM: spantreeDone (root 0x%x res %d)\n", root, res);
    if (state != STATE_FORMING_SPANTREE) return;
    if (res != SUCCESS) {
      dbg(DBG_USR1, "ReduceM: spantree creation failed");
      resetState();
      signal Reduce.reduceDone(cur_outbuf, FAIL);
      return;
    }
    if (stree->root != cur_root) {
      dbg(DBG_USR1, "ReduceM: spantree has wrong root\n");
      resetState();
      signal Reduce.reduceDone(cur_outbuf, FAIL);
    }

    num_child_slots = 0;
    cur_parent = stree->parent;
    dbg(DBG_USR1, "ReduceM: spantreeDone parent is 0x%x depth %d\n", cur_parent, stree->depth);

    /* Delay before sending */
    state = STATE_WAIT_CHILD;
    if (!call Timer.start(TIMER_ONE_SHOT, REDUCE_XMIT_DELAY * (REDUCE_MAX_LEVELS - stree->depth))) {
      dbg(DBG_USR1, "ReduceM: spantreeDone can't start timer - reverting to passthrough\n");
      // Revert to passthrough
      cur_passthrough = TRUE;
      return;
    }
    dbg(DBG_USR1, "ReduceM: spantreeDone waiting for children\n");
  }

  event void Spantree.spantreeEvicted(uint16_t root) {
    dbg(DBG_USR1, "ReduceM: spantreeEvicted root 0x%x\n", root);
    // Do nothing
  }

  event result_t Timer.fired() {
    if (state != STATE_WAIT_CHILD) return SUCCESS;
    state = STATE_SENDING;
    post sendTask();
    return SUCCESS;
  }

  task void recvTask() {
    dbg(DBG_USR1, "ReduceM: recvTask() called\n");
    switch (cur_type) {
      case TYPE_UINT16:
	memcpy(&child_buf[num_child_slots].uint16_t_val, child_msg->data, sizeof(uint16_t));
	dbg(DBG_USR1, "ReduceM: received value %d\n", child_buf[num_child_slots].uint16_t_val);
	break;
      case TYPE_FLOAT:
	memcpy(&child_buf[num_child_slots].float_val, child_msg->data, sizeof(float));
	dbg(DBG_USR1, "ReduceM: received value %f\n", child_buf[num_child_slots].float_val);
	break;
      default:
	dbg(DBG_USR1, "Reduce: recvTask(): Bad type %d\n", cur_type);
	return;
    }
    num_child_slots++;
    dbg(DBG_USR1, "ReduceM: recvTask() num_child_slots now %d\n", num_child_slots);
    recv_busy = FALSE;
  }

  // XXX MDW: Deal with passthrough
  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr msg) {
    dbg(DBG_USR1, "ReduceM: ReceiveMsg (state %d recv_busy %d num_child_slots %d)\n", state, recv_busy, num_child_slots);
    if (state != STATE_WAIT_CHILD) return msg;
    if (recv_busy) return msg;
    if (num_child_slots == MAX_CHILDREN) return msg;
    recv_busy = TRUE;
    child_msg = (ReduceMsg *)msg->data;
    dbg(DBG_USR1, "ReduceM: Posting recv task\n");
    post recvTask();
    return &recv_packet;
  }

  // XXX MDW: Deal with passthrough
  event void Command.receive(uint16_t commandID, uint8_t *params, uint16_t paramslen) {
    dbg(DBG_USR1, "ReduceM: Command.receive(): state %d id %x params_len %d (need %d)\n", state, commandID, paramslen, call Reduce.typeSize(cur_type));
    // Don't need a task here since Command.receive() already invoked
    // within a task
    if (commandID != COMMAND_REDUCE_DONE) return;
    if (paramslen != call Reduce.typeSize(cur_type)) return;
    if (state == STATE_IDLE || cur_passthrough) return;
    memcpy(cur_outbuf, params, paramslen);
    dbg(DBG_USR1, "ReduceM: Got REDUCE_DONE: Done with reduction, result 0x%lx\n", (unsigned long)*(unsigned long *)cur_outbuf);
    resetState();
    signal Reduce.reduceDone(cur_outbuf, SUCCESS);
  }



}

