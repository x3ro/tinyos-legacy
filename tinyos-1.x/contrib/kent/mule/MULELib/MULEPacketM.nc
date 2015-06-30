/** MULEPacketM.nc
  * Hybrid simulation support for TOSSIM
  */

/**
 * This is a drop-in replacement for TOSSIM's radio stack. This does not
 * attempt to simulate the functionality of the radio stack, but rather 
 * communicates with Mica2 motes connected to MIB600's, over TCP.
 *
 * To use this code, all you need to do is add the line
 *   PFLAGS = -I/path/to/hybrid
 * to your application Makefile, then rebuild your application with 'make pc'.
 *
 * This uses a configuration file in the current directory called 
 * 'hybrid.conf'. This is simply a list of the addresses of the EPRB's being
 * used, one per line.
 *
 * David Watson - dgwatson@kent.edu
 */

// I had put this in to find out when free was being called - not removing 
// it because it may turn out to be useful in the future
//#define free(x) fprintf(stderr, "freeing %p at %s\n", x, __LINE__); free(x)

#define TOSSIM_TICKS_PER_MICA2_TICK 4.38 

includes hybrid;
module MULEPacketM { 
  provides interface StdControl as Control;
  provides interface BareSendMsg as Send;
  provides interface ReceiveMsg as Receive;
}
implementation {
  bool queueEmpty();
  void do_multi_send(int mote, int num_sending);
  void flush_all_incoming();
  void sleep_tossim_ticks(long long ticks);
  void create_senddone(int moteNum, uint16_t send_time);
  bool packetsMatch(TOS_MsgPtr a, TOS_MsgPtr b);
  void createReceived(TOS_MsgPtr msg, int sender, int recvr, 
      long long start_time, uint16_t sending_time);
  void event_tossim_senddone_create(event_t *fevent, TOS_MsgPtr msg, int mote,
      uint32_t end_time);
  void event_tossim_msg_create(event_t *fevent, TOS_MsgPtr msg, int source, 
      int dest, uint32_t end_time); 
  void event_tossim_do_send_handle(event_t *fevent, 
	struct TOS_state *fstate);

  void testAllSenders(hybrid_message** messages, int num_sending, char* func) {
    int i;
    fprintf(stderr, "%s\n", func);
    for (i = 0; i < num_sending; i++) {
      fprintf(stderr, "message %d: addr %d\n", i, messages[i]->msg->addr);
    }
  }

 
  
  command result_t Control.init() {
    //dbg(DBG_USR1, "MULEPacketM: Control.init() called\n");
    init_hybrid_sim();
    return SUCCESS;
  }

  command result_t Control.start() {
    //dbg(DBG_USR1, "MULEPacketM: Control.start() called\n");
    return SUCCESS;
  }
  command result_t Control.stop() {
    //dbg(DBG_USR1, "MULEPacketM: Control.stop() called\n");
    return SUCCESS;
  }

  // Runs thru each mote socket, and throws out any input we 
  // have not yet handled.
  void flush_all_incoming() {
    int i;
    for (i = 0; i < tos_state.num_nodes; i++) {
      if (hybrid_state.mote_array[i]->fd >= 0)
	flush_incoming(hybrid_state.mote_array[i]->fd);
    }
  }

  // This method is kind of hacky. I'm not entirely sure it 
  // works the way it should. But so far it seems to have 
  // #worked adequately enough for my purposes.
  bool packetsMatch(TOS_MsgPtr msg1, TOS_MsgPtr msg2) {
    int length;
    int i;
    if (msg1 == NULL || msg2 == NULL) return 0;
    if (msg1->addr != msg2->addr) return 0;

    // necessary because for some reason MULEApp doesn't properly
    // report the length of received messages, but instead simply
    // gives a '0'.
    if (msg1->length > msg2->length) length = msg1->length;
    else length = msg2->length;

    for (i = 0; i < length; i++) {
      if (msg1->data[i] != msg2->data[i]) return 0;
    }

    return 1;
  }

  void createReceived(TOS_MsgPtr msg, int sender, int receiver, 
      long long start_time, uint16_t sending_time) {
    TOS_MsgPtr msgCopy = (TOS_MsgPtr)malloc(sizeof(TOS_Msg));
    event_t* ev = (event_t*)malloc(sizeof(event_t));
    memcpy(msgCopy, msg, sizeof(TOS_Msg));
    
    event_tossim_msg_create(ev, msgCopy, sender, receiver, 
	start_time + sending_time);
    TOS_queue_insert_event(ev);
  }
  
  
  int compare_messages(const hybrid_message** n1, const hybrid_message** n2) {
    if ((*n1)->startTime < (*n2)->startTime) return -1;
    if ((*n1)->startTime > (*n2)->startTime) return 1;
    return 0;
  }

  //TODO: refactor this a bit, perhaps? It seems a little long for comfort.
  void recv_all_waiting(hybrid_multi_ent* entry, int sock, int node) {
    int waitTime = 80000;
    entry->msg = NULL;
    entry->send_time = 0;
    entry->ackFirst = 0;
    entry->node = node;

    //I changed this so that the check is performed in do_multi_send.
    //This is to support caching.
    //if (!tos_state.moteOn[node]) return;

    //TODO: look for ACK instead of hasDataAvailable
    //Update: tried doing this. Had poor results - was missing a lot of 
    //packets. Still unsure as to the reason. If I get a chance, I'll 
    //try working on this some more.
    while (hasDataAvailable(sock, waitTime)) {
      char preamble;
      waitTime = 100000;
      read(sock, &preamble, 1);

      if (preamble == HYBRID_SEND_LOCAL_ADDRESS) {
	flush_incoming(sock);
	break;
      } else if (preamble == HYBRID_TIMING_SYMBOL) {
	uint8_t time_buf[4];

	if (entry->msg == NULL) { 
	  entry->ackFirst = 1;
	  //fprintf(stderr, "mote %d got ack first\n", node);
	}
	read_bytes(sock, time_buf, 4);
	if (time_buf[3] != HYBRID_DONE_SYMBOL) {
	  entry->ackFirst = 0;
	  continue;
	}
	entry->send_time = TOSSIM_TICKS_PER_MICA2_TICK * 
	  ((time_buf[0] << 8) | time_buf[1]);
	entry->msgAcked = time_buf[2];
	if (entry->ackFirst) {
	  if (!hybrid_state.sending[node]) {
	    fprintf(stderr, "Error - mote got ack, but was not sending!.\n"
		"Exiting.");
	    exit(-1);
	  }
	  hybrid_state.totalSendTime = entry->send_time;
	  hybrid_state.backoffTime = entry->send_time + 
	    hybrid_state.sending[node]->startTime;
	}
	hybrid_state.sending[node]->msg->ack = entry->msgAcked;

	//fprintf(stderr, "recv_all_waiting: Mote %d took time %d to send\n", node, entry->send_time);
	
      } else if (preamble == HYBRID_START_SYMBOL) {
	if (entry->msg != NULL) { // get rid of this message
	  uint8_t num_bytes, c;
	  //fprintf(stderr, "recv_all_waiting: Dropping extra packet from mote %d\n", node);
	  read(sock, &num_bytes, 1);
	  num_bytes++;

	  for (;num_bytes > 0; num_bytes--)  {
	    read(sock, &c, 1);
	  }
	} else {
	  // read this message
	  uint8_t num_bytes, c, retval;
	  //fprintf(stderr, "recv_all_waiting: reading message at mote %d: ", node);
	  setNonBlocking(sock, 0);
	  read(sock, &num_bytes, 1);

	  entry->msg = (TOS_MsgPtr)(malloc(sizeof(TOS_Msg)));
	  if (!entry->msg) {
	    fprintf(stderr, "Unable to allocate memory\n");
	    exit(-1);
	  }
	  retval = read_bytes(sock, entry->msg, num_bytes);

	  read(sock, &c, 1);
	  if (c != HYBRID_DONE_SYMBOL) {
	    //fprintf(stderr, "error at mote %d - did not get done symbol\n", node);
	    free(entry->msg);
	    entry->msg = NULL;
	  } else if (entry->msg->addr != TOS_BCAST_ADDR) {
	    entry->msg->addr = node;
	  }
	}
      }
    }

    //fprintf(stderr, "recv_all_waiting for node %d:\n msg %p send_time %d ack_first %d msgAcked %d\n", node, entry->msg, entry->send_time, entry->ackFirst, entry->msgAcked);
  }
	

  void perform_packet_sends(int motenum, int num_sending, 
      hybrid_message** messages) {
    int i;
    int tmpMsgAddr;
    long long lastTime;
    //dbg_clear(DBG_USR2, "perform_packet_sends: Sending packets for motes");
    // send all of the packets

    flush_all_incoming();


    lastTime = messages[0]->startTime;
    for (i = 0; i < num_sending; i++) {
      //Packet is 36 bytes, plus 1 preamble and 1 conclusion
      uint8_t send_buf[38];  

      if (SOCKET(messages[i]->mote) > -1) {
	messages[i]->actuallySent++;
      } else {
	continue;
      }
      
      tmpMsgAddr = messages[i]->msg->addr;
      if (messages[i]->msg->addr != TOS_BCAST_ADDR) {
	if (messages[i]->msg->addr >= tos_state.num_nodes) {
	  //fprintf(stderr, "MULEPacketM: Sending to node %d - does not exist?\n", messages[i]->msg->addr);
	}
	messages[i]->msg->addr = 
	  hybrid_state.mote_array[messages[i]->msg->addr]->hwAddr;
      }
      send_buf[0] = HYBRID_RECEIVE_PACKET_FROM_UART;
      memcpy(send_buf+1, messages[i]->msg, 36);
      send_buf[37] = '\n';
      write(hybrid_state.mote_array[messages[i]->mote]->fd, send_buf, 38);
      messages[i]->msg->addr = tmpMsgAddr;

      sleep_tossim_ticks(messages[i]->startTime - lastTime);
      lastTime = messages[i]->startTime;
      //dbg_clear(DBG_USR2, " %d", messages[i]->mote);
    }
    //dbg_clear(DBG_USR2, "\n");
  }

  void map_real_onto_virtual(int moteid) {
    int i, j;
    int moteX, moteY;
    int offX, offY;

    if (!hybrid_state.usingTiling) return;

    for (i = 0; i < hybrid_state.simWidth; i++) {
      for (j = 0; j < hybrid_state.simHeight; j++) {
	hybrid_state.virtual_motes[i][j].fd = -1;
	hybrid_state.virtual_motes[i][j].hwAddr = -1;
      }
    }

    // determine coordinates of center mote
    moteY = moteid % hybrid_state.simWidth;
    moteX = moteid / hybrid_state.simWidth;
    offX = moteX - hybrid_state.centerX;
    offY = moteY + 1 - hybrid_state.centerY;
    
    // copy real_motes onto virtual_motes
    for (i = 0; i < hybrid_state.physWidth; i++) {
      for (j = 0; j < hybrid_state.physHeight; j++) {
	if (i + offX > hybrid_state.simWidth - 1 || i + offX < 0 || 
	  j + offY > hybrid_state.simHeight - 1 || j + offY< 0) {
	  //fprintf(stderr, "%d %d out of range\n", i+offX, j+offY);
	  continue;
	}

	//fprintf(stderr, "vX %d vY %d -> rX %d rY %d\n", i+offX, j+offY, i, j);
	hybrid_state.virtual_motes[i+offX][j+offY] = 
	  hybrid_state.real_motes[i][j];
      }
    }
  }
 
  int get_tile_index(int motenum) {
    int moteindex;
    real_mote* mote = hybrid_state.mote_array[motenum];
    moteindex = mote->motearray_xpos + 
      mote->motearray_ypos*hybrid_state.physWidth;

    return moteindex;
  }

 

  char* gen_sending_id(hybrid_message** messages, int num_sending) {
    int i;
    char *mess_buf = malloc(
	(hybrid_state.physWidth*hybrid_state.physHeight + 1)*sizeof(char));

    for (i = 0; i < hybrid_state.physWidth*hybrid_state.physHeight; i++) {
      mess_buf[i] = '#';
    }
    mess_buf[i] = '\0';

    for (i = 0; i < num_sending; i++) {
      if (hybrid_state.mote_array[messages[i]->mote]->fd == -1) continue;

      mess_buf[get_tile_index(messages[i]->mote)] = '1';
    }

    return mess_buf;
  }

  // Searches thru the cached configurations. If the current configuration
  // has been run the proper number of times, it will return the configuration
  // information, otherwise NULL.
  sending_record* get_cached_configuration(char* pattern) {
    sending_record* current;
    if (!hybrid_state.usingTiling || !hybrid_state.usingCaching) return NULL;

    current = hybrid_state.cachedSends;

    while(current) {
      if (!(strcmp(pattern, current->sendPattern))) {
        if (current->count == SENDING_RECORD_COUNT) 
	  return current;
	else return NULL;
      }

      current = current->next;
    }

    return NULL;
  }

  sending_record* alloc_sending_record(char* sPattern);

  void saveCachedInformation(char* sendPattern, char* recvPattern,
      long sendTime) {
    sending_record * rec = NULL;

    if (!hybrid_state.usingTiling) return;

    if (hybrid_state.cachedSends == NULL) {
      rec = alloc_sending_record(sendPattern);
      hybrid_state.cachedSends = rec;
    } else { // we need to search
      sending_record * current;
      bool found = 0;
      current = hybrid_state.cachedSends;

      while (current->next) {
	if (!(strcmp(sendPattern, current->sendPattern))) {
	  found = 1;
	  rec = current;
	  break;
	}
	current = current->next;
      }

      if (!found) {
	rec = alloc_sending_record(sendPattern);
	current->next = rec;
      }
    }

    if (rec->count == SENDING_RECORD_COUNT) return;

    rec->send_time[rec->count] = sendTime;
    rec->received[rec->count] = recvPattern;
    rec->count++;
  }

  sending_record* alloc_sending_record(char* sendPattern) {
    sending_record* rec = calloc(1, sizeof(sending_record));
    rec->count = 0;
    rec->next = NULL;
    rec->sendPattern = malloc(strlen(sendPattern + 1));
    strcpy(rec->sendPattern, sendPattern);

    return rec;
  }
      

  hybrid_message** get_sorted_messages_to_send(int num_sending) {
    int i;
    int curr; // used as index into messages[] while scanning senders

    // first need to get list of all sending motes
    hybrid_message** messages = 
    	(hybrid_message**)calloc(num_sending,sizeof(hybrid_message*));
    for (i = 0, curr = 0; i < tos_state.num_nodes; i++) {
      if (hybrid_state.sending[i] != NULL)
	messages[curr++] = hybrid_state.sending[i];
    }

    qsort(messages, num_sending, sizeof(hybrid_message*), 
	(int (*)(const void*, const void*))compare_messages);


    return messages;
  }

  void send_ack_to_all_motes() {
    int i;
    for (i = 0; i < tos_state.num_nodes; i++) {
      if (hybrid_state.mote_array[i]->fd == -1) continue;
      else {
	uint8_t buf[2];
	buf[0] = HYBRID_SEND_LOCAL_ADDRESS;
	buf[1] = '\n';
	write(hybrid_state.mote_array[i]->fd, buf, 2);
      }
    }
  }


  hybrid_multi_ent* get_responses_from_all_motes() {
    int i;
    hybrid_multi_ent* responses = (hybrid_multi_ent*)
      calloc(tos_state.num_nodes, sizeof(hybrid_multi_ent));

    for (i = 0; i < tos_state.num_nodes; i++) {
      if (hybrid_state.mote_array[i]->fd == -1) continue;
      recv_all_waiting(&(responses[i]), hybrid_state.mote_array[i]->fd, i);
    }
    flush_all_incoming();

    return responses;
  }

  void create_senddone_for_ackfirsts(hybrid_multi_ent* responses) {
    // find out which sending took the least amount of time
    // if we have two that both have ackFirst, then we have a winner
    // create sendDones for those that have ackFirst
    int i;

    for (i = 0; i < tos_state.num_nodes; i++) {
      if (hybrid_state.mote_array[i]->fd == -1) continue;
      /*dbg(DBG_USR2, "responses[%d]: ackFirst %d node %d sending %d\n",
	  i, responses[i].ackFirst, responses[i].node,
	  hybrid_state.sending[responses[i].node]);*/
      if (responses[i].ackFirst && hybrid_state.sending[responses[i].node]) {
	//dbg(DBG_USR2, "calling create_senddone\n");
	create_senddone(responses[i].node, responses[i].send_time);
	// discard received messages on those nodes
	// FIXME: free this stuff
	if (responses[i].msg) {
	  free(responses[i].msg);
	  responses[i].msg = NULL;
	}
      }
    }
  }

  char* create_new_received_buf() {
    char* received_buf;
    int i;
    if (hybrid_state.usingTiling) {
      received_buf = malloc(sizeof(char) *
	  (hybrid_state.physWidth*hybrid_state.physHeight + 1));

      for (i = 0; 
	  i < hybrid_state.physWidth*hybrid_state.physHeight + 1; 
	  i++) {
	received_buf[i] = '#';
      }
      received_buf[i] = '\0';
    }

    return received_buf;
  }


  int find_earliest_sender() {
    int i;
    int earliestSender = -1;
    for (i = 0; i < tos_state.num_nodes; i++) {
      if (hybrid_state.sending[i]) {
	if (earliestSender == -1) 
	  earliestSender = i;
	else {
	  if (hybrid_state.sending[i]->startTime < 
	      hybrid_state.sending[earliestSender]->startTime)
	    earliestSender = i;
	}
      }
    }

    return earliestSender;
  }

  //FIXME: figure out where the first sent message gets marked as no longer
  //sending
  void create_event_for_earliest_sender() {
    int earliestSender = find_earliest_sender();
   
    if (earliestSender != -1) { // may look like a bug, but it's not - 
				// if two motes that can't hear each other 
				// both transmit, we may get this
      event_t* ev = (event_t*)malloc(sizeof(event_t));
      hybrid_state.sending[earliestSender]->isInQueue = 1;
      ev->mote = earliestSender;
      ev->data = NULL;
      ev->time = hybrid_state.sending[earliestSender]->startTime + 32000;
      ev->handle = event_tossim_do_send_handle;
      ev->cleanup = event_default_cleanup;
      ev->pause = 0;
      TOS_queue_insert_event(ev);
    }
  }

  void create_received_for_all_motes(hybrid_message** messages, 
      hybrid_multi_ent* responses, int num_sending, char* received_buf) {
    int i;

    //TODO: make sure that for tiling, only first one succeeds in sending
    // once that's done, scan thru received packets, and create received 
    // events for all those that match
    for (i = 0; i < num_sending; i++) {
      // we don't want to back off sending message that were outside this 
      // tile!
      if (!messages[i]->actuallySent) {
	continue;
      }
      // if we got an ack first on this sending node, then scan all the 
      // responses, looking for packets that match the sent packet
      if (responses[messages[i]->mote].ackFirst) {
	int j;
	for (j = 0; j < tos_state.num_nodes; j++) {
	  if (messages[i]->mote == j) continue;
	  if (packetsMatch(responses[j].msg, messages[i]->msg)) {
	    if (hybrid_state.usingTiling) {
	      received_buf[get_tile_index(j)] = '1';
	    }
	    
	    // this check is done here, instead of recv_all_waiting, to
	    // support caching
	    if (tos_state.moteOn[j]) {
	      createReceived(messages[i]->msg, messages[i]->mote, 
		  j, messages[i]->startTime, responses[i].send_time);
	    }
	  }
	}
	// free entry for this node

	
	/*dbg(DBG_USR2, "hybrid_state.sending[%d]: %d\n", moteNum,
	    hybrid_state.sending[moteNum]);*/
	//dbg_clear(DBG_USR2, "MULEPacketM: Mote %d sent.\n", messages[i]->mote);
      } else {
	messages[i]->startTime = hybrid_state.backoffTime;
      }
    }
  }

  void free_responses(hybrid_multi_ent* responses) {
    int i;
    for (i = 0; i < tos_state.num_nodes; i++) {
      if (responses[i].msg) {
	free(responses[i].msg);
	responses[i].msg = NULL;
      }
    }
    free(responses);
  }

  char* setup_tiling_parameters(hybrid_message** messages, int num_sending) {
    char* sendingPattern = NULL;
    if (hybrid_state.usingTiling) {
      messages[0]->actuallySent = 1;
      sendingPattern = gen_sending_id(messages, num_sending);
    } else {
      int i;
      for (i = 0; i < num_sending; i++) messages[i]->actuallySent = 1;
    }

    return sendingPattern;
  }

  void create_cached_receives(hybrid_message* mess, sending_record* srec,
    int whichOne) {
    int i;
    for (i = 0; i < tos_state.num_nodes; i++) {
      if (hybrid_state.mote_array[mess->mote]->fd == -1) continue;
      if (!tos_state.moteOn[i]) continue;

      if (srec->received[whichOne][get_tile_index(i)] == '1')
	createReceived(mess->msg, mess->mote, i, mess->startTime, 
	 srec->send_time[whichOne]);
    }
  }

  void create_cached_senddone(hybrid_message* mess, sending_record* srec,
      int whichOne) {
    create_senddone(mess->mote, srec->send_time[whichOne]);
    
  }
  
  void delay_other_sends(hybrid_message** messages, sending_record* srec,
      int num_sending, int whichOne) {
    int i;
    for (i = 1; i < num_sending; i++) {
      if (hybrid_state.mote_array[messages[i]->mote]->fd == -1) continue;
      hybrid_state.sending[messages[i]->mote]->startTime += 
       srec->send_time[whichOne];
    }
  }
  
  void do_multi_send(int motenum, int num_sending) {
    sending_record* sendRecord;
    char * sendingPattern;
    hybrid_message** messages; 
   
    messages = get_sorted_messages_to_send(num_sending); 
    map_real_onto_virtual(messages[0]->mote);
    sendingPattern = setup_tiling_parameters(messages, num_sending);

    if (sendRecord = get_cached_configuration(sendingPattern)) {
      int whichOne = rand() % 10;
      fprintf(stderr, "Doing a cached send!\n");
      create_cached_receives(messages[0], sendRecord, whichOne);
      create_cached_senddone(messages[0], sendRecord, whichOne);
      delay_other_sends(messages, sendRecord, num_sending, whichOne);
      create_event_for_earliest_sender();

      free(sendingPattern);
      free(messages);
    } else {
      hybrid_multi_ent* responses;
      char* received_buf;

      perform_packet_sends(motenum, num_sending, messages);
      //TODO: send_ack_to_all_motes();
      //testAllSenders(messages, num_sending, "get_responses");
      responses = get_responses_from_all_motes();
      //testAllSenders(messages, num_sending, "create_senddone");
      //testAllSenders(messages, num_sending, "create_new_received");
      received_buf = create_new_received_buf();
      //testAllSenders(messages, num_sending, "create_received");
      create_received_for_all_motes(messages, responses, 
	  num_sending, received_buf);

      create_senddone_for_ackfirsts(responses);
      //fprintf(stderr, "Received: %s\n", received_buf);
      if(hybrid_state.usingTiling) {
	saveCachedInformation(sendingPattern, received_buf, 
	    hybrid_state.totalSendTime);
      }

      // find out who we should have send next
      create_event_for_earliest_sender();
     
      free(messages);
      free(received_buf);
      free_responses(responses);
      if (sendingPattern) free(sendingPattern);
    }
  }

  // does a nanosleep for the specified number of TOSSIM ticks.
  // 1 tick = 250 ns (4M ticks/sec)
  void sleep_tossim_ticks(long long ticks) {
    struct timespec ts;
    if (ticks == 0) return;
    ts.tv_sec = 0;
    ts.tv_nsec = 250*ticks;

    nanosleep(&ts, NULL);
    //printf("Slept %lld ticks\n", ticks);
  }

  // checks to see if there is another mote sending
  bool queueEmpty() {
    int i;
    for (i = 0; i < tos_state.num_nodes; i++) {
      if (hybrid_state.sending[i] != NULL)
	if (hybrid_state.sending[i]->isInQueue) {
	  //dbg(DBG_USR2, "MULEPacketM: Mote %d is already in queue.\n", i);
	  return 0;
	}
    }
    return 1;
  }
  
  command result_t Send.send(TOS_MsgPtr msg) {
    event_t* ev;
    hybrid_message* hMsg;
    char time_buf[128];

    printTime(time_buf, 128);
    dbg(DBG_AM, "MULEPacketM: Send.send() called at %s\n", time_buf);

    if (hybrid_state.sending[NODE_NUM] != NULL) return FAIL;

    hMsg = (hybrid_message*)malloc(sizeof(hybrid_message));
    hMsg->startTime = tos_state.tos_time;
    hMsg->msg = msg;
    hMsg->isInQueue = 0;
    hMsg->mote = NODE_NUM;
    hybrid_state.sending[NODE_NUM] = hMsg;

    if (queueEmpty()) { 
      // should check if anything else is queued up, and if so not
      // put it in the queue
      hMsg->isInQueue = 1;

      // create event that should fire at time + 32000
      ev = (event_t*)malloc(sizeof(event_t));
      ev->mote = NODE_NUM;
      ev->data = NULL;
      ev->time = tos_state.tos_time + 32000; // roughly how long it takes
      ev->handle = event_tossim_do_send_handle;
      ev->cleanup = event_default_cleanup;
      ev->pause = 0;
      TOS_queue_insert_event(ev);
    } else {
      //dbg(DBG_USR2, "MULEPacketM: Not putting in queue: already an entry.\n");
    }

    return SUCCESS;
  }
  
  void event_tossim_msg_handle(event_t *fevent, struct TOS_state *fstate) __attribute__ ((C, spontaneous)) {
    tossim_msg_event *msgev = (tossim_msg_event *)fevent->data;
    msgev->msg->crc = 1;
    dbg(DBG_USR2, "MULEPacketM: calling Receive.receive at mote %d\n", NODE_NUM);
    signal Receive.receive(msgev->msg);
  }


  void event_tossim_msg_create(event_t *fevent, TOS_MsgPtr msg, int source, 
      int dest, uint32_t end_time) {
    tossim_msg_event *msgev = (tossim_msg_event *)malloc(sizeof(tossim_msg_event
  ));
    msgev->msg = msg;
    msgev->srcaddr = source;
    fevent->mote = dest;
    fevent->data = msgev;
    fevent->time = end_time; 
    fevent->handle = event_tossim_msg_handle;
    fevent->cleanup = event_total_cleanup;
    fevent->pause = 0;
    //dbg(DBG_USR1, "MULEPacketM: Created msg event for mote%d\n", dest);
  }
   
  void event_tossim_senddone_handle(event_t *fevent, struct TOS_state *fstate) __attribute__ ((C, spontaneous)) {
    RadioMsgSentEvent sendev; tossim_senddone_event *sdev = (tossim_senddone_event *)fevent->data; 
    dbg(DBG_USR1, "Done transmitting\n");
    hybrid_state.anyoneTransmitting = 0;

    //dbg(DBG_USR1, "MULEPacketM: Handling event_tossim_senddone at mote %d\n", NODE_NUM);
    memcpy(&sendev.message, sdev->msg, sizeof(sendev.message));
    sendTossimEvent(NODE_NUM, AM_RADIOMSGSENTEVENT, tos_state.tos_time, &sendev);
    signal Send.sendDone(sdev->msg, SUCCESS);
  }

  //creates a sendDone event after a multi-send event
  void create_senddone(int moteNum, uint16_t send_time) {
    event_t* ev = (event_t*)malloc(sizeof(event_t));
    event_tossim_senddone_create(ev, hybrid_state.sending[moteNum]->msg, 
	moteNum, hybrid_state.sending[moteNum]->startTime + send_time);
    TOS_queue_insert_event(ev);
    free(hybrid_state.sending[moteNum]);
    hybrid_state.sending[moteNum] = NULL;
    //dbg(DBG_USR2, "Creating sendDone for mote %d at %d\n", moteNum, send_time);
  }


  void event_tossim_senddone_create(event_t *fevent, TOS_MsgPtr msg, int mote,
      uint32_t end_time) {
    char time_buf[128];
    tossim_senddone_event *sdev = (tossim_senddone_event *)malloc(sizeof(tossim_senddone_event));
    sdev->msg = msg;
    fevent->mote = mote;
    fevent->data = sdev;
    fevent->time = end_time;
    fevent->handle = event_tossim_senddone_handle;
    fevent->cleanup = event_total_cleanup;
    fevent->pause = 0;

    printOtherTime(time_buf, 128, end_time);
    //dbg(DBG_USR1, "MULEPacketM: Created senddone event for mote %d at %s\n", 
    //	mote, time_buf);
  }

  void event_tossim_do_send_handle(event_t *fevent, 
	struct TOS_state *fstate) __attribute__ ((C, spontaneous)) {
    int i;
    int numSending = 0;
    //dbg(DBG_USR2, "event_tossim_do_send_handle called for mote %d\n", fevent->mote); 

    for (i = 0; i < tos_state.num_nodes; i++) {
      if (hybrid_state.sending[i] != NULL) {
	numSending++;
      }
    }

    do_multi_send(fevent->mote, numSending);
  }
}

