/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 * Authors:		Phil Levis
 *                      Nelson Lee
 *
 */

/*
 *   FILE: BapM.td
 * AUTHOR: Phil Levis
 *         Nelson Lee 
 *  DESCR: Beaconless routing protocol
 *
 *  BapM is a Beacon-LESS routing protocol for TinyOS. All data messages
 *  are sent as broadcasts. Motes sniff data traffic for other motes that
 *  can be heard. If the current parent mote (to whom messages are sent to
 *  get to the base station) is unheard for an interval, the mote switches
 *  to a new parent. The distance for the base station is stored in every
 *  data packet. If a mote hears a transmission from a mote that is closer
 *  to the base station than its current parent, it updates its cache of possible 
 *  parents. If it hears its parent, but its parent suddenly is more distant
 *  from the base station, it rejects its parent and tries to find a new one
 *  (otherwise, cycles in the routing graph could easily result).
 *
 *  Motes maintain a cache of 8 heard motes in case that a parent change is
 *  necessary. The base station periodically sends out a data message to
 *  itself, so that nearby motes can associate.

 *  Bap is not an optimal ad-hoc routing protocol. However, tweaking certain
 *  parameters can significantly improve its performance.  Of course, the values
 *  of the different parameters depend a lot on the structure and conditions
 *  of the network.
 *  
 *  When a new parent is chosen:
 *     - If a packet is heard and there is no parent.
 *     - Based on the number of packets received and sent, a new parent
 *       should be selected
 *  
 *  To separate the dependence of an algorithm with time, this protocol responds
 *  to activity over the network, namely the sum of the number of packets sent and received.
 *  
 *  Therefore, whenever the sum of the number of packets sent and received equals EVAL_PARENT,
 *  which by default is 40, a new parent will be selected.

 *  Updating of the heuristic value is slightly more complex.  Whenever a packet
 *  is received, if an entry in cache exists for the sender of that packet, its
 *  heuristic is increased/decreased by current_hop_distance - cached_hop_distance.
 *  
 *  When the sum of the number of packets sent and received equals EVAL_HEURISTICS,
 *  every cache entry's heuristic is changed by the following expression:
 *  
 *  "ECHO_SCALAR*echoTemp + HEARD_SCALAR*heardTemp + LONGEVITY_INCREMENT:
 *  
 *  
 *  The first term represents the reward for entries whose corresponding motes echo back
 *  packets sent by the updating mote.  The second term represents the reward for entries
 *  whose corresponding mote's packets can be heard.  And lastly, the third constant
 *  represents the penalty a mote suffers if it has not been heard. 
 *  
 *  Bap keeps track of whether or not a mote in cache has been heard or not by bitmasks.
 *  As an advantage to the current parent, (Bap is designed so that a good parent is kept longer)
 *  a ping is sent to the current parent when the sum of the number of packets sent and received
 *  equals COUNT_TO_SEND_PING. If the parent responds to the ping, it is marked as having been
 *  both heard and echoed. This is the only time when both an entry is marked as heard and echoed.
 *  
 *   
 *   
 *  The Bap message format stores the source, the hop source (so you know
 *  who is transmitting it), hop destination, previous hop source (used as a heuristic
 *  when determining next parent), the hop distance of the hop src,
 *  and data.
 *
 *  The application BapTest shows a trivial example use of Bap.
 *
 *  Bap should be given at most 21 bytes of data to be sent out at a time. If it is given
 *  more, it will only send the first 21 bytes and the remaining bytes will be dropped!
 *  
 *  Certain parameters can be adjusted to improve performance.  For instance, if the 
 *  network is very well structured and will not change often, increasing TIMEOUT_HEURISTIC,
 *  and EVAL_HEURISTICS will keep the node's current parent longer.  Furthermore, 
 *  EVAL_HEURISTICS, EVAL_PARENT, and COUNT_TO_SEND_PING can also be increased to 
 *  conserve computation time as well as network bandwidth.
 *
 */


includes BapMsg;
module BapM {
  provides {
    interface SendData;
    interface StdControl;
    command result_t active();

    // New Base-station functionality interface
    interface Receive;
  }


