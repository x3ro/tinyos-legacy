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

#include <pthread.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <stdlib.h>

#if __BYTE_ORDER == __BIG_ENDIAN
#  define htonll(x) (x)
#  define ntohll(x) (x)
#else
#  if __BYTE_ORDER == __LITTLE_ENDIAN
#    define htonll(x) __bswap_64(x)
#    define ntohll(x) __bswap_64(x)
#  endif
#endif


const short radioInPort  =    RADIO_IN_PORT;
const short radioOutPort =    RADIO_OUT_PORT;
const short radioBitOutPort = RADIO_BIT_OUT_PORT;
const short radioRTInPort =   RADIO_RT_PORT; // Server socket
const short uartInPort   =    UART_IN_PORT;
const short uartOutPort  =    UART_OUT_PORT;
const short loggingPort  =    LOGGING_PORT; //Server socket
const short radioRawOutPort = RADIO_RAW_OUT_PORT;

#define localAddr INADDR_LOOPBACK

int inUARTFD        = -1;
int outUARTFD       = -1;
int inRadioFD       = -1;
int outRadioFD      = -1;
int outRadioBitFD   = -1;
int inRTRadioFD     = -1;
int loggingFD       = -1;
int loggingClientFD = -1;
int rawOutRadioFD   = -1;

pthread_t radioThread;
pthread_t loggingThread;
pthread_mutex_t logFDLock;

extern short TOS_LOCAL_ADDRESS;

int createSocket(short port);
int createServerSocket(short port);
void* rtRadioRead(void* arg);
void* loggingAccept(void* arg);

char injectedBitmask [] = {0x00, 0x00, 0x00, 0x00, 0x00};

int loggingPause;

void initializeSockets() {
  initializeIncomingUART();
  initializeOutgoingUART();
  initializeIncomingRadio();
  initializeIncomingRTRadio();
  initializeOutgoingRadio();
  initializeOutgoingBitRadio();
  initializeOutgoingRawRadio();
}

int initializeIncomingUART() {
  inUARTFD = createSocket(uartInPort);

  if (inUARTFD >= 0) {
    dbg_clear(DBG_SIM, ("SIM: Incoming UART messages initialized at fd %i.\n", inUARTFD));
  }
  return 1;
}

int initializeOutgoingUART() {
  outUARTFD = createSocket(uartOutPort);

  if (outUARTFD >= 0) {
    dbg_clear(DBG_SIM, ("SIM: Outgoing UART messages initialized.\n"));
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
    dbg_clear(DBG_SIM, ("SIM: Incoming radio messages initialized at fd %i.\n", inRadioFD));
    return 1;
  }
  else {
    return 0;
  }
}

// Need to change to server socket for after-start connection capability.

int initializeIncomingRTRadio() {
  dbg_clear(DBG_SIM, ("SIM: Creating server socket for dynamic packet injection.\n"));
  
  inRTRadioFD = createServerSocket(radioRTInPort);

  if (inRTRadioFD >= 0) {
    pthread_create(&radioThread, NULL, rtRadioRead, &inRTRadioFD);
    dbg_clear(DBG_SIM, ("SIM: Incoming radio messages initialized at fd %i.\n", inRTRadioFD));
    return 1;
  }
  else {
    return 0;
  }
}


int initializeOutgoingRadio() {
  outRadioFD = createSocket(radioOutPort);

  if (outRadioFD >= 0) {
    dbg_clear(DBG_SIM, ("SIM: Outgoing radio messages initialized at fd %i.\n", outRadioFD));
    return 1;
  }
  else {
    return 0;
  }
}

int initializeOutgoingRawRadio() {
  rawOutRadioFD = createSocket(radioRawOutPort);

  if (rawOutRadioFD >= 0) {
    dbg_clear(DBG_SIM, ("SIM: Outgoing raw radio messages initialized at fd %i.\n", outRadioFD));
    return 1;
  }
  else {
    return 0;
  }
}


int initializeOutgoingBitRadio() {
  outRadioBitFD = createSocket(radioBitOutPort);

  if (outRadioBitFD >= 0) {
    dbg_clear(DBG_SIM, ("SIM: Outgoing radio messages initialized at fd %i.\n", outRadioBitFD));
    return 1;
  }
  else {
    return 0;
  }
}

