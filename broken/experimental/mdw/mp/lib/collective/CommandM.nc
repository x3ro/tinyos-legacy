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

module CommandM { 
  provides {
    interface StdControl;
    interface Command;
  }
  uses {
    interface SendMsg;
    interface ReceiveMsg;
  }
} implementation {

  bool send_busy, recv_busy, cmd_busy;
  TOS_Msg send_packet, recv_swap_packet;
  uint8_t lastSeqno;
  TOS_MsgPtr recv_packet;
  uint16_t cur_commandID;
  uint8_t cur_params[COMMAND_MAX_BUFLEN];
  uint16_t cur_params_len;

  command result_t StdControl.init() {
    send_busy = FALSE;
    recv_busy = FALSE;
    cmd_busy = FALSE;
    lastSeqno = 0; 
    return SUCCESS;
  }
  command result_t StdControl.start(){
    return SUCCESS;
  }
  command result_t StdControl.stop(){
    return SUCCESS;
  }

  task void cmdTask() {
    dbg(DBG_USR1, "Command: executing received command %d\n", cur_commandID);
    signal Command.receive(cur_commandID, cur_params, cur_params_len);
    cmd_busy = FALSE;
  }

  inline bool is_new_msg(uint8_t sno) {
    return ((sno - lastSeqno >= 0) || (sno+127 < lastSeqno));
  }

  task void recvTask() {
    CommandMsg *msg = (CommandMsg*)&recv_packet->data;
    dbg(DBG_USR2, "CommandM.recvTask() running, destaddr 0x%x\n", msg->destaddr);
    if (msg->destaddr == TOS_LOCAL_ADDRESS ||
	msg->destaddr == TOS_BCAST_ADDR) {
      dbg(DBG_USR2, "CommandM.recvTask(): message is for me, cmd_busy %d data_len %d seqno %d (last % d)\n", cmd_busy, msg->data_len, msg->seqno, lastSeqno);
      if (!cmd_busy && msg->data_len <= COMMAND_MAX_BUFLEN && is_new_msg(msg->seqno)) {
	cmd_busy = TRUE;
	cur_commandID = msg->commandID;
        dbg(DBG_USR2, "CommandM processing received command %d\n", cur_commandID);
	memcpy(cur_params, msg->data, msg->data_len);
	cur_params_len = msg->data_len;
	post cmdTask();
      }
    }

    if (!send_busy && is_new_msg(msg->seqno)) {
      send_busy = TRUE;
      dbg(DBG_USR2, "CommandM.recvTask(): rebroadcasting command\n");
      if (!call SendMsg.send(TOS_BCAST_ADDR, sizeof(CommandMsg), recv_packet)) {
	send_busy = FALSE;
      }
      lastSeqno = msg->seqno+1;
    }
    recv_busy = FALSE;
  }

  command result_t Command.invoke(uint16_t destaddr, uint16_t commandID, uint8_t *params, uint16_t params_len) {
    CommandMsg *msg = (CommandMsg*)&send_packet.data;
    dbg(DBG_USR2, "CommandM.invoke() called, command %d params 0x%lx params_len %d\n", commandID, (unsigned long)params, params_len);

    if (send_busy) return FAIL;
    if (params_len > COMMAND_MAX_BUFLEN) return FAIL;

    msg->destaddr = destaddr;
    msg->commandID = commandID;
    msg->data_len = params_len;
    msg->seqno = lastSeqno++;
    memcpy(msg->data, params, params_len);
    send_busy = TRUE;
    dbg(DBG_USR1, "CommandM.invoke(): sending msg 0x%lx, buffer 0x%lx\n", (unsigned long)msg, (unsigned long)&send_packet);
    if (call SendMsg.send(TOS_BCAST_ADDR, sizeof(CommandMsg), &send_packet)) {
      return SUCCESS;
    } else {
      dbg(DBG_USR2, "CommandM.invoke(): Failed sending message");
      send_busy = FALSE;
      return FAIL;
    }
  }

  command result_t Command.broadcast(uint16_t commandID, uint8_t *params, uint16_t params_len) {
    dbg(DBG_USR2, "CommandM.broadcast() called\n");
    return call Command.invoke(TOS_BCAST_ADDR, commandID, params, params_len);
  }

  command result_t Command.sendToBase(uint16_t commandID, uint8_t *params, uint16_t params_len) {
    // XXX MDW Implement using Surge or Spantree
    dbg(DBG_USR2, "Command.sendToBase called, command %d\n", commandID);
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr msg) {
    dbg(DBG_USR2, "CommandM.ReceiveMsg.receive() called, recv_busy %d\n", recv_busy);
    if (recv_busy) return msg;
    recv_busy = TRUE;
    recv_packet = msg;
    post recvTask();
    return &recv_swap_packet;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    dbg(DBG_USR2, "CommandM.SendMsg.sendDone() called\n");
    send_busy = FALSE;
    return SUCCESS;
  }
}

