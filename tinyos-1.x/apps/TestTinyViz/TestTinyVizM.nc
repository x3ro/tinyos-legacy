// $Id: TestTinyVizM.nc,v 1.2 2003/10/07 21:45:24 idgay Exp $

/*
 * Copyright (c) 2003
 *	The President and Fellows of Harvard College.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/* Author: Matt Welsh <mdw@eecs.harvard.edu> 
 * Last modified: 3 August 2003
 */

/**
 * The TestTinyViz application simply sends random messages to demonstrate 
 * the debugging and visualization features of TinyViz.
 * @author Matt Welsh <mdw@eecs.harvard.edu> 
 */
module TestTinyVizM {
  provides {
    interface StdControl;
  }
  uses {
    interface Timer;
    interface ReceiveMsg;
    interface SendMsg;
    interface Random;
  }
} implementation {

  enum {
    MAX_NEIGHBORS = 8,
  };

  uint16_t neighbors[MAX_NEIGHBORS];
  TOS_Msg beacon_packet;

  command result_t StdControl.init() {
    int i;
    for (i = 0; i < MAX_NEIGHBORS; i++) {
      neighbors[i] = 0xffff;
    }
    *((uint16_t *)beacon_packet.data) = TOS_LOCAL_ADDRESS;
    return call Random.init();
  }
  command result_t StdControl.start() {
    return call Timer.start(TIMER_REPEAT, 1000);
  }
  command result_t StdControl.stop() {
    return call Timer.stop();
  }

  event result_t Timer.fired() {
    uint16_t nbr;
    nbr = call Random.rand() % MAX_NEIGHBORS;
    // Don't worry if we can't send the message
    if (neighbors[nbr] != 0xffff) {
      dbg(DBG_USR1, "TestTinyVizM: Sending message to node %d\n", neighbors[nbr]);
      call SendMsg.send(neighbors[nbr], sizeof(uint16_t), &beacon_packet);
    } else {
      dbg(DBG_USR1, "TestTinyVizM: Sending beacon\n");
      call SendMsg.send(TOS_BCAST_ADDR, sizeof(uint16_t), &beacon_packet);
    }

    return SUCCESS;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, bool success) {
    dbg(DBG_USR1, "TestTinyVizM: Done sending, success=%d\n", success);
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr recv_packet) {
    int n;
    uint16_t nodeaddr = *((uint16_t *)recv_packet->data);
    dbg(DBG_USR1, "TestTinyVizM: Received message from %d\n", nodeaddr);
    for (n = 0; n < MAX_NEIGHBORS; n++) {
      if (neighbors[n] == 0xffff) {
	neighbors[n] = nodeaddr;
	break;
      }
    }
    return recv_packet;
  }


}




