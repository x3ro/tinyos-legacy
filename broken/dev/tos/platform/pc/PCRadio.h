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
#include "rfm_space_model.h"

typedef struct {
  long long time;
  short moteID;
  TOS_Msg msg;
} InRadioMsg;

typedef struct {
  long long time;
  short moteID;
  char bit;
} OutRadioBitMsg;

typedef struct {
  long long time;
  short moteID;
  char data[42] ;
} OutRadioMsg;

typedef struct {
  short receiver;
  TOS_Msg msg;
} incoming_radio_data_t;


int writeOutRadioBit(long long ftime, short moteID, char bit) {
  OutRadioBitMsg msg;
  if (outRadioBitFD >= 0) {
    msg.time = htonll(ftime);
    msg.moteID = htons(moteID);
    msg.bit = bit & 0x01;
    write(outRadioBitFD, &msg, sizeof(msg));
    return 1;
  }
  else {
    return 0;
  }
}

int writeOutRadioPacket(long long ftime, short moteID, char* data, int length) {
  int i, j;
  OutRadioMsg msg;
  if (length > sizeof(TOS_Msg)) {
    dbg_clear(DBG_SIM, "SIM: Write of data message longer than 36 bytes attempted. Truncated to 36 bytes.\n");
  }
  if ((outRadioFD >= 0) || (outRTRadioFD >= 0)) {
    // Crap to cut out signal strength
    int dataLen = (length > (sizeof(TOS_Msg)))? (sizeof(TOS_Msg)):length;
    msg.time = htonll(ftime);
    msg.moteID = htons(moteID);
    memcpy(&(msg.data), data, dataLen);
    
    //dbg_clear(DBG_SIM, "SIM: Writing out %i bytes of data as a radio packet message.\n", sizeof(msg));
    
    if (outRadioFD >= 0) {
      write(outRadioFD, &msg, sizeof(msg));
      read(outRadioFD, &msg, 1);
    }
    if (outRTRadioFD >= 0) {
      i = write(outRTRadioFD, &msg, sizeof(msg));
      j = read(outRTRadioFD, &msg, 1);
      if ((i == -1)  || (j == -1)) {
	dbg(DBG_SIM, "SIM: Closing socket for real-time radio out.\n");

	close(outRTRadioFD);
	
	pthread_mutex_lock(&rtWriteClientLock);
	outRTRadioFD = -1;
	pthread_cond_signal(&rtWriteClientCond);
	pthread_mutex_unlock(&rtWriteClientLock);
      }
    }
    return 1;
  }
  
  else if (rawOutRadioFD >= 0) {
    TOS_MsgPtr ptr = (TOS_MsgPtr)data;
    ptr->addr = TOS_UART_ADDR;
    write(rawOutRadioFD, data, sizeof(TOS_Msg) -2);
    return 1;
  }
  else {
    return 0;
  }
}

void event_radio_in_handle(event_t* event,
			   struct TOS_state* state);

void event_radio_in_create(event_t* event,
			   long long ftime,
			   short receiver,
			   TOS_MsgPtr msg) {
  incoming_radio_data_t* data = (incoming_radio_data_t*)malloc(sizeof(incoming_radio_data_t));
  dbg_clear(DBG_MEM, "SIM: malloc incoming radio event data\n");
  data->receiver = receiver;
  memcpy(&(data->msg), msg, sizeof(TOS_Msg));
  
  event->mote = receiver;
  event->pause = 1;
  event->data = data;
  event->time = ftime;
  event->handle = event_radio_in_handle;
  event->cleanup = event_total_cleanup;
}

TOS_MsgPtr NIDO_received(TOS_MsgPtr packet);

void event_radio_in_handle(event_t* event,
				  struct TOS_state* state) {
    incoming_radio_data_t* data = (incoming_radio_data_t*)event->data;
    if (dbg_active(DBG_SIM)) {
      char thetime[128];
      printTime(thetime, 128);
      dbg(DBG_SIM, "external_comm: Mote receiving injected packet at time %s.\n", thetime);
    }
    NIDO_received(&(data->msg));
}

