/*									
 * "Copyright (c) 2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors: Naveen Sastry (nks@cs)
 * Date:    Nov 29, 2003
 */

module PairwiseM {
  provides interface StdControl;
  uses interface ReceiveMsg as ReceiveCmdMsg;
  uses interface ReceiveMsg as ReceiveTstMsg;
  uses interface ReceiveMsg as ReceiveTSModeMsg;
  uses interface SendMsg as    SendCmdMsg;
  uses interface SendMsg as    SendTstMsg;
  uses interface TinySecMode;
  uses interface Leds;
  uses interface Timer   as    TimerSend;
  uses interface Timer   as    TimerTestInterval;  
}
implementation {

  typedef enum {
    CT_START = 1,
    CT_STATS_REQ = 2,
    CT_STATS_RESP = 3,
    CT_RESET = 4,
  } __attribute__((packed))  cmd_type;
  
  
  struct cmd {
    // req:
    cmd_type type;
    uint16_t test_duration ; // in (actual) seconds
    uint8_t  test_msgsize  ; // in bytes
    uint8_t  test_sleep    ; // in binary MS between messages [0 for immediate]
    uint8_t  num_nodes     ;
    // resp:
    uint16_t packets_sent;
    uint16_t packets_recv;
    uint16_t bytes_sent;
    uint16_t bytes_recv;
    uint16_t tosaddr;
    uint8_t  tosmode;
  };

  // current test params: 
  struct cmd cur;
  bool test_running;
  TOS_Msg msg;
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  command result_t StdControl.init() {
    memset(&cur, 0, sizeof(struct cmd));
    test_running = FALSE;
    return SUCCESS;
  }

  task void tstmsgsend() {
    if (test_running) {
      if (call SendTstMsg.send (TOS_LOCAL_ADDRESS + 1, cur.test_msgsize, &msg)
          == SUCCESS) {
        cur.packets_sent ++;
        cur.bytes_sent += cur.test_msgsize;
      }
    } 
  }

  event result_t TimerTestInterval.fired() {
    if (cur.test_duration) {
      call TimerSend.stop();
    }
    test_running = FALSE;
    return SUCCESS;
  }

  event result_t TimerSend.fired() {
    post tstmsgsend();
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveTstMsg.receive(TOS_MsgPtr m) {
    call Leds.greenToggle();          
    cur.packets_recv ++;
    cur.bytes_recv += m->length;
    return m;    
  }

  event TOS_MsgPtr ReceiveTSModeMsg.receive(TOS_MsgPtr m) {
    if (m->data[0] == 0) {
      call TinySecMode.setTransmitMode(TINYSEC_AUTH_ONLY);
      call TinySecMode.setReceiveMode (TINYSEC_RECEIVE_AUTHENTICATED);
    } else if (m->data[0] == 1) {
      call TinySecMode.setTransmitMode(TINYSEC_ENCRYPT_AND_AUTH);
      call TinySecMode.setReceiveMode (TINYSEC_RECEIVE_AUTHENTICATED);      
    } else {
      call TinySecMode.setTransmitMode(TINYSEC_DISABLED);
      call TinySecMode.setReceiveMode(TINYSEC_RECEIVE_CRC);      
    }
    cur.tosmode = m->data[0];
    call Leds.redToggle();
    return m;
  }
  
  event TOS_MsgPtr ReceiveCmdMsg.receive(TOS_MsgPtr m) {
    struct cmd* c = ((struct cmd *)m->data);
    switch (c->type) {
    case CT_START:
      // only send if we are odd and less than 2 * num to send.
      // so this means that for cur-num_nodes = 3
      //    nodes 1, 3, 5 will transmit to
      //          2, 4, 6
      //   
      if (TOS_LOCAL_ADDRESS  > c->num_nodes * 2 ||
          !(TOS_LOCAL_ADDRESS & 0x1)) {
        break;
      }
      call Leds.yellowToggle();
      memcpy(&cur, c, sizeof(struct cmd));
      call TimerTestInterval.start (TIMER_ONE_SHOT, 1024 * cur.test_duration);
      test_running = TRUE;
      if (cur.test_sleep) {
        call TimerSend.start (TIMER_REPEAT, cur.test_duration);
      } else {
        post tstmsgsend();
      }
      break;
    case CT_STATS_RESP:
      break;
    case CT_STATS_REQ:
      c = (struct cmd *)&msg.data;
      memcpy(c, &cur, sizeof(struct cmd));
      c->type = CT_STATS_RESP;
      c->tosaddr      = TOS_LOCAL_ADDRESS;
      c->tosmode      = call TinySecMode.getTransmitMode();
      call SendCmdMsg.send (TOS_BCAST_ADDR, sizeof(struct cmd), &msg);
      break;
    case CT_RESET:
      memset(&cur, 0, sizeof(struct cmd));
      call Leds.set(0);
      test_running = FALSE;      
      break;
    }
    return m;
  }

  event result_t SendTstMsg.sendDone (TOS_MsgPtr m, result_t success) {
    if (!cur.test_sleep) {
      post tstmsgsend();
    }
    return SUCCESS;
  }
  
  event result_t SendCmdMsg.sendDone(TOS_MsgPtr m, result_t success) {
    return SUCCESS;
  }
}
