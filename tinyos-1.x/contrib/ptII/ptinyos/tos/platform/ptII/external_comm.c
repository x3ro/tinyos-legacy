// $Id: external_comm.c,v 1.8 2006/12/15 01:00:06 celaine Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

#if defined(__CYGWIN__) || defined(__FreeBSD__)

// CSS 24 Jun 2003: I can't find Cygwin's 64-bit byte-swap; this works.
#define swap_type(type,a,b) { type t=(a); (a)=(b); (b)=t; }
int64_t bswap_64( int64_t n )
{
  int8_t* p = (int8_t*)&n;
  swap_type( int8_t, p[0], p[7] );
  swap_type( int8_t, p[1], p[6] );
  swap_type( int8_t, p[2], p[5] );
  swap_type( int8_t, p[3], p[4] );
  return n;
}

#endif /* defined(__CYGWIN__) || defined(__FreeBSD__) */

#if defined(__CYGWIN__)

#define htonll(x) bswap_64(x)
#define ntohll(x) bswap_64(x)

#elif defined(__FreeBSD__)

#include <machine/endian.h>

#if BYTE_ORDER == BIG_ENDIAN
#error
#  define htonll(x) (x)
#  define ntohll(x) (x)
#else /* BYTE_ORDER == LITTLE_ENDIAN */
#  define htonll(x) bswap_64(x)
#  define ntohll(x) bswap_64(x)
#endif /* BYTE_ORDER == LITTLE_ENDIAN */

#else//if defined(__CYGWIN__)

#if __BYTE_ORDER == __BIG_ENDIAN
#  define htonll(x) (x)
#  define ntohll(x) (x)
#else
#  if __BYTE_ORDER == __LITTLE_ENDIAN
#    define htonll(x) __bswap_64(x)
#    define ntohll(x) __bswap_64(x)
#  endif
#endif

#endif//if defined(__CYGWIN__)

#define localAddr INADDR_LOOPBACK
//#define EC_DEBUG(_x)
// Viptos: comment out above and uncomment below for debugging statements.
#define EC_DEBUG(_x) _x

// Viptos: replacing C socket operations with Java sockets.
//int commandServerSocket = -1;
void *commandServerSocket = NULL;
//int eventServerSocket = -1;
void *eventServerSocket = NULL;
// Viptos: replacing C socket operations with Java sockets.
//int commandClients[MAX_CLIENT_CONNECTIONS];
void* commandClients[MAX_CLIENT_CONNECTIONS]; // array of SocketChannel
uint8_t batchState[MAX_CLIENT_CONNECTIONS];
// Viptos: replacing C socket operations with Java sockets.
//norace int eventClients[MAX_CLIENT_CONNECTIONS];
norace void* eventClients[MAX_CLIENT_CONNECTIONS]; // array of SocketChannel
norace uint16_t eventMask;

// Viptos: replacing C socket operations with Java sockets.
extern void* ptII_serverSocketCreate(short port);
extern void ptII_serverSocketClose(void *serverSocket);
extern void* ptII_selectorCreate(void *serverSocket, bool opAccept, bool opConnect, bool opRead, bool opWrite);
extern void ptII_selectorRegister(void *selector, void *socketChannel, bool opAccept, bool opConnect, bool opRead, bool opWrite);
extern void ptII_selectorClose(void *selector);
extern void* ptII_selectSocket(void *selector, char *selectorIsClosing, bool opAccept, bool opConnect, bool opRead, bool opWrite);
extern void* ptII_acceptConnection(void *serverSocketChannel);
extern void ptII_socketChannelClose(void *socketChannel);
extern int ptII_socketChannelWrite(void *socketChannel, void *data, int datalen);
extern int ptII_socketChannelRead(void *socketChannel, void *data, int datalen);

// Viptos: replacing C socket operations with Java sockets.
// Store the socket selectors for each thread.
void *selectorEventAcceptThread = NULL;
void *selectorCommandReadThread = NULL;

// Viptos: functions to create, enter, exit, wait, and broadcast
// (notifyAll()) on monitor.
extern void *ptII_createMonitorObject();
extern int ptII_MonitorEnter(void *monitorObject);
extern int ptII_MonitorExit(void *monitorObject);
extern void ptII_MonitorNotifyAll(void *monitorObject);
extern void ptII_MonitorWait(void *monitorObject);

// Viptos: Replacing pthread objects with JNI objects.
//pthread_t eventAcceptThread;
//pthread_t commandReadThread;
//pthread_mutex_t eventClientsLock;
norace void *eventClientsLock; // Viptos: of type jobject.  Note: Annotated as norace
//pthread_cond_t eventClientsCond;

/* UART/radio Messages injected by commands */
TOS_Msg external_comm_msgs_[TOSNODES];
TOS_MsgPtr external_comm_buffers_[TOSNODES];
norace static int GUI_enabled;

int createServerSocket(short port);
void *eventAcceptThreadFunc(void *arg);
void *commandReadThreadFunc(void *arg);

#if NESC >= 111

static int __nesc_nido_resolve(int __nesc_mote,
                               char* varname,
                               uintptr_t* addr, size_t* size);

#else

static int __nesc_nido_resolve(int __nesc_mote,
                               char* varname,
                               uintptr_t* addr, size_t* size)
{
    return -1;
}

#endif

/***************************************************************************
 * Initialization
 ***************************************************************************/