  uses {
    interface Timer;
    interface Leds;
    interface SendMsg as SendMsgGenericComm;
    interface ReceiveMsg as ReceiveMsgGenericComm;
    interface Ping;
    interface StdControl as StdControlGenericComm;    
    interface StdControl as StdControlBapPing;
    
    // New Base-station functionality interface
    interface IsBaseStation;
  }

}
implementation {
  enum {
    NO_PARENT = -1,
    MAX_HOPS  = 8,
    EVAL_PARENT = 40,
    EVAL_HEURISTICS = 4,
    NUM_ENTRIES = 8,
    WORST_VALUE_HEURISTIC = 126,
    NO_MOTE = -64,
    TIMEOUT_HEURISTIC = 80,
    COUNT_TO_SEND_PING = 3,
    LONGEVITY_INCREMENT = 3,
    ECHO_SCALAR = -2,
    HEARD_SCALAR = -1,
    CLOCK_PARAM = 0x07, // 32 tick/sec
    INTR_PARAM  = 32  // ticks/intr (5sec)
  };
 
  uint8_t sentCounter;
  uint8_t receivedCounter;
  int8_t parentIndex;
  
  uint16_t parentAddress;
  uint8_t sendPending;
  uint8_t appSendPending;
  
  int16_t cacheAddr[NUM_ENTRIES];
  uint8_t cacheHopCount[NUM_ENTRIES];
  uint8_t cacheHeuristics[NUM_ENTRIES];
  
  uint8_t heardBitmask;
  uint8_t echoBitmask;

  uint16_t pingReceiveAddr;
  
  uint8_t *savedData;

  TOS_Msg dataBuf;
  TOS_MsgPtr msg;
  
 
  void prepare_route_msg() {
    int i;
    bap_msg* n_message = (bap_msg*)msg->data;
  
    n_message->dest = TOS_UART_ADDR;
    n_message->hop_src  = TOS_LOCAL_ADDRESS;
    n_message->src = TOS_LOCAL_ADDRESS;
    n_message->prev_src = TOS_LOCAL_ADDRESS;
    n_message->src_hop_distance = 0;
    
    for (i = 0; i < 20; i++) {
      n_message->data[i] = 0xee;
    }
  }
  

  inline void changeHeuristic(int findex, uint8_t changeAmount) {
    int changeAmountInt = (int) changeAmount;
    int heuristicInt = (int) cacheHeuristics[findex];
    int newAmount = changeAmountInt + heuristicInt;
    if (newAmount < 0)
      cacheHeuristics[findex] = 0;
    else if (newAmount > WORST_VALUE_HEURISTIC)
      cacheHeuristics[findex] = WORST_VALUE_HEURISTIC+1;
    else 
      cacheHeuristics[findex] = (char) newAmount;
  }
  
  // returns 1 if a parent was assigned, 0 otherwise
  inline char assignNewParent() {
    int i; 
    int bestIndex = -1;
    char bestHeuristic = WORST_VALUE_HEURISTIC + 1;
    
    for (i = 0; i < NUM_ENTRIES; i++) {
      if (cacheHeuristics[i] < bestHeuristic) {
	bestHeuristic = cacheHeuristics[i];
	bestIndex = i;
      }
    }
    
    if (bestIndex == -1) {
      // call Leds.yellowOff();
      // call Leds.greenOff();
      return 0;
    }
    else {
      parentIndex = bestIndex;
      if ((cacheAddr[bestIndex] == 1) || (cacheAddr[bestIndex] == 3)) {
	// call Leds.greenOn();
      }
      else {
	// call Leds.greenOff();
      }
      if ((cacheAddr[bestIndex] == 2) || (cacheAddr[bestIndex] == 3)) {
	// call Leds.yellowOn();
      }
      else {
	// call Leds.yellowOff();
      }
      return 1;
    }
  }
  
  
  inline void markHeard(short hopSource, short prevSource, char hopSourceHopDistance) {
    int i;
    int findex = -1;
    int replace_index = -1;
    char worst_heuristic = -1;
    
    for (i = 0; i < NUM_ENTRIES; i++) {
      if (cacheAddr[i] == hopSource) {
	findex = i;
	break;
      }
    }
    
    // hopSource already in cache
    if (findex != -1) {
      // if our parent's hop count increased, remove him as parent and remove his entry
      if ((hopSourceHopDistance > cacheHopCount[findex]) &&
	  (findex == parentIndex)) {
	cacheAddr[findex] = NO_MOTE;
	cacheHopCount[findex] = MAX_HOPS + 1;
	cacheHeuristics[findex] = WORST_VALUE_HEURISTIC + 1;
	parentIndex = NO_PARENT;
	echoBitmask &= (~(1 << findex));
	heardBitmask &= (~(1 << findex));      
      }
      // now check if hop_count increased past MAX_HOPS, if so, remove from cache
      else if (hopSourceHopDistance > MAX_HOPS) {
	cacheAddr[findex] = NO_MOTE;
	cacheHopCount[findex] = MAX_HOPS + 1;
	cacheHeuristics[findex] = WORST_VALUE_HEURISTIC + 1;
	echoBitmask &= (~(1 << findex));
	heardBitmask &= (~(1 << findex));
      }      
      // else, update the heuristic based on how much hop_count changed
      else {
	changeHeuristic(findex, hopSourceHopDistance - cacheHopCount[findex]);
	cacheHopCount[findex] = hopSourceHopDistance;
	if (prevSource == TOS_LOCAL_ADDRESS) 
	  echoBitmask |= (1 << findex);
	else 
	  heardBitmask |= (1 << findex);
      }
    }
    
    // we need to insert this entry into cache, only if hops_source_hop_distance
    // not as far as it should be
    else {
      if (!(hopSourceHopDistance > MAX_HOPS)) {
	for (i = 0; i < NUM_ENTRIES; i++) {
	  if ((parentIndex != i) && (cacheHeuristics[i] > worst_heuristic)) {
	    replace_index = i;
	    worst_heuristic = cacheHeuristics[i];
	  }
	  
	}
	
	// insert new info at replace_index
	cacheAddr[replace_index] = hopSource;
	cacheHopCount[replace_index] = hopSourceHopDistance;
	cacheHeuristics[replace_index] = hopSourceHopDistance;
	
	if (prevSource == TOS_LOCAL_ADDRESS)
	  echoBitmask |= (1 << replace_index);
	else
	  heardBitmask |= (1 << replace_index);
      }
    }
    
    if (parentIndex == NO_PARENT)
      assignNewParent();
  }
  
  command result_t StdControl.init() {
    int i;
    parentIndex = NO_PARENT;
    msg = &dataBuf;
    sendPending = 0;
    heardBitmask = 0;
    echoBitmask = 0;
    pingReceiveAddr = NO_PARENT;


   
    for (i = 0; i < NUM_ENTRIES; i++) {
      cacheAddr[i] = NO_MOTE;
      cacheHopCount[i] = MAX_HOPS + 1;
      cacheHeuristics[i] = WORST_VALUE_HEURISTIC + 1; 
    }
    
    call StdControlGenericComm.init();
    call StdControlBapPing.init();
    // call Leds.yellowOn();
    // call Leds.greenOn();


   return SUCCESS;
  }

  command result_t StdControl.start() {
    result_t res1 = call StdControlGenericComm.start();
    result_t res2 = call StdControlBapPing.start();

    // Issue clock interrupt once every 5 seconds
    call Timer.start(TIMER_REPEAT, 4096);

    return rcombine(res1, res2);
  }
  
  command result_t StdControl.stop() {
    result_t res1 = call StdControlGenericComm.stop();
    result_t res2 = call StdControlBapPing.stop();
    return rcombine(res1, res2);
  }
  
  task void evalCounterParent() {
    int i;
    int j;
    char heardTemp = 0;
    char echoTemp = 0;

    // if the node has a parent and it's time to send it a ping, do so
    if ((((sentCounter + receivedCounter) % 16) == COUNT_TO_SEND_PING) &&
	(parentIndex != NO_PARENT)) 
      call Ping.send(cacheAddr[(int)parentIndex], 0);
    
    // update heuristics based on heard and echo indices!
    if (((sentCounter + receivedCounter) % 5) == EVAL_HEURISTICS) {
      for (i = 0; i < NUM_ENTRIES; i++) {
	if (cacheAddr[i] != NO_MOTE) {
	
	  // if my parent node's heuristic exceeded TIMEOUT_HEURISTIC, remove from cache and as parent
	  // and clear cache
	  if ((cacheHeuristics[i] > TIMEOUT_HEURISTIC) &&
	      (parentIndex == i)) {
	    parentIndex = NO_PARENT;
	  
	    for (j = 0; j < NUM_ENTRIES; j++) {
	      cacheAddr[j] = NO_MOTE;
	      cacheHopCount[j] = MAX_HOPS + 1;
	      cacheHeuristics[j] = WORST_VALUE_HEURISTIC + 1; 
	    }
	    echoBitmask = 0;
	    heardBitmask = 0;
	    
	  }
	  // if this node's heuristic exceeded TIMEOUT_HEURISTIC, remove from cache
	  else if (cacheHeuristics[i] > TIMEOUT_HEURISTIC) {
	    cacheAddr[i] = NO_MOTE;
	    cacheHopCount[i] = MAX_HOPS + 1;
	    cacheHeuristics[i] = WORST_VALUE_HEURISTIC + 1;
	    echoBitmask &= (~(1 << i));
	    heardBitmask &= (~(1 << i));
	  }
	  // else, simply update the heuristic value based on heard and echo bitmasks
	  else {
	    if (heardBitmask & (1 << i)) 
	      heardTemp = 1; 
	    else 
	      heardTemp = 0;
	    if (echoBitmask & (1 << i))
	      echoTemp = 1;
	    else
	      echoTemp = 0;
	  }
	  changeHeuristic(i, ECHO_SCALAR*echoTemp + HEARD_SCALAR*heardTemp + LONGEVITY_INCREMENT);    
	}
      }
      
      echoBitmask = 0;
      heardBitmask = 0;
    }
    
    if ((sentCounter + receivedCounter) == EVAL_PARENT) {
      assignNewParent();
      sentCounter = 0;
      receivedCounter = 0;
    }
  }

  task void sendDoneCallback() {
    signal SendData.sendDone(savedData, SUCCESS);
  }


  command result_t SendData.send(uint8_t* data, uint8_t len) {
    if(call IsBaseStation.isBase() == TRUE) {
      if(post sendDoneCallback()) {
	signal Receive.receive(NULL, data, len);
	savedData = data;
	return SUCCESS;
      } else {
	return FAIL;
      }
    } else {
      int i;
      bap_msg* n_message = (bap_msg*)(msg->data);
    
      len = (len > 21)? 21 : len;
  
    
      if ((sendPending == 1) || !call active()) {
	//do nothing
      }
      else {
	n_message->dest = cacheAddr[(int)parentIndex];
	n_message->hop_src = TOS_LOCAL_ADDRESS;
	n_message->prev_src = TOS_LOCAL_ADDRESS;
	n_message->src = TOS_LOCAL_ADDRESS;
	n_message->src_hop_distance = (cacheHopCount[(int)parentIndex] + 1);
      

      
	for (i = 0; i < len; i++) 
	  n_message->data[i] = data[i];
      
	if (SUCCESS == call SendMsgGenericComm.send((uint16_t) TOS_BCAST_ADDR, sizeof(bap_msg), msg)) {
	  // call Leds.redOn();
	  sendPending = 1;
	  appSendPending = 1;
	  return SUCCESS;
	}
      }
    
      return FAIL;
    }
  }

  command result_t active() {
    return parentIndex != NO_PARENT;}

  default event TOS_MsgPtr Receive.receive(TOS_MsgPtr my_msg, void* payload, uint16_t payloadLen) {
    return my_msg;
  }

  // modified to support base stations
  event TOS_MsgPtr ReceiveMsgGenericComm.receive(TOS_MsgPtr smsg) {
    bap_msg* n_message = (bap_msg*)smsg->data;
    TOS_MsgPtr tmp;

    //call Leds.redToggle();
    // I received a message, update receivedCounter
    receivedCounter += 1;
    
    if(call IsBaseStation.isBase() == TRUE) {
      return (signal Receive.receive(smsg, n_message->data, BAP_DATA_LEN));
    }
    else {
      post evalCounterParent();
      
    
      // update cache
      markHeard(n_message->hop_src, n_message->prev_src, n_message->src_hop_distance);
      
      if ((parentIndex != NO_PARENT) && (n_message->dest == TOS_LOCAL_ADDRESS && sendPending == 0)) {
	n_message->dest = cacheAddr[(int) parentIndex];
	n_message->prev_src = n_message->hop_src;
	n_message->hop_src = TOS_LOCAL_ADDRESS;
	n_message->src_hop_distance = (cacheHopCount[(int) parentIndex] + 1);
	if (SUCCESS == call SendMsgGenericComm.send(TOS_BCAST_ADDR, sizeof(bap_msg), smsg)) {
	  // call Leds.redOn();
	  sendPending = 1;
	  tmp = msg;
	  msg = smsg;
	  return tmp;
	}
      }
      return smsg;
    }
  }  
  
  task void incrementSendCounter() {
    sentCounter += 1;
  }


  event result_t SendMsgGenericComm.sendDone(TOS_MsgPtr data, result_t success) {  
    sendPending = 0;
    // call Leds.redOff();
    post incrementSendCounter();
    post evalCounterParent();
    if (appSendPending) {
      signal SendData.sendDone((uint8_t*) ((bap_msg*)data->data)->data, success);
      appSendPending = 0;
    }
    return success;
  }

  task void pingReceivedUpdate() {
    if ((parentIndex == NO_PARENT) || (pingReceiveAddr != cacheAddr[(int)parentIndex])) {
    }
    else {
      echoBitmask |= (1 << parentIndex);
      heardBitmask |= (1 << parentIndex);
    }
    return;
  }

  event result_t Ping.pingResponse(uint16_t moteID, uint8_t sequence) {
    pingReceiveAddr = moteID;
    post pingReceivedUpdate();
    return SUCCESS;
  }

  event result_t Ping.pingReceive(uint16_t moteID, uint8_t sequence) {
    return SUCCESS ;
  }

  event result_t Timer.fired() {
    //if is the base, then it should send out the route update.   
    if((call IsBaseStation.isBase() == TRUE) &&
       (sendPending == 0)) {
      prepare_route_msg();

      if (SUCCESS == call SendMsgGenericComm.send((short)TOS_BCAST_ADDR, sizeof(bap_msg), msg)) {
	// call Leds.redOn();
	sendPending = 1;
      }
    }
    
    return SUCCESS;
  }
}


