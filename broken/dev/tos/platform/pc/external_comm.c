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


#if __BYTE_ORDER == __BIG_ENDIAN
#  define htonll(x) (x)
#  define ntohll(x) (x)
#else
#  if __BYTE_ORDER == __LITTLE_ENDIAN
#    define htonll(x) __bswap_64(x)
#    define ntohll(x) __bswap_64(x)
#  endif
#endif


const short radioInPort  =    RADIO_IN_PORT; // Need this - should be a server socket -ri simulator blocks until client closes 
const short radioOutPort =    RADIO_OUT_PORT; // Need this -ro 
const short radioBitOutPort = RADIO_BIT_OUT_PORT; // Don't need this
const short radioRTInPort =   RADIO_RT_IN_PORT; // Server socket // Need this
const short radioRTOutPort =  RADIO_RT_OUT_PORT; 
const short uartInPort   =    UART_IN_PORT; // Don't need this
const short uartOutPort  =    UART_OUT_PORT; // Don't need this
const short loggingPort  =    LOGGING_PORT; //Server socket // Need this
const short radioRawOutPort = RADIO_RAW_OUT_PORT; // Don't need this

#define localAddr INADDR_LOOPBACK

int inUARTFD        = -1;
int outUARTFD       = -1;
int inRadioFD       = -1;
int outRadioFD      = -1;
int outRadioBitFD   = -1;
int inRTRadioFD     = -1;
int outRTRadioFD    = -1;
int outRTRadioServerFD = -1;
int loggingFD       = -1;
int loggingClientFD = -1;
int rawOutRadioFD   = -1;

pthread_t radioRTReadThread;
pthread_t radioWriteThread;
pthread_t loggingThread;
pthread_mutex_t logFDLock;
pthread_mutex_t rtWriteClientLock;
pthread_cond_t rtWriteClientCond;

int createSocket(short port);
int createServerSocket(short port);
int createServerSocketAndWait(short port);
void* rtRadioRead(void* arg);
void* rtConnectRadioWrite(void* arg);
void* loggingAccept(void* arg);

char injectedBitmask [] = {0x00, 0x00, 0x00, 0x00, 0x00};

int loggingPause;

int readInRadioMessages();

// this method takes as input from MAIN.c radio_in_port and radio_out_port
// for user specified port numbers 
void initializeSockets() {
  //initializeIncomingUART();
  //initializeOutgoingUART();
  initializeIncomingRTRadio();
  initializeOutgoingRTRadio();
  //initializeOutgoingBitRadio();
  //initializeOutgoingRawRadio();
}

int initializeIncomingUART() {
  inUARTFD = createSocket(uartInPort);

  if (inUARTFD >= 0) {
    dbg_clear(DBG_SIM, "SIM: Incoming UART messages initialized at fd %i.\n", inUARTFD);
  }
  return 1;
}

int initializeOutgoingUART() {
  outUARTFD = createSocket(uartOutPort);

  if (outUARTFD >= 0) {
    dbg_clear(DBG_SIM, "SIM: Outgoing UART messages initialized.\n");
    return 1;
  }
  else {
    return 0;
  }
}

int initializeIncomingRadio(int radio_in_port) {
  int portToUse = radioInPort;
  
  if (radio_in_port != -1) 
    portToUse = radio_in_port;
  
  inRadioFD = createServerSocketAndWait(portToUse);
  if (inRadioFD >= 0) {
    readInRadioMessages();
    dbg_clear(DBG_SIM, "SIM: Incoming radio messages initialized at fd %i.\n", inRadioFD);
    return 1;
  }
  else {
    return 0;
  }
}

// Need to change to server socket for after-start connection capability.

int initializeIncomingRTRadio() {
  char ftime[128];
  dbg_clear(DBG_SIM, "SIM: Creating server socket for dynamic packet injection.\n");
  
  inRTRadioFD = createServerSocket(radioRTInPort);

  if (inRTRadioFD >= 0) {
    pthread_create(&radioRTReadThread, NULL, rtRadioRead, &inRTRadioFD);
    printTime(ftime,128);
    dbg_clear(DBG_SIM, "SIM: Real-time incoming radio message reader thread spawned at %s.\n", ftime);
    return 1;
  }
  else {
    return 0;
  }
}

int initializeOutgoingRTRadio() {
    char ftime[128];
    dbg_clear(DBG_SIM, "SIM: Creating server socket for dynamic Radio Output Connection.\n");
    
    pthread_cond_init(&rtWriteClientCond,NULL);
    outRTRadioServerFD = createServerSocket(radioRTOutPort);
    
    if (outRTRadioServerFD >= 0) {
	pthread_create(&radioWriteThread, NULL, rtConnectRadioWrite, &outRTRadioServerFD);
	printTime(ftime,128);
	dbg_clear(DBG_SIM, "SIM: Real-time outgoing radio message thread spawned at %s.\n", ftime);
	return 1;
    }
    else {
	return 0;
    }
}