int initializeInvocationLogging() {
  loggingFD = createServerSocket(loggingPort);
  if (inRTRadioFD >= 0) {
    loggingAccept(&loggingFD);
    //pthread_create(&loggingThread, NULL, loggingAccept, &loggingFD);
    dbg_clear(DBG_SIM, ("SIM: Invocation logger initialized at fd %i.\n", (int)loggingFD));
    return 1;
  }
  else {
    return 0;
  }

  loggingPause = 0;
}
int createServerSocket(short port) {
  struct sockaddr_in sock;
  int fd;
  int rval = -1;
  
  memset(&sock, 0, sizeof(sock));
  sock.sin_family = AF_INET;
  sock.sin_port = htons(port);
  sock.sin_addr.s_addr = htonl(localAddr);

  fd = socket(AF_INET, SOCK_STREAM, 0);
  if (fd < 0) {
    dbg_clear(DBG_SIM|DBG_ERROR, ("SIM: Could not create server socket: %s\n", strerror(errno)));
    return -1;
  }

  while(rval < 0) {
    rval = bind(fd, (struct sockaddr*)&sock, sizeof(sock));
    if (rval < 0) {
      dbg_clear(DBG_SIM|DBG_ERROR, ("SIM: Could not bind server socket to port %i: %s\n", (int)port, strerror(errno)));
      dbg_clear(DBG_SIM|DBG_ERROR, ("SIM: Will retry in 10 seconds.\n"));
      sleep(10);
    }
  }

  listen(fd, 1);

  dbg_clear(DBG_SIM, ("SIM: Created server socket listening on port %i.\n", (int)port));
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
    dbg_clear(DBG_ERROR, ("SIM: Could not create incoming socket to port %i. Error: %s \n", (int)port, strerror(errno)));
    return -1;
  }

  rval = connect(fd, (struct sockaddr*)&sock, sizeof(sock));
  if (rval < 0) {
    close(fd);
    dbg_clear(DBG_SIM, ("SIM: Could not initiate connection to port %i for messages.\n", (int)port));
    return -1;
  }

  dbg_clear(DBG_SIM, ("SIM: Socket to port %i initialized at fd %i.\n", (int)port, fd));
  
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
      dbg_clear(DBG_MEM, ("SIM: malloc radio message input event.\n"));
      event_radio_in_create(event, msg.time, msg.moteID, &(msg.msg)); 
      TOS_queue_insert_event(event);
      dbg_clear(DBG_SIM, ("SIM: Inserted incoming radio message at time %lli\n", msg.time));
    }
  }
  else {
    dbg_clear(DBG_SIM, ("SIM: external_comm: No incoming radio messages.\n"));
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
  if (length > sizeof(TOS_Msg)) {
    dbg_clear(DBG_SIM, ("SIM: Write of data message longer than 36 bytes attempted. Truncated to 36 bytes.\n"));
  }
  if (outRadioFD >= 0) {
    // Crap to cut out signal strength
    int dataLen = (length > (sizeof(TOS_Msg)-2))? (sizeof(TOS_Msg)-2):length;
    msg.time = htonll(time);
    msg.moteID = htons(moteID);
    memcpy(&(msg.data), data, dataLen);

    //dbg_clear(DBG_SIM, ("SIM: Writing out %i bytes of data as a radio packet message.\n", sizeof(msg)));
    
    write(outRadioFD, &msg, sizeof(msg) - 2);
    read(outRadioFD, &msg, 1);
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

void event_radio_in_create(event_t* event,
			   long long time,
			   short receiver,
			   TOS_MsgPtr msg) {
  incoming_radio_data_t* data = (incoming_radio_data_t*)malloc(sizeof(incoming_radio_data_t));
  dbg_clear(DBG_MEM, ("SIM: malloc incoming radio event data\n"));
  data->receiver = receiver;
  memcpy(&(data->msg), msg, sizeof(TOS_Msg));
  
  event->mote = receiver;
  event->pause = 1;
  event->data = data;
  event->time = time;
  event->handle = event_radio_in_handle;
  event->cleanup = event_total_cleanup;
}

#ifdef PACKET_RX_PACKET_DONE_EVENT
char PACKET_RX_PACKET_DONE_EVENT(TOS_MsgPtr ptr);
#endif

void event_radio_in_handle(event_t* event,
				  struct TOS_state* state) {
  // This is nasty kludge so non-networked apps will link -pal
#ifdef PACKET_RX_PACKET_DONE_EVENT
  incoming_radio_data_t* data = (incoming_radio_data_t*)event->data;
  if (dbg_active(DBG_SIM)) {
    char time[128];
    printTime(time, 128);
    dbg(DBG_SIM, ("external_comm: Mote receiving injected packet at time %s.\n", time));
  }
  TOS_SIGNAL_EVENT(PACKET_RX_PACKET_DONE)(&(data->msg));
#endif

}

int readMsg(int fd, InRadioMsg* msg) {
  int size = sizeof(InRadioMsg) - 2; // Nasty hack to get around signal str
  int len = 0;
  char* ptr = (char*)msg;

  while (len < size) {
    int rval;
    dbg(DBG_SIM, ("SIM: Read from real-time port, total: %i, need %i\n", len, size));
    rval  = read(fd, ptr + len, size - len);
    if (rval < 0) {
      dbg_clear(DBG_ERROR, ("SIM: Error reading from RT radio stream. Terminating reading thread. Error: %s\n", strerror(errno)));
      return -1;
    }
    else if (rval == 0) {
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
    
    clientFD = accept(fd, (struct sockaddr*)&client, &size);
    valid = (clientFD >= 0)? 1:0;

    while(valid) {
      int rval = readMsg(clientFD, &msg);
      dbg(DBG_SIM, ("SIM: Read in message.\n"));
      if (rval >= 0) {
	msg.time = ntohll(msg.time);
	if (msg.time < tos_state.tos_time) {
	  msg.time = tos_state.tos_time;
	}
	msg.moteID = ntohs(msg.moteID);
	
	event = (event_t*)malloc(sizeof(event_t));
	dbg_clear(DBG_MEM, ("SIM: malloc radio input event.\n"));
	event_radio_in_create(event, msg.time, msg.moteID, &(msg.msg)); 
	TOS_queue_insert_event(event);

	if (dbg_active(DBG_SIM)) {
	  char time[128];
	  printOtherTime(time, 128, msg.time);
	  dbg_clear(DBG_SIM, ("SIM: Inserted incoming radio message at time %s\n", time));
	}
      }
      else {
	dbg(DBG_SIM, ("SIM: Closing socket.\n"));
	valid = 0;
	close(clientFD);
      }
    }
  }
  
  return NULL;
}

void* loggingAccept(void* arg) {
  int valid;
  struct sockaddr_in client;
  int fd = *((int*)arg);
  int size = sizeof(client);

  valid = 0;

  while (!valid) {
    pthread_mutex_lock(&logFDLock);
    loggingClientFD = accept(fd, (struct sockaddr*)&client, &size);
    valid = (loggingClientFD >= 0)? 1:0;
    pthread_mutex_unlock(&logFDLock);
  }
  
  return NULL;
}

void setLoggingPause(int pause) {
  loggingPause = pause;
}


int notifyTaskPosted(char* task) {
  if (loggingFD < 0 || NODE_NUM != 0) {return 0;}
  
  if (loggingClientFD >= 0 && tos_state.current_node == 0) {
    char buf[1024];
    int len = sprintf(buf, "%lli %s\n", tos_state.tos_time, task);

    //tos_state.tos_time++;
    
    len = write(loggingClientFD, buf, len);
    if (len <= 0) {
      loggingClientFD = -1;
      pthread_create(&loggingThread, NULL, loggingAccept, &loggingFD);
    }
    len = read(loggingClientFD, buf, 1);
    if (len <= 0) {
      loggingClientFD = -1;
      pthread_create(&loggingThread, NULL, loggingAccept, &loggingFD);
    }
  }
  else {
    dbg(DBG_SIM, ("Task posted: %s\n", task));
  }
  if (loggingPause > 0) {
    //usleep(loggingPause);
  }
  
  return 0;
}

int notifyEventSignaled(char* event) {
  if (loggingFD < 0 || NODE_NUM != 0) {return 0;}
  
  if (loggingClientFD >= 0 && tos_state.current_node == 0) {
    char buf[1024];
    int len = sprintf(buf, "%lli %s\n", tos_state.tos_time, event);

    //tos_state.tos_time++;
    
    len = write(loggingClientFD, buf, len);
    if (len <= 0) {
      loggingClientFD = -1;
      pthread_create(&loggingThread, NULL, loggingAccept, &loggingFD);
    }
    len = read(loggingClientFD, buf, 1);
    if (len <= 0) {
      loggingClientFD = -1;
      pthread_create(&loggingThread, NULL, loggingAccept, &loggingFD);
    }
  }
  else {
    dbg(DBG_SIM, ("Event signaled: %s\n", event));
  }

  if (loggingPause > 0) {
    //usleep(loggingPause);
  }
   
  return 0;
}

int notifyCommandCalled(char* command) {
  if (loggingFD < 0 || NODE_NUM != 0) {return 0;}
  
  if (loggingClientFD >= 0 && tos_state.current_node == 0) {
    char buf[1024];
    int len = sprintf(buf, "%lli %s\n", tos_state.tos_time, command);

    //tos_state.tos_time++;

    len = write(loggingClientFD, buf, len);
    if (len <= 0) {
      loggingClientFD = -1;
      pthread_create(&loggingThread, NULL, loggingAccept, &loggingFD);
    }
    len = read(loggingClientFD, buf, 1);
    if (len <= 0) {
      loggingClientFD = -1;
      pthread_create(&loggingThread, NULL, loggingAccept, &loggingFD);
    }
  }
  else {
    dbg(DBG_SIM, ("Command called: %s\n", command));	
  }
  if (loggingPause > 0) {
    //usleep(loggingPause);
  }
  return 0;
}

int printOtherTime(char* buf, int len, long long int time) {
  int hours;
  int minutes;
  int seconds;
  int secondBillionths;
  
  secondBillionths = (int)(time % (long long) 4000000);
  seconds = (int)(time / (long long) 4000000);
  minutes = seconds / 60;
  hours = minutes / 60;
  secondBillionths *= (long long) 25;
  seconds %= 60;
  minutes %= 60;
  
  return snprintf(buf, len, "%i:%i:%i.%08i", hours, minutes, seconds, secondBillionths);
}


int printTime(char* buf, int len) {
  return printOtherTime(buf, len, tos_state.tos_time);
}
