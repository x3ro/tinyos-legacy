/*									tab:4
 *
 *
 * "Copyright (c) 2001 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * Authors:		Philip Levis <pal@cs.berkeley.edu>
 *
 *
 */

/*
 *   FILE: external_comm.c
 * AUTHOR: pal
 *   DESC: Routines for communication with other processes.
 */

#include "tos.h"
#include "dbg.h"
#include "tossim.h"
#include "event_queue.h"
#include "external_comm.h"

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <byteswap.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <pthread.h>

#if __BYTE_ORDER == __BIG_ENDIAN
#  define htonll(x) (x)
#  define ntohll(x) (x)
#else
#  if __BYTE_ORDER == __LITTLE_ENDIAN
#    define htonll(x) __bswap_64(x)
#    define ntohll(x) __bswap_64(x)
#  endif
#endif


const short radioInPort  =    10576;
const short radioOutPort =    10577;
const short radioBitOutPort = 10578;
const short radioRTInPort =   10579; // Server socket
const short uartInPort   =    10580;
const short uartOutPort  =    10581;

#define localAddr INADDR_LOOPBACK

int inUARTFD        = -1;
int outUARTFD       = -1;
int inRadioFD       = -1;
int outRadioFD      = -1;
int outRadioBitFD   = -1;
int inRTRadioFD     = -1;

pthread_t radioThread;

extern short TOS_LOCAL_ADDRESS;

int createSocket(short port);
int createServerSocket(short port);
void* rtRadioRead(void* arg);


int initializeIncomingUART() {
  inUARTFD = createSocket(uartInPort);

  if (inUARTFD >= 0) {
    dbg(DBG_SIM, ("SIM: Incoming UART messages initialized at fd %i.\n", inUARTFD));
  }
  return 1;
}

int initializeOutgoingUART() {
  outUARTFD = createSocket(uartOutPort);

  if (outUARTFD >= 0) {
    dbg(DBG_SIM, ("SIM: Outgoing UART messages initialized.\n"));
    return 1;
  }
  else {
    return 0;
  }
}

int initializeIncomingRadio() {
  inRadioFD = createSocket(radioInPort);

  if (inRadioFD >= 0) {
    readInRadioMessages();
    dbg(DBG_SIM, ("SIM: Incoming radio messages initialized at fd %i.\n", inRadioFD));
    return 1;
  }
  else {
    return 0;
  }
}

// Need to change to server socket for after-start connection capability.

int initializeIncomingRTRadio() {
  inRTRadioFD = createServerSocket(radioRTInPort);

  if (inRTRadioFD >= 0) {
    pthread_create(&radioThread, NULL, rtRadioRead, &inRTRadioFD);
    dbg(DBG_SIM, ("SIM: Incoming radio messages initialized at fd %i.\n", inRadioFD));
    return 1;
  }
  else {
    return 0;
  }
}


int initializeOutgoingRadio() {
  outRadioFD = createSocket(radioOutPort);

  if (outRadioFD >= 0) {
    dbg(DBG_SIM, ("SIM: Outgoing radio messages initialized at fd %i.\n", outRadioFD));
    return 1;
  }
  else {
    return 0;
  }
}


int initializeOutgoingBitRadio() {
  outRadioBitFD = createSocket(radioBitOutPort);

  if (outRadioBitFD >= 0) {
    dbg(DBG_SIM, ("SIM: Outgoing radio messages initialized at fd %i.\n", outRadioBitFD));
    return 1;
  }
  else {
    return 0;
  }
}

int createServerSocket(short port) {
  struct sockaddr_in sock;
  int fd;
  int rval;
  
  memset(&sock, 0, sizeof(sock));
  sock.sin_family = AF_INET;
  sock.sin_port = htons(port);
  sock.sin_addr.s_addr = htonl(localAddr);

  fd = socket(AF_INET, SOCK_STREAM, 0);
  if (fd < 0) {
    printf("could not create socket: %s\n", strerror(errno));
    return -1;
  }

  rval = bind(fd, (struct sockaddr*)&sock, sizeof(sock));
  if (rval < 0) {
    printf("could not bind socket: %s", strerror(errno));
    return -1;
  }

  listen(fd, 1);

  printf("Created server socket listening on port %i.\n", (int)port);
  return fd;
}

int createSocket(short port) {
  struct sockaddr_in sock;
  int fd;
  int rval;
  
  memset(&sock, 0, sizeof(sock));
  sock.sin_family = AF_INET;
  sock.sin_port = htons(port);
  sock.sin_addr.s_addr = htonl(localAddr);

  fd = socket(AF_INET, SOCK_STREAM, 0);
  if (fd < 0) {
    dbg(DBG_ERROR, ("SIM: Could not create incoming socket to port %i. Error: %s \n", (int)port, strerror(errno)));
    return -1;
  }

  rval = connect(fd, (struct sockaddr*)&sock, sizeof(sock));
  if (rval < 0) {
    close(fd);
    dbg(DBG_ERROR, ("SIM: Could not initiate connection to port %i for messages.\n", (int)port));
    return -1;
  }

  dbg(DBG_SIM, ("SIM: Socket to port %i initialized at fd %i.\n", (int)port, inUARTFD));
  
  return fd;
}