int readMsg(int sfd, InRadioMsg* msg) {
  int size = sizeof(InRadioMsg) - 4; // Nasty hack to get around signal strength and time;
  int len = 0;
  char* ptr = (char*)msg;

  // we also want to ignore the ack, but the problem is, the number of bytes we read in
  // is determined by a call to sizeof(InRadioMsg).  Since some compilers pad bytes, ie, for
  // ack since it is only a byte, the compiler might add in a byte to the struct. As a result
  // the size of the struct is now 52 when in reality it should be only 51
  if (sizeof(InRadioMsg) == 52)
    size -= 2;
  else if (sizeof(InRadioMsg) == 51)
    size -= 1;
  
  
  while (len < size) {
    int rval;
    dbg(DBG_SIM, "SIM: Read from real-time port, total: %i, need %i\n", len, size);
    rval  = read(sfd, ptr + len, size - len);
    if (rval < 0) {
      dbg_clear(DBG_ERROR, "SIM: Error reading from RT radio stream. Terminating reading thread. Error: %s\n", strerror(errno));
      return -1;
    }
    else if (rval == 0) {
      return -1;
    }
    len += rval;
  }

  return 0;
}

void* rtConnectRadioWrite(void* arg) {
  int sfd = *((int*)arg);
  struct sockaddr_in client;
  int size = sizeof(client);
  outRTRadioFD = accept(sfd, (struct sockaddr*)&client, &size);
  dbg_clear(DBG_SIM, "SIM: Opened connection for real time Radio output fd = %i.\n", outRTRadioFD);
  
  while (1) {
    pthread_mutex_lock(&rtWriteClientLock);
    if (outRTRadioFD >= 0) {
	pthread_cond_wait(&rtWriteClientCond,&rtWriteClientLock);  
    }
    
    pthread_mutex_unlock(&rtWriteClientLock);
    
    outRTRadioFD = accept(sfd, (struct sockaddr*)&client, &size);
    dbg_clear(DBG_SIM, "SIM: Opened connection for real time Radio output fd = %i.\n", outRTRadioFD);
    
  }
  dbg(DBG_SIM, "SIM: Real Time Radio Write port connected.\n");
  
}
  

void* rtRadioRead(void* arg) {
  InRadioMsg msg;
  event_t* event;
  
  int sfd = *((int*)arg);
  
  while(1) {
    int clientFD, valid;
    struct sockaddr_in client;
    int size = sizeof(client);
    
    clientFD = accept(sfd, (struct sockaddr*)&client, &size);
    valid = (clientFD >= 0)? 1:0;

    while(valid) {
      int rval = readMsg(clientFD, &msg);
      dbg(DBG_SIM, "SIM: Read in message.\n");
      if (rval >= 0) {
	msg.time = ntohll(msg.time);
	if (msg.time < tos_state.tos_time) {
	  msg.time = tos_state.tos_time;
	}
	msg.moteID = ntohs(msg.moteID);
	
	event = (event_t*)malloc(sizeof(event_t));
	dbg_clear(DBG_MEM, "SIM: malloc radio input event.\n");
	event_radio_in_create(event, msg.time, msg.moteID, &(msg.msg)); 
	TOS_queue_insert_event(event);

	if (dbg_active(DBG_SIM)) {
	  char ftime[128];
	  printOtherTime(ftime, 128, msg.time);
	  dbg_clear(DBG_SIM, "SIM: Inserted incoming radio message at time %s\n", ftime);
	}
      }
      else {
	dbg(DBG_SIM, "SIM: Closing socket.\n");
	valid = 0;
	close(clientFD);
      }
    }
  }
  
  return NULL;
}

int readInRadioMessages() {
  if (inRadioFD >= 0) {
    int len;
    InRadioMsg msg;
    event_t* event;
    
    while(1) {
      char* ptr = (char*)&msg;
      len = 2; // Nasty hack to get around lack of signal strength at the end
      while (len < sizeof(InRadioMsg)) {
	int count = read(inRadioFD, ptr, sizeof(InRadioMsg) - len);
	if (count == 0) {
	  return 1;
	}
	if (count == -1) {
	  return 0;
	}
	
	ptr += count;
	len += count;
      }

      msg.time = htonll(msg.time);
      msg.moteID = htons(msg.moteID);
      
      event = (event_t*)malloc(sizeof(event_t));
      dbg_clear(DBG_MEM, "SIM: malloc radio message input event.\n");
      event_radio_in_create(event, msg.time, msg.moteID, &(msg.msg)); 
      TOS_queue_insert_event(event);
      dbg_clear(DBG_SIM, "SIM: Inserted incoming radio message at time %lli\n", msg.time);
    }
  }
  else {
    dbg_clear(DBG_SIM, "SIM: external_comm: No incoming radio messages.\n");
  }

  return 1;
}

#include "rfm_model.c"
#include "rfm_space_model.c"