void initializeSockets() {
  int i;
  //dbg_clear(DBG_SIM, "SIM: Initializing sockets\n");
  dbg_clear(DBG_SIM, "SIM: Initializing sockets for mote %i\n", _PTII_NODEID);

  // Viptos: Set the lock object.
  tos_state.pause_lock = ptII_createMonitorObject();
    
  // Viptos: Replacing pthread objects with JNI objects.
  //pthread_mutex_init(&(tos_state.pause_lock), NULL);
  //pthread_cond_init(&(tos_state.pause_cond), NULL);
  //pthread_cond_init(&(tos_state.pause_ack_cond), NULL);

  for (i = 0; i < MAX_CLIENT_CONNECTIONS; i++) {
    // Viptos: replacing C socket operations with Java sockets.
    //commandClients[i] = -1;
    commandClients[i] = NULL;      
    //eventClients[i] = -1;
    eventClients[i] = NULL;
    batchState[i] = 0;
  }
  eventMask = 0xffff;
  // Viptos: replacing C socket operations with Java sockets.
  //commandServerSocket = createServerSocket(COMMAND_PORT);
  commandServerSocket = ptII_serverSocketCreate(COMMAND_PORT);
  //eventServerSocket = createServerSocket(EVENT_PORT);
  eventServerSocket = ptII_serverSocketCreate(EVENT_PORT);

  // Viptos: Set the lock object.
  eventClientsLock = ptII_createMonitorObject();

  //pthread_mutex_init(&eventClientsLock, NULL);
  //pthread_cond_init(&eventClientsCond, NULL);
  //pthread_create(&eventAcceptThread, NULL, eventAcceptThreadFunc, NULL);
  //pthread_create(&commandReadThread, NULL, commandReadThreadFunc, NULL);

  ptII_startThreads();
  
  socketsInitialized = 1;
}

/***************************************************************************
 * Socket management
 ***************************************************************************/

// Viptos: replacing C socket operations with Java sockets.
//int acceptConnection(int servfd) {
void* acceptConnection(void *serverSocketChannel) {
  //struct sockaddr_in cli_addr;
  //int clilen = sizeof(cli_addr);
  //int clifd;
  void *socketChannel;

  //EC_DEBUG(dbg_clear(DBG_SIM, "SIM: Waiting for connection on socket %d\n", servfd));
  EC_DEBUG(dbg_clear(DBG_SIM, "SIM: Waiting for connection on serverSocketChannel %p for mote %i\n", serverSocketChannel, _PTII_NODEID));

  //clifd = accept(servfd, (struct sockaddr*)&cli_addr, &clilen);
  socketChannel = ptII_acceptConnection(serverSocketChannel);

  //if (clifd < 0) {
  if (socketChannel == NULL) {
    //EC_DEBUG(dbg_clear(DBG_SIM, "SIM: Could not accept socket: %s\n", strerror(errno)));
    EC_DEBUG(dbg_clear(DBG_SIM, "SIM: Could not accept socket for mote %i.\n", _PTII_NODEID));

    // MDW: Maybe want to return -1 and keep going
    //exit(-1);
    // celaine
    //return -1;
    return NULL;
  }
  //EC_DEBUG(dbg_clear(DBG_SIM, "SIM: Accepted client socket: fd %d\n", clifd));
  EC_DEBUG(dbg_clear(DBG_SIM, "SIM: Accepted client socket: fd %p for mote %i\n", socketChannel, _PTII_NODEID));

  //return clifd;
  return socketChannel;
}

int createServerSocket(short port) {
  struct sockaddr_in sock;
  int sfd;
  int rval = -1;
  long enable = 1;

  memset(&sock, 0, sizeof(sock));
  sock.sin_family = AF_INET;
  sock.sin_port = htons(port);
  sock.sin_addr.s_addr = htonl(localAddr);

  sfd = socket(AF_INET, SOCK_STREAM, 0);
  if (sfd < 0) {
    dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Could not create server socket: %s\n", strerror(errno));
    exit(-1);
  }
  setsockopt(sfd, SOL_SOCKET, SO_REUSEADDR, (char *)&enable, sizeof(int));

  while(rval < 0) {
    rval = bind(sfd, (struct sockaddr*)&sock, sizeof(sock));
    if (rval < 0) {
      dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Could not bind server socket to port %d: %s\n", port, strerror(errno));
      dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Perhaps another copy of TOSSIM is already running?\n");
      dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Will retry in 10 seconds.\n");
      sleep(10);
    }
  }

  if (listen(sfd, 1) < 0) {
    dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Could not listen on server socket: %s\n", strerror(errno));
    exit(-1);
  }
  dbg_clear(DBG_SIM, "SIM: Created server socket listening on port %d.\n", port);

  return sfd;
}

// celaine
void shutdownSockets() __attribute__ ((C, spontaneous)) {



    socketsInitialized = 0;

    /*
    if (shutdown(commandServerSocket, SHUT_RDWR) < 0) {
        //if (close(commandServerSocket) < 0) {
        dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Could not shutdown command server socket: %s\n", strerror(errno));
        //dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Could not close command server socket: %s\n", strerror(errno));
    } else {
        dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Shut down command server socket.\n");
        //dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Closed command server socket.\n");
    }
     */
    
    ptII_selectorClose(selectorCommandReadThread);
    dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Shut down command server selector for mote %i.\n", _PTII_NODEID);
    ptII_serverSocketClose(commandServerSocket);
    dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Closed command server socket for mote %i.\n", _PTII_NODEID);
     
    /*
    if (shutdown(eventServerSocket, SHUT_RDWR) < 0) {
        //if (close(eventServerSocket) < 0) {
        dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Could not shutdown event server socket: %s\n", strerror(errno));
        //dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Could not close event server socket: %s\n", strerror(errno));
    } else {
        dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Shut down event server socket.\n");
        //dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Closed event server socket.\n");
    }
     */

    ptII_selectorClose(selectorEventAcceptThread);
    dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Shut down event server selector for mote %i.\n", _PTII_NODEID);
    ptII_serverSocketClose(eventServerSocket);
    dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Closed event server socket for mote %i.\n", _PTII_NODEID);
    
    if (ptII_joinThreads()) {
        dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Joined commandReadThread for mote %i.\n", _PTII_NODEID);
        dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Joined eventAcceptThread for mote %i.\n", _PTII_NODEID);
    } else {
        dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Could not join commandReadThread and/or eventAcceptThread for mote %i.\n", _PTII_NODEID);
    }

    
    /*
    if (pthread_join(commandReadThread, NULL) != 0) {
        dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Could not join commandReadThread.\n");
    } else {
        dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Joined commandReadThread.\n");
    }
    if (pthread_join(eventAcceptThread, NULL) != 0) {
        dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Could not join eventAcceptThread.\n");
    } else {
        dbg_clear(DBG_SIM|DBG_ERROR, "SIM: Joined eventAcceptThread.\n");
    }
     */
}