int initializeOutgoingRadio(int radio_out_port) {
  int portToUse = radioOutPort;

  if (radio_out_port != -1)
    portToUse = radio_out_port;
  
  outRadioFD = createServerSocketAndWait(portToUse);

  if (outRadioFD >= 0) {
    dbg_clear(DBG_SIM, "SIM: Outgoing radio messages initialized at fd %i.\n", outRadioFD);
    return 1;
  }
  else {
    return 0;
  }
}

int initializeOutgoingRawRadio() {
  rawOutRadioFD = createSocket(radioRawOutPort);

  if (rawOutRadioFD >= 0) {
    dbg_clear(DBG_SIM, "SIM: Outgoing raw radio messages initialized at fd %i.\n", rawOutRadioFD);
    return 1;
  }
  else {
    return 0;
  }
}


int initializeOutgoingBitRadio() {
  outRadioBitFD = createSocket(radioBitOutPort);

  if (outRadioBitFD >= 0) {
    dbg_clear(DBG_SIM, "SIM: Outgoing radio messages initialized at fd %i.\n", outRadioBitFD);
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
    dbg_clear(DBG_SIM, "SIM: Invocation logger initialized at fd %i.\n", (int)loggingFD);
    return 1;
  }
  else {
    return 0;
  }

  loggingPause = 0;
}

int createServerSocketAndWait(short port) {
  int sockfd;
  int clilen;
  int rval;

  struct sockaddr_in serv_addr;
  struct sockaddr_in cli_addr;
  

  memset(&serv_addr, 0, sizeof(serv_addr));
  serv_addr.sin_family = AF_INET;
  serv_addr.sin_port = htons(port);
  serv_addr.sin_addr.s_addr = htonl(localAddr);
  
  sockfd = socket(AF_INET, SOCK_STREAM, 0);
  if (sockfd < 0) {
    dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Could not create server socket: %s\n", strerror(errno));
    return -1;
  }
  
  do { 
      rval = bind(sockfd, (struct sockaddr*)&serv_addr, sizeof(serv_addr));
      if (rval < 0) {
	  dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Could not bind server socket to port %i: %s\n", (int)port, strerror(errno));
	  dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Will retry in 10 seconds.\n");
	  sleep(10);
      } 
  } while (rval < 0);

  listen(sockfd, 1);
  dbg_clear(DBG_SIM, "SIM: Created server socket waiting for client connection on port %i.\n", (int)port);


  clilen = sizeof(cli_addr);
  
  sockfd = accept(sockfd, (struct sockaddr*)&cli_addr, &clilen);
  dbg_clear(DBG_SIM, "SIM: Accepted client socket: FD %i\n", sockfd);
  return sockfd;
}

int createServerSocket(short port) {
  struct sockaddr_in sock;
  int sfd;
  int rval = -1;
  
  memset(&sock, 0, sizeof(sock));
  sock.sin_family = AF_INET;
  sock.sin_port = htons(port);
  sock.sin_addr.s_addr = htonl(localAddr);

  sfd = socket(AF_INET, SOCK_STREAM, 0);
  if (sfd < 0) {
    dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Could not create server socket: %s\n", strerror(errno));
    return -1;
  }

  while(rval < 0) {
    rval = bind(sfd, (struct sockaddr*)&sock, sizeof(sock));
    if (rval < 0) {
      dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Could not bind server socket to port %i: %s\n", (int)port, strerror(errno));
      dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Will retry in 10 seconds.\n");
      sleep(10);
    }
  }

  listen(sfd, 1);

  dbg_clear(DBG_SIM, "SIM: Created server socket listening on port %i.\n", (int)port);
  return sfd;
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
    dbg_clear(DBG_ERROR, "SIM: Could not create incoming socket to port %i. Error: %s \n", (int)port, strerror(errno));
    return -1;
  }

  rval = connect(fd, (struct sockaddr*)&sock, sizeof(sock));
  if (rval < 0) {
    close(fd);
    dbg_clear(DBG_SIM, "SIM: Could not initiate connection to port %i for messages.\n", (int)port);
    return -1;
  }

  dbg_clear(DBG_SIM, "SIM: Socket to port %i initialized at fd %i.\n", (int)port, fd);
  
  return fd;
}


int readInUARTMessages() {
  return 1;
}

int writeOutUartByte(long long ftime, short moteID, char value) {
  UartByteMsg msg;
  if (outUARTFD >= 0) {
    msg.time = htonll(ftime);
    msg.moteID = htons(moteID);
    msg.data = value;
    write(outUARTFD, &msg, sizeof(msg));
    return 1;
  }
  else {
    return 0;
  }
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

void setLoggingPause(int fpause) {
  loggingPause = fpause;
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
    dbg(DBG_SIM, "Task posted: %s\n", task);
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
    dbg(DBG_SIM, "Event signaled: %s\n", event);
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
    dbg(DBG_SIM, "Command called: %s\n", command);	
  }
  if (loggingPause > 0) {
    //usleep(loggingPause);
  }
  return 0;
}

int printOtherTime(char* buf, int len, long long int ftime) {
  int hours;
  int minutes;
  int seconds;
  int secondBillionths;
  
  secondBillionths = (int)(ftime % (long long) 4000000);
  seconds = (int)(ftime / (long long) 4000000);
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