int readInUARTMessages() {
  return 1;
}

int readInRadioMessages() {
  if (inRadioFD >= 0) {
    int len;
    InRadioMsg msg;
    event_t* event;
    
    while(1) {
      char* ptr = (char*)&msg;
      len = 0;
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
      event_radio_in_create(event, msg.time, msg.moteID, &(msg.msg)); 
      TOS_queue_insert_event(event);
      dbg(DBG_USR3, ("Inserted incoming radio message at time %lli\n", msg.time));
    }
  }
  else {
    dbg(DBG_SIM, ("external_comm: No incoming radio messages.\n"));
  }

  return 1;
}

int writeOutUartByte(long long time, short moteID, char value) {
  UartByteMsg msg;
  if (outUARTFD >= 0) {
    msg.time = htonll(time);
    msg.moteID = htons(moteID);
    msg.data = value;
    write(outUARTFD, &msg, sizeof(msg));
    return 1;
  }
  else {
    return 0;
  }
}

int writeOutRadioBit(long long time, short moteID, char bit) {
  OutRadioBitMsg msg;
  if (outRadioBitFD >= 0) {
    msg.time = htonll(time);
    msg.moteID = htons(moteID);
    msg.bit = bit & 0x01;
    write(outRadioBitFD, &msg, sizeof(msg));
    return 1;
  }
  else {
    return 0;
  }
}

int writeOutRadioPacket(long long time, short moteID, char* data, int length) {
  OutRadioMsg msg;
  if (length > 38) {
    dbg(DBG_SIM, ("Write of data message longer than 38 bytes attempted. Truncated to 38 bytes.\n"));
  }
  if (outRadioFD >= 0) {
    int dataLen = (length > 38)? 38:length;
    msg.time = htonll(time);
    msg.moteID = htons(moteID);
    memcpy(&(msg.data), data, dataLen);
    dbg(DBG_USR1, ("data len: %i\n", dataLen));
    dbg(DBG_USR1, ("msg size: %i\n", sizeof(msg)));
    write(outRadioFD, &msg, sizeof(msg));
    read(outRadioFD, &msg, 1);
    dbg(DBG_USR1, ("Writing out this data:"));
    {
      int i;
      for (i = 0; i < 38; i++) {
	if (i % 20 == 0) {dbg(DBG_USR1, ("\n"));}
	dbg(DBG_USR1, ("%x ", (int)(msg.data[i] & 0xff)));
      }
      dbg(DBG_USR1, ("\n"));
    }
    return 1;
  }
  else {
    return 0;
  }
}

void event_radio_in_create(event_t* event,
			   long long time,
			   short receiver,
			   TOS_MsgPtr msg) {
  incoming_radio_data_t* data = (incoming_radio_data_t*)malloc(sizeof(incoming_radio_data_t));
  data->receiver = receiver;
  memcpy(&(data->msg), msg, sizeof(TOS_Msg));
  
  event->mote = receiver;
  event->pause = 1;
  event->data = data;
  event->time = time;
  event->handle = event_radio_in_handle;
  event->cleanup = event_total_cleanup;
}

void event_radio_in_handle(event_t* event,
				  struct TOS_state* state) {
  incoming_radio_data_t* data = (incoming_radio_data_t*)event->data;
  TOS_SIGNAL_EVENT(AM_RX_PACKET_DONE)(&(data->msg));
  dbg(DBG_USR3, ("Sent packet from init to mote %i\n", (int)event->mote));
}

int readMsg(int fd, InRadioMsg* msg) {
  int size = sizeof(InRadioMsg);
  int len = 0;
  char* ptr = (char*)msg;

  while (len < size) {
    int rval  = read(fd, ptr + len, size - len);
    if (rval < 0) {
      dbg(DBG_ERROR, ("Error reading from RT radio stream. Terminating reading thread. Error: %s\n", strerror(errno)));
      return -1;
    }
    len += rval;
  }

  return 0;
}

void* rtRadioRead(void* arg) {
  InRadioMsg msg;
  event_t* event;
  
  int fd = *((int*)arg);
  
  while(1) {
    int clientFD, valid;
    struct sockaddr_in client;
    int size = sizeof(client);

    dbg(DBG_USR2, ("Waiting for real-time radio connection."));
    clientFD = accept(fd, (struct sockaddr*)&client, &size);
    dbg(DBG_USR2, ("Connection made from %i\n", (int)ntohs(client.sin_port)));
    valid = (clientFD >= 0)? 1:0;

    while(valid) {
      int rval = readMsg(clientFD, &msg);
      if (rval >= 0) {
	msg.time = ntohll(msg.time);
	if (msg.time < tos_state.tos_time) {
	  msg.time = tos_state.tos_time;
	}
	msg.moteID = ntohs(msg.moteID);
	
	event = (event_t*)malloc(sizeof(event_t));
	event_radio_in_create(event, msg.time, msg.moteID, &(msg.msg)); 
	TOS_queue_insert_event(event);
	dbg(DBG_USR3, ("Inserted incoming radio message at time %lli\n", msg.time));
      }
      else {
	valid = 0;
	close(clientFD);
      }
    }
  }
  
  return NULL;
}