/* XXX MDW REMOVE THESE ?? */

/* XXX MDW: Rewrite these to send debug messages */
//int notifyTaskPosted(char* task) {
//  return 0;
//}

/* XXX MDW: Rewrite these to send debug messages */
//int notifyEventSignaled(char* event) {
//  return 0;
//}

/* XXX MDW: Rewrite these to send debug messages */
//int notifyCommandCalled(char* command) {
//  return 0;
//}

/***************************************************************************
 * Utilities
 ***************************************************************************/

void waitForGuiConnection() {
  int numclients = 0;
  int n;

  dbg_clear(DBG_SIM, "SIM: Waiting for connection from GUI...for mote %i\n", _PTII_NODEID);

  // Viptos: Replacing pthread objects with JNI objects.
  ptII_MonitorEnter(eventClientsLock);

  //pthread_mutex_lock(&eventClientsLock);
  while (numclients == 0) {
    for (n = 0; n < MAX_CLIENT_CONNECTIONS; n++) {
        // Viptos: replacing C socket operations with Java sockets.
        if (eventClients[n] != NULL) {
        //if (eventClients[n] != -1) {
	//dbg_clear(DBG_SIM, "SIM: Got client connection fd %d\n", eventClients[n]);
            dbg_clear(DBG_SIM, "SIM: Got client connection fd %p for mote %i\n", eventClients[n], _PTII_NODEID);
            numclients++;
        }
    }
    if (numclients == 0) {
      //pthread_cond_wait(&eventClientsCond, &eventClientsLock);
      ptII_MonitorWait(eventClientsLock);
    } 
  }
  //pthread_mutex_unlock(&eventClientsLock);

  ptII_MonitorExit(eventClientsLock);
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

char* currentTime() {
  static char timeBuf[128];
  printTime(timeBuf, 128);
  return timeBuf;
}

// Viptos: replacing C socket operations with Java sockets.
void addClient2(void *clientSockets[], void* socketChannel) {
  int i;
  
  for (i = 0; i < MAX_CLIENT_CONNECTIONS; i++) {
      if (clientSockets[i] == NULL) {
      clientSockets[i] = socketChannel;
      return;
    }
  }
  
  // client state is full - drop connection
  //close(clifd);
  ptII_socketChannelClose(socketChannel);
}

void addClient(int *clientSockets, int clifd) {
  int i;
  
  for (i = 0; i < MAX_CLIENT_CONNECTIONS; i++) {
    if (clientSockets[i] == -1) {
      clientSockets[i] = clifd;
      return;
    }
  }
  
  // client state is full - drop connection
  close(clifd);
}

// Viptos: replacing C socket operations with Java sockets.
//void sendInitEvent(int clifd) {
void sendInitEvent(void* socketChannel) {
  TossimInitEvent initEv;
  unsigned char* msg;
  int total_size;
      
  memset((char*)&initEv, 0, sizeof(TossimInitEvent));
  initEv.numMotes = tos_state.num_nodes;
  initEv.radioModel = tos_state.radioModel;
  initEv.rate = get_sim_rate();
  buildTossimEvent(0, AM_TOSSIMINITEVENT,
                   tos_state.tos_time, &initEv, &msg, &total_size);
  //writeTossimEvent(msg, total_size, clifd);
  writeTossimEvent(msg, total_size, socketChannel);
  free(msg);
}

/***************************************************************************
 * Event socket accept thread
 ***************************************************************************/

void *eventAcceptThreadFunc(void *arg) __attribute__ ((C, spontaneous)) {
  // Viptos: replacing C socket operations with Java sockets.
  //int clifd;
  //fd_set acceptset;

  // Viptos: replacing C socket operations with Java sockets.

  void *serverSocketChannel;
  void *socketChannel;
  char selectorIsClosing = 0;
  
  dbg_clear(DBG_SIM, "SIM: eventAcceptThread running for mote %i.\n", _PTII_NODEID);

  // Viptos: replacing C socket operations with Java sockets.
  selectorEventAcceptThread = ptII_selectorCreate(eventServerSocket, TRUE, FALSE, FALSE, FALSE);

  if (selectorEventAcceptThread == NULL) {
        EC_DEBUG(fprintf(stderr, "SIM: eventAcceptThread: selectorCreate returned NULL %i.\n", _PTII_NODEID));
        return 0;
  }
  
  while (1) {
      // Viptos: replacing C socket operations with Java sockets.
      //FD_ZERO(&acceptset);
      //FD_SET(eventServerSocket, &acceptset);
      EC_DEBUG(fprintf(stderr, "SIM: eventAcceptThread: calling select for mote %i\n", _PTII_NODEID));
      //if (select(eventServerSocket + 1, &acceptset, NULL, NULL, NULL) < 0) {

      // Call to ptII_selectSocket() is a blocking call.
      serverSocketChannel = ptII_selectSocket(selectorEventAcceptThread, &selectorIsClosing, TRUE, FALSE, FALSE, FALSE);
      EC_DEBUG(fprintf(stderr, "SIM: eventAcceptThread: returned from select for mote %i\n", _PTII_NODEID));
      if (serverSocketChannel == NULL) {
          if (selectorIsClosing) {
              EC_DEBUG(fprintf(stderr, "SIM: eventAcceptThreadFunc: selector is closing for mote %i.\n", _PTII_NODEID));
              return 0;
          } else {
              //EC_DEBUG(fprintf(stderr, "SIM: eventAcceptThreadFunc: error in select(): %s\n", strerror(errno)));
              EC_DEBUG(fprintf(stderr, "SIM: eventAcceptThreadFunc: error in select for mote %i\n", _PTII_NODEID));
              return 0;
          }
      }
      EC_DEBUG(fprintf(stderr, "SIM: eventAcceptThread: select returned for mote %i\n", _PTII_NODEID));

      //if (FD_ISSET(eventServerSocket, &acceptset)) {
      if (serverSocketChannel != NULL) {
          EC_DEBUG(fprintf(stderr, "SIM: eventAcceptThread: Checking for event connection for mote %i\n", _PTII_NODEID));
          //clifd = acceptConnection(eventServerSocket);
          socketChannel = acceptConnection(serverSocketChannel);
          EC_DEBUG(fprintf(stderr, "SIM: eventAcceptThread: Returned from acceptConnection for mote %i\n", _PTII_NODEID));
          //// celaine
          //if (clifd < 0) {
          if (socketChannel == NULL) {
              EC_DEBUG(fprintf(stderr, "SIM: eventAcceptThread: acceptConnection failed for mote %i\n", _PTII_NODEID));
              return 0;
          }
          //EC_DEBUG(fprintf(stderr, "SIM: eventAcceptThread: Got event connection %d\n", clifd));
          EC_DEBUG(fprintf(stderr, "SIM: eventAcceptThread: Got event connection %p for mote %i\n", socketChannel, _PTII_NODEID));

          //// Viptos: Replacing pthread objects with JNI objects.
          ptII_MonitorEnter(eventClientsLock);
      
          ////pthread_mutex_lock(&eventClientsLock);
          //addClient(eventClients, clifd);
          addClient2(eventClients, socketChannel);
          //sendInitEvent(clifd);
          sendInitEvent(socketChannel);
          ////pthread_cond_broadcast(&eventClientsCond);
          ptII_MonitorNotifyAll(eventClientsLock);
      
          ////pthread_mutex_unlock(&eventClientsLock);
          ptII_MonitorExit(eventClientsLock);
      }
  }
  return 0;
}

/***************************************************************************
 * Reading and processing incoming commands
 ***************************************************************************/

/* Event type for incoming commands */
typedef struct {
  GuiMsg* msg;
  char* payLoad;
} incoming_command_data_t;

// Commands invoke the following functions. 
// XXX These should be in a header file.
void nido_start_mote(uint16_t moteID);
void nido_stop_mote(uint16_t moteID);
TOS_MsgPtr NIDO_received_radio(TOS_MsgPtr packet);
TOS_MsgPtr NIDO_received_uart(TOS_MsgPtr packet);
void set_link_prob_value(uint16_t moteID1, uint16_t moteID2, double prob);

void event_command_cleanup(event_t* event) {
  incoming_command_data_t* cmdData = (incoming_command_data_t*)event->data;
  free(cmdData->msg);
  free(cmdData->payLoad);
  event_total_cleanup(event);
}
void event_command_in_handle(event_t* event,
			     struct TOS_state* state);
void event_command_in_create(event_t* event,
			     GuiMsg* msg,
			     char* payLoad) {
  incoming_command_data_t* data = (incoming_command_data_t*)malloc(sizeof(incoming_command_data_t));
  data->msg = msg;
  data->payLoad = payLoad;

  event->mote = (int)(msg->moteID & 0xffff);
  if (event->mote < TOSNODES &&
      event->mote >= 0) { // no events for motes that don't exist
    event->force = 1; // XXX MDW: Not all commands should be 'force'
  }
  event->pause = 1;
  event->data = data;
  event->time = msg->time;
  event->handle = event_command_in_handle;
  event->cleanup = event_command_cleanup;
}

// Viptos: replacing C socket operations with Java sockets.
// Actually process a command. Most command types are turned into
// events on the event queue, but others are processed instantaneously.
// if there's a response event, fill in reply_msg with the event and return 1
//int processCommand(int clifd, int clidx, GuiMsg *msg, char *payLoad,
int processCommand(void *socketChannel, int clidx, GuiMsg *msg, char *payLoad,
                   unsigned char** replyMsg, int* replyLen) {
  int ret = 0;
  switch (msg->msgType) {

    case AM_SETLINKPROBCOMMAND:
      {
       	SetLinkProbCommand *linkmsg = (SetLinkProbCommand*)payLoad;
	double prob = ((double)linkmsg->scaledProb)/10000;
	set_link_prob_value(msg->moteID, linkmsg->moteReceiver, prob);
	break;
      }
    case AM_SETADCPORTVALUECOMMAND:
      {
       	SetADCPortValueCommand *adcmsg = (SetADCPortValueCommand*)payLoad;
	set_adc_value(msg->moteID, adcmsg->port, adcmsg->value);
	break;
      }
    case AM_SETRATECOMMAND:
      {
        SetRateCommand *ratemsg = (SetRateCommand*)payLoad;
	set_sim_rate(ratemsg->rate);
	break;
      }
    case AM_VARIABLERESOLVECOMMAND:
      {
        VariableResolveResponse varResult;
        VariableResolveCommand *rmsg = (VariableResolveCommand*)payLoad;

        /*
         * Note that the following will need to be changed on
         * non-32bit systems.
         */
        if (__nesc_nido_resolve(msg->moteID, (char*)rmsg->name,
                                (uintptr_t*)&varResult.addr,
                                (size_t*)&varResult.length) != 0)
        {
          varResult.addr = 0;
          varResult.length = -1;
        }
      
        dbg_clear(DBG_SIM, "SIM: Resolving variable %s for mote %d: 0x%x %d\n",
                  rmsg->name, msg->moteID, varResult.addr, varResult.length);

        buildTossimEvent(TOS_BCAST_ADDR, AM_VARIABLERESOLVERESPONSE,
                         tos_state.tos_time, &varResult, replyMsg, replyLen);
        ret = 1;
        break;
      }
    case AM_VARIABLEREQUESTCOMMAND:
      {
        VariableRequestResponse varResult;
        VariableRequestCommand *rmsg = (VariableRequestCommand*)payLoad;
        uint8_t* ptr = (uint8_t*)rmsg->addr;
        varResult.length = rmsg->length;

        if (varResult.length == 0)
          varResult.length = 256; // special case
        
        memcpy(varResult.value, ptr, varResult.length);

        buildTossimEvent(TOS_BCAST_ADDR, AM_VARIABLEREQUESTRESPONSE,
                         tos_state.tos_time, &varResult, replyMsg, replyLen);
        ret = 1;
        break;
      }

  case AM_GETMOTECOUNTCOMMAND:
    {
      int i;      
      GetMoteCountResponse countResponse;

      countResponse.totalMotes = tos_state.num_nodes;
      bzero(&countResponse.bitmask, sizeof(countResponse.bitmask));
      
      for (i = 0; i < TOSNODES; i++) {
	countResponse.bitmask[i/8] |= (1 << (7 - (i % 8)));
      }

      buildTossimEvent(TOS_BCAST_ADDR, AM_GETMOTECOUNTRESPONSE,
		       tos_state.tos_time, &countResponse, replyMsg, replyLen);
      ret = 1;
      break;
    }
  case AM_SETDBGCOMMAND:
    {
      SetDBGCommand* cmd = (SetDBGCommand*)payLoad;
      dbg_set(cmd->dbg);
      break;
    }
  case AM_SETEVENTMASKCOMMAND:
    {
      SetEventMaskCommand* setMaskCommand = (SetEventMaskCommand*)payLoad;
      eventMask = setMaskCommand->mask;
      break;
    }
  case AM_BEGINBATCHCOMMAND:
    {
      if (batchState[clidx] != 0) {
        dbg(DBG_SIM|DBG_ERROR, "SIM: duplicate begin batch");
      }
      dbg(DBG_SIM, "SIM: begin batch");
      batchState[clidx] = 1;
      break;
    }
  case AM_ENDBATCHCOMMAND:
    {
      if (batchState[clidx] == 0) {
        dbg(DBG_SIM|DBG_ERROR, "SIM: end batch without begin");
      }
      dbg(DBG_SIM, "SIM: end batch");
      batchState[clidx] = 0;
      break;
    }
    
  default: 
      {
	// For all other commands, place on the event queue. 
	// See event_command_in_handle for these
	event_t* event = (event_t*)malloc(sizeof(event_t));
	event_command_in_create(event, msg, payLoad); 
	dbg(DBG_SIM, "SIM: Enqueuing command event 0x%lx\n", (unsigned long)event);
	TOS_queue_insert_event(event);
      }
  }

  return ret;
}

// Process commands that are posted to the event queue
void event_command_in_handle(event_t* event,
			     struct TOS_state* state) {
  incoming_command_data_t* cmdData = (incoming_command_data_t*)event->data;
  GuiMsg* msg = cmdData->msg;
  dbg_clear(DBG_SIM, "SIM: Handling incoming command type %d for mote %d\n", msg->msgType, msg->moteID);

  switch (msg->msgType) {

  case AM_TURNONMOTECOMMAND:
    dbg_clear(DBG_SIM, "SIM: Turning on mote %d\n", msg->moteID);
    nido_start_mote(msg->moteID);
    break;

  case AM_TURNOFFMOTECOMMAND:
    dbg_clear(DBG_SIM, "SIM: Turning off mote %d\n", msg->moteID);
    nido_stop_mote(msg->moteID);
    break;
    
  case AM_RADIOMSGSENDCOMMAND:
    {
      RadioMsgSendCommand *rmsg = (RadioMsgSendCommand*)cmdData->payLoad;
      TOS_MsgPtr buffer;
      
      dbg_clear(DBG_SIM, "SIM: Enqueueing radio message for mote %d (payloadlen %d)\n", msg->moteID, msg->payLoadLen);
      if (external_comm_buffers_[msg->moteID] == NULL) 
	external_comm_buffers_[msg->moteID] = &external_comm_msgs_[msg->moteID];
      buffer = external_comm_buffers_[msg->moteID];
      memcpy(buffer, &(rmsg->message), msg->payLoadLen);
      buffer->group = TOS_AM_GROUP;
      external_comm_buffers_[msg->moteID] = NIDO_received_radio(buffer);
    }
    break;
    
  case AM_UARTMSGSENDCOMMAND: 
    {
      UARTMsgSendCommand *umsg = (UARTMsgSendCommand*)cmdData->payLoad;
      TOS_MsgPtr buffer;
      int len = (msg->payLoadLen > sizeof(TOS_Msg))? sizeof(TOS_Msg):msg->payLoadLen;
      
      dbg_clear(DBG_SIM, "SIM: Enqueueing UART message for mote %d (payloadlen %d)\n", msg->moteID, msg->payLoadLen);
      if (external_comm_buffers_[msg->moteID] == NULL) 
	external_comm_buffers_[msg->moteID] = &external_comm_msgs_[msg->moteID];
      buffer = external_comm_buffers_[msg->moteID];
      
      memcpy(buffer, &(umsg->message), len);
      buffer->group = TOS_AM_GROUP;
      external_comm_buffers_[msg->moteID] = NIDO_received_uart(buffer);
    }
    break;

  case AM_INTERRUPTCOMMAND:
    {
      InterruptEvent interruptEvent;
      InterruptCommand* pcmd = (InterruptCommand*)cmdData->payLoad;
      interruptEvent.id = pcmd->id;
      dbg_clear(DBG_TEMP, "\nSIM: Interrupt command, id: %i.\n\n", pcmd->id);
      sendTossimEvent(TOS_BCAST_ADDR, AM_INTERRUPTEVENT,
                      tos_state.tos_time, &interruptEvent);
      break;
    }

  default:
    dbg_clear(DBG_SIM, "SIM: Unrecognizable command type received from TinyViz %i\n", msg->msgType);
    break;
  }

  event_cleanup(event);
}

// Viptos: replacing C socket operations with Java sockets.
// Read in a command from the given client socket and process it.
// Returns 0 if successful, -1 if the client connection was closed
//int readTossimCommand(int clifd, int clidx) {
int readTossimCommand(void *socketChannel, int clidx) {
  GuiMsg* msg; 
  unsigned char *header;
  char* payLoad = NULL;
  int curlen = 0;
  int rval;
  unsigned char ack;
  int reply;
  unsigned char* replyMsg = 0;
  int replyLen = 0;

  // Viptos: replacing C socket operations with Java sockets.
  //dbg_clear(DBG_SIM, "SIM: Reading command from client fd %d\n", clifd);
  dbg_clear(DBG_SIM, "SIM: Reading command from client fd %p\n", socketChannel);

  header = (unsigned char *)malloc(GUI_MSG_HEADER_LENGTH);
  msg = (GuiMsg*)malloc(sizeof(GuiMsg));
  // read in header of GuiMsg
  curlen = 0;
  while (curlen < GUI_MSG_HEADER_LENGTH) {
    dbg_clear(DBG_SIM, "SIM: Reading in GuiMsg header of size %d with length %d\n", GUI_MSG_HEADER_LENGTH, curlen);
    // Viptos: replacing C socket operations with Java sockets.
    //rval = read(clifd, header + curlen, GUI_MSG_HEADER_LENGTH - curlen);
    rval = ptII_socketChannelRead(socketChannel, header + curlen, GUI_MSG_HEADER_LENGTH - curlen);
    if (rval <= 0) {
      // Viptos: replacing C socket operations with Java sockets.
      //dbg_clear(DBG_SIM, "SIM: Closing client socket %d.\n", clifd);
      dbg_clear(DBG_SIM, "SIM: Closing client socket %p.\n", socketChannel);
      free(msg);
      // Viptos: replacing C socket operations with Java sockets.
      //close(clifd);
      ptII_socketChannelClose(socketChannel);
      goto done;
    } else {
      curlen += rval;
    }
  }

  // fill in values into allocated GuiMsg
  msg->msgType = ntohs(*(unsigned short *)&header[0]);
  msg->moteID = ntohs(*(unsigned short *)&header[2]);
  msg->time = ntohll(*(long long *)&header[4]);
  msg->payLoadLen = ntohs(*(unsigned short *)&header[12]);
  dbg_clear(DBG_SIM, "SIM: Command type %d mote %d time 0x%lx payloadlen %d\n", msg->msgType, msg->moteID, msg->time, msg->payLoadLen);
  if (msg->time < tos_state.tos_time) {
    msg->time = tos_state.tos_time;
  }

  // read in payload
  if (msg->payLoadLen > 0) {
    payLoad = (char*)malloc(msg->payLoadLen);
    curlen = 0;
    while (curlen < msg->payLoadLen) {
      dbg(DBG_SIM, "SIM: Reading in GuiMsg payload of size %d with length %d\n", msg->payLoadLen, curlen);
      // Viptos: replacing C socket operations with Java sockets.
      //rval = read(clifd, payLoad + curlen, msg->payLoadLen - curlen);
      rval = ptII_socketChannelRead(socketChannel, payLoad + curlen, msg->payLoadLen - curlen);
      if (rval <= 0) {
        // Viptos: replacing C socket operations with Java sockets.
        //dbg(DBG_SIM, "SIM: Closing client socket %d.\n", clifd);
       	dbg(DBG_SIM, "SIM: Closing client socket %p.\n", socketChannel);
	free(msg);
	free(payLoad);
	goto done;
      } else {
	curlen += rval;
	dbg(DBG_SIM, "SIM: Read from command port, total: %d, need %d\n", curlen, msg->payLoadLen - curlen);
      }
    }
  }

  if (msg->moteID < tos_state.num_nodes) {
      // Viptos: replacing C socket operations with Java sockets.
      //reply = processCommand(clifd, clidx, msg, payLoad, &replyMsg, &replyLen);
      reply = processCommand(socketChannel, clidx, msg, payLoad, &replyMsg, &replyLen);
  }
  else {
    dbg(DBG_SIM|DBG_ERROR, "SIM: Received command for invalid mote: %i\n", (int)msg->moteID);
  }

  // if we're in a batch, we don't send an ack for each command
  if (batchState[clidx] != 0) {
    if (reply) {
      dbg(DBG_SIM|DBG_ERROR, "SIM: unexpected command response in batch!!\n");
    }
    return 0;
  }
  
  do {
    // Viptos: replacing C socket operations with Java sockets.
    //rval = write(clifd, &ack, 1);
    rval = ptII_socketChannelWrite(socketChannel, &ack, 1);
    if (rval < 0) {
      // Viptos: replacing C socket operations with Java sockets.
      //dbg(DBG_SIM, "SIM: Closing client socket %d.\n", clifd);
      dbg(DBG_SIM, "SIM: Closing client socket %p.\n", socketChannel);
      goto done;
    }
  } while (rval != 1);

  if (reply) {
    dbg(DBG_SIM, "SIM: Sending %d byte reply.\n", replyLen);
    // Viptos: replacing C socket operations with Java sockets.
    //writeTossimEvent(replyMsg, replyLen, clifd);
    writeTossimEvent(replyMsg, replyLen, socketChannel);
    free(replyMsg);
  }

done:
  return 0;
}

/***************************************************************************
 * Command read thread
 ***************************************************************************/

void *commandReadThreadFunc(void *arg) __attribute__ ((C, spontaneous)) {
  int i;
  // Viptos: replacing C socket operations with Java sockets.
  //fd_set readset, exceptset;
  //int highest;
  int numclients;

  // Viptos: replacing C socket operations with Java sockets.
  void *selectableChannel;
  void *socketChannel;
  char selectorIsClosing = 0;

  dbg_clear(DBG_SIM, "SIM: commandReadThread running.\n");

  
  while (1) {
    // Viptos: replacing C socket operations with Java sockets.
    selectorCommandReadThread = ptII_selectorCreate(commandServerSocket, TRUE, FALSE, FALSE, FALSE);

    if (selectorCommandReadThread == NULL) {
        EC_DEBUG(fprintf(stderr, "SIM: commandReadThread: selectorCreate returned NULL for mote %i.\n", _PTII_NODEID));
        return 0;
    }
        
    // Viptos: replacing C socket operations with Java sockets.
    // Build up the fd_set
    //FD_ZERO(&readset);
    //FD_ZERO(&exceptset);
    //FD_SET(commandServerSocket, &readset);
    //FD_SET(commandServerSocket, &exceptset);
    //highest = commandServerSocket;
    numclients = 0;
    
    for (i = 0; i < MAX_CLIENT_CONNECTIONS; i++) {
    //  if (commandClients[i] != -1) {
        if (commandClients[i] != NULL) {
    //    if (commandClients[i] > highest) highest = commandClients[i];
    //    EC_DEBUG(fprintf(stderr, "SIM: commandReadThread: Adding fd %d to select set\n",
    //                     commandClients[i]));
    //    FD_SET(commandClients[i], &readset);
    //    FD_SET(commandClients[i], &exceptset);
          ptII_selectorRegister(selectorCommandReadThread, commandClients[i], FALSE, FALSE, TRUE, FALSE);
          numclients++;
      }
    }

    //EC_DEBUG(fprintf(stderr, "SIM: commandReadThread: Doing select, %d clients, highest %d\n",
    //                 numclients, highest));
    EC_DEBUG(fprintf(stderr, "SIM: commandReadThread: Doing select for mote %i\n", _PTII_NODEID));
    
    //if (select(highest+1, &readset, NULL, &exceptset, 0) < 0) {

    // Call to ptII_selectSocket() is a blocking call.
    selectableChannel = ptII_selectSocket(selectorCommandReadThread, &selectorIsClosing, FALSE, FALSE, TRUE, FALSE);
    if (selectableChannel == NULL) {
        if (selectorIsClosing) {
            dbg_clear(DBG_SIM, "SIM: commandReadThreadFunc: selector is closing for mote %i.\n", _PTII_NODEID);
            return 0;
        } else {
            //dbg_clear(DBG_SIM, "SIM: commandReadThreadFunc: error in select(): %s\n", strerror(errno));
            dbg_clear(DBG_SIM, "SIM: commandReadThreadFunc: error in select for mote %i\n", _PTII_NODEID);
            return 0;
        }
    }
    EC_DEBUG(fprintf(stderr, "SIM: commandReadThread: Returned from select for mote %i\n", _PTII_NODEID));

    // Viptos: replacing C socket operations with Java sockets.
    // Read from clients and check for errors
    for (i = 0; i < MAX_CLIENT_CONNECTIONS; i++) {
      /*EC_DEBUG(fprintf(stderr, "SIM: commandClients[i] %d excepta %d read %d\n",
	    commandClients[i], 
	    ((commandClients[i] != -1)?
	    FD_ISSET(commandClients[i], &exceptset) : -1),
	    ((commandClients[i] != -1)?
	    FD_ISSET(commandClients[i], &readset) : -1)));*/
      //if (commandClients[i] != -1 && FD_ISSET(commandClients[i], &readset)) {
      if (commandClients[i] != NULL && commandClients[i] == selectableChannel) {
	if (readTossimCommand(commandClients[i], i) < 0) { 
          //close(commandClients[i]);
          ptII_socketChannelClose(commandClients[i]);
	  //commandClients[i] = -1;
          commandClients[i] = NULL;
	}
      }
      /*
      if (commandClients[i] != -1 && FD_ISSET(commandClients[i], &exceptset)) {
	// Assume we need to close this one
	close(commandClients[i]);
	commandClients[i] = -1;
      }
      */
      ptII_selectorClose(selectorCommandReadThread);

    }

    // Check for new clients
    //if (FD_ISSET(commandServerSocket, &readset)) {
    if (commandServerSocket == selectableChannel) {
      //int clifd;
      EC_DEBUG(fprintf(stderr, "SIM: commandReadThread: accepting command connection for mote %i\n", _PTII_NODEID));
      //clifd = acceptConnection(commandServerSocket);
      socketChannel = acceptConnection(commandServerSocket);
      // celaine
      //if (clifd < 0) {
      if (socketChannel == NULL) {
          EC_DEBUG(fprintf(stderr, "SIM: commandReadThread: acceptConnection failed for mote %i\n", _PTII_NODEID));
          return 0;
      }
      //EC_DEBUG(fprintf(stderr, "SIM: commandReadThread: Got command connection %d\n", clifd));
      EC_DEBUG(fprintf(stderr, "SIM: commandReadThread: Got command connection %p for mote %i\n", socketChannel, _PTII_NODEID));
      //addClient(commandClients, clifd);
      addClient2(commandClients, socketChannel);
    }
  }
  return 0;
}

/***************************************************************************
 * Writing events
 ***************************************************************************/

// Viptos: replacing C socket operations with Java sockets.
// Write an event to the given client socket and wait for an ACK.
// Returns 0 if successful, -1 if the client connection was closed
//int writeTossimEvent(void *data, int datalen, int clifd) {
int writeTossimEvent(void *data, int datalen, void* socketChannel) {
  unsigned char ack;
  int i, j;

  /* Debugging only */
  /* fprintf(stderr,"WRITING: ");
   * for (i = 0; i < datalen; i++) {
   *   fprintf(stderr,"%2x ", ((unsigned char *)data)[i]);
   * }
   * fprintf(stderr,"\n");
   */

  //EC_DEBUG(fprintf(stderr, "writeTossimEvent: fd %d datalen %d (0x%2x)\n", clifd, datalen, datalen));
  EC_DEBUG(fprintf(stderr, "writeTossimEvent: socketChannel %p datalen %d (0x%2x)\n", socketChannel, datalen, datalen));
  j = 0;
  // XXX PAL: Is there a chance that we don't write everything
  // and need to loop? Hope and pray, I guess...

  // Viptos: replacing C socket operations with Java sockets.
  //i = send(clifd, data, datalen, 0);
  i = ptII_socketChannelWrite(socketChannel, data, datalen);
  
  EC_DEBUG(fprintf(stderr, "writeTossimEvent: waiting for ack...\n"));
  // Viptos: replacing C socket operations with Java sockets.
  //if (i >= 0) j = read(clifd, &ack, 1);
  if (i >= 0) {
      j = ptII_socketChannelRead(socketChannel, &ack, 1);
  }
  
  EC_DEBUG(fprintf(stderr, "writeTossimEvent: ack received...\n"));
  if ((i < 0)  || (j < 0)) {
    EC_DEBUG(fprintf(stderr, "writeTossimEvent: Socket closed: %s\n", strerror(errno)));
    // Viptos: replacing C socket operations with Java sockets.
    //close(clifd);
    ptII_socketChannelClose(socketChannel);
    
    return -1;
    // XXX MDW: If -gui, should really wait for a new connection?
    // That's painful if we have multiple clients...
  }
  EC_DEBUG(fprintf(stderr, "writeTossimEvent: done\n"));
  return 0;
}

void buildTossimEvent(uint16_t moteID, uint16_t type, long long ftime, void *data,
                      unsigned char **msgp, int *lenp) {
  unsigned char *msg;
  int payload_size, total_size;
  
  // Determine payload size
  
  switch (type) {
  case AM_DEBUGMSGEVENT: 
    payload_size = sizeof(DebugMsgEvent);
    break;
  case AM_RADIOMSGSENTEVENT:
    payload_size = sizeof(RadioMsgSentEvent);
    break;
  case AM_UARTMSGSENTEVENT:
    payload_size = sizeof(RadioMsgSentEvent);
    break;
  case AM_ADCDATAREADYEVENT:
    payload_size = sizeof(ADCDataReadyEvent);
    break;
  case AM_TOSSIMINITEVENT:
    payload_size = sizeof(TossimInitEvent);
    break;
  case AM_VARIABLERESOLVERESPONSE:
    payload_size = sizeof(VariableResolveResponse);
    break;
  case AM_VARIABLEREQUESTRESPONSE:
    payload_size = sizeof(VariableRequestResponse);
    break;
  case AM_INTERRUPTEVENT:
    payload_size = sizeof(InterruptEvent);
    dbg(DBG_TEMP, "SIM: Sending InterruptEvent, payload is %i\n", (int)payload_size);
    break;
  case AM_LEDEVENT:
    payload_size = sizeof(LedEvent);
    break;
  default:
    EC_DEBUG(fprintf(stderr, "buildTossimEvent for invalid type: %d", type));
    return;
  }

  total_size = GUI_MSG_HEADER_LENGTH + payload_size;
  msg = (unsigned char *)malloc(total_size);

  *(unsigned short *)(&msg[0]) = htons(type);
  *(unsigned short *)(&msg[2]) = htons(moteID);
  *(long long *)(&msg[4]) = htonll(ftime);
  *(unsigned short *)(&msg[12]) = htons(payload_size);
  memcpy(((unsigned char *)msg)+GUI_MSG_HEADER_LENGTH, data, payload_size);

  EC_DEBUG(fprintf(stderr, "buildTossimEvent: msgType %d (0x%02x) moteID %d (0x%02x) payload size %d total size %d\n", type, type, moteID, moteID, payload_size, total_size));


  *msgp = msg;
  *lenp = total_size;
}

/* Send a TOSSIM event to all clients connected to the event port.
 * Note that this requires waiting for an ACK from each client in turn.
 */
void sendTossimEvent (uint16_t moteID, uint16_t type, long long ftime, void *data) {
  unsigned char *msg;
  int total_size;
  int n;
  int numclients = 0;
  // Viptos: replacing C socket operations with Java sockets.
  //int clients[MAX_CLIENT_CONNECTIONS];
  void* clients[MAX_CLIENT_CONNECTIONS];

  if (!socketsInitialized) return;

  // Viptos: Replacing pthread objects with JNI objects.
  ptII_MonitorEnter(eventClientsLock);
  
  //pthread_mutex_lock(&eventClientsLock);
  while (numclients == 0) {
    for (n = 0; n < MAX_CLIENT_CONNECTIONS; n++) {
      //clients[n] = -1;
      clients[n] = NULL;
      //if (eventClients[n] != -1) {
      if (eventClients[n] != NULL) {
	clients[n] = eventClients[n];
	numclients++;
      }
    }
    // If no clients and '-gui', wait for a connection
    if (numclients == 0 && GUI_enabled) {
      EC_DEBUG(fprintf(stderr, "sendTossimEvent waiting for connection\n"));

      //pthread_cond_wait(&eventClientsCond, &eventClientsLock);
      ptII_MonitorWait(eventClientsLock);
      
      EC_DEBUG(fprintf(stderr, "sendTossimEvent woke up\n"));
    } else if (numclients == 0) {
      // No clients, but don't wait around for them
      //pthread_mutex_unlock(&eventClientsLock);

      ptII_MonitorExit(eventClientsLock);

      return;
    }
  }
  //pthread_mutex_unlock(&eventClientsLock);

  ptII_MonitorExit(eventClientsLock);


  EC_DEBUG(fprintf(stderr, "sendTossimEvent: msgType %d (0x%02x) moteID %d (0x%02x)\n", type, type, moteID, moteID));

  buildTossimEvent(moteID, type, ftime, data, &msg, &total_size);

  for (n = 0; n < MAX_CLIENT_CONNECTIONS; n++) {
      //if (clients[n] != -1 && ((type & eventMask) != 0)) {
      if (clients[n] != NULL && ((type & eventMask) != 0)) {
          if (writeTossimEvent(msg, total_size, clients[n]) < 0) {
              // Socket closed

              // Viptos: Replacing pthread objects with JNI objects.
              ptII_MonitorEnter(eventClientsLock);
        
              //pthread_mutex_lock(&eventClientsLock);
              //eventClients[n] = -1;
              eventClients[n] = NULL;
              //pthread_mutex_unlock(&eventClientsLock);

              ptII_MonitorExit(eventClientsLock);
          }
      }
  }
  EC_DEBUG(fprintf(stderr, "Sent.\n"));
  free(msg);
}

