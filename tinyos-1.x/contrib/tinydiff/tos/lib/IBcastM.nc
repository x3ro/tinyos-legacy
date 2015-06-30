module IBcastM {
  provides {
    interface StdControl;
    interface Enqueue as IBcastEnqueue;
    interface ReceiveMsg as IBcastReceiveMsg;
  }

  uses {
    interface ReceiveMsg;
    interface Enqueue as TxManEnqueue;
    interface Pot;
    interface SimpleEEPROM as OCEEPROM;
    interface Leds;
  }
}
implementation {

  /* NOTE: IBCAST will only decrement a packet's TTL
  * IT WILL NOT increment the sequence number of the packet
  * The application is solely responsible for setting the corect fields
  * of an IBCAST message.
  * See ibcast_hdr.h for details on the bcastmsg structure
  */

  //#include "tos.h"
  #include "ibcast_hdr.h"
  #include "string.h"
  #include "dbg.h"
  //#include "udb.h"
  //#include "printf_P.h"


  #ifndef SQN_GBAND
  #error "SQN_GBAND undefined"
  #endif

  #undef udb_printf
  #define udb_printf(...)

  /* EEPROM stuff */
  #ifndef MAX_SOURCES
  #define MAX_SOURCES	30
  #endif

  #define U_EEPROM_ADDR	0

  /*	Return codes */
  /*
  #define NM_ERROR		    -4
  #define TTL_OR_ADDRESS_CHECK_F    -3
  #define GB_UID_CHECK_FAIL	    -2  // Guardband Unique ID check fail
  #define CACHE_FULL		    -1
  #define NM_SEQ_CHECK_FAIL	    0	// Normal Mode Seqno check fail
  #define GB_POSN_FORWARD	    1	// Guardband Forward on positive N 
  #define GB_NEGN_FORWARD	    2	// GuardBand forward on negative N
  #define GB_UID_FORWARD	    3	// Guardband uid forward
  #define NM_FORWARD		    4	// Normal forward			
  #define NS_FORWARD		    5	// New Source forward
  */

  enum {
    NM_ERROR		   =  -4,
    TTL_OR_ADDRESS_CHECK_F =  -3,
    GB_UID_CHECK_FAIL	   =  -2,   // Guardband Unique ID check fail
    CACHE_FULL		   =  -1,
    NM_SEQ_CHECK_FAIL	   =  0,    // Normal Mode Seqno check fail
    GB_POSN_FORWARD	   =  1,    // Guardband Forward on positive N 
    GB_NEGN_FORWARD	   =  2,    // GuardBand forward on negative N
    GB_UID_FORWARD	   =  3,    // Guardband uid forward
    NM_FORWARD		   =  4,    // Normal forward			
    NS_FORWARD		   =  5	    // New Source forward
  };

  
  // frame of the component
  //#define tos_frame_type ibcast_obj_frame
  //tos_frame_begin(ibcast_obj_frame) {
  TOS_Msg bcast_buf;	       // bcast message buffer
  TOS_MsgPtr savedMsg;
  struct bcastcache cache[MAX_SOURCES];
  uint8_t unique;
  // TODO: change
  //}
  //TOS_FRAME_END(IBCAST_obj_frame);
  char check_forwarding(struct bcastmsg *bmsg);

  // TODO: put something here
  void flip_rx_led() {};

  //char TOS_COMMAND(IBCAST_INIT)(){
  command result_t StdControl.init()
  {
    // Initialize settings
    // udb_init(12);

    //TOS_CALL_COMMAND(IBCAST_POT_INIT)(5);
    call Pot.init(50); // TODO: change back
    //TOS_CALL_COMMAND(IBCAST_TXMAN_INIT)();
    

    call Leds.init();
    call Leds.greenOn();
    // bcast_pending = 0;
    //
    savedMsg=&bcast_buf;

    /* Read the value of address #0, add 1, then write back the value
    * On the next invocation of start (due to a reboot), unique will be
    * different. The value of unique will be used as a double-check when
    * the seqs are the same
    */

    //TOS_CALL_COMMAND(IBCAST_OCEEPROM_READ)(U_EEPROM_ADDR, 1, &(unique));
    call OCEEPROM.read(U_EEPROM_ADDR, 1, &unique);
    unique++;
    unique &= 0xFF; // not needed, really

    //TOS_CALL_COMMAND(IBCAST_OCEEPROM_WRITE)(U_EEPROM_ADDR, 1, &(unique));
    call OCEEPROM.writeByte(U_EEPROM_ADDR, unique);

    return SUCCESS;
  }


//char TOS_COMMAND(IBCAST_START)()
  command result_t StdControl.start()
  {
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }


  // Command sent by upper layer. 
  // char TOS_COMMAND(IBCAST_TX_MSG)(TOS_MsgPtr pkt)
  command result_t IBcastEnqueue.enqueue(TOS_MsgPtr pkt)
  {
    struct bcastmsg *bmsg = (struct bcastmsg *)(pkt->data);

    if (bmsg == NULL || bmsg->source == 0 || bmsg->seq == 0 || bmsg->ttl == 0)	{
      //return -1;
      dbg(DBG_ERROR, "IBcast: BAD packet from app! bmsg = 0x%x, source = %d, "
	  "seq = %d, ttl = %d\n", bmsg, bmsg->source, bmsg->seq, bmsg->ttl);
      return FAIL;
    }

    if (bmsg->source == TOS_LOCAL_ADDRESS) {
      // This is my own message, send it out without any checks
      /* add unique number to packet*/
      // THIS IS THE ONLY PLACE WHERE UID SHOULD BE ASSIGNED
      bmsg->uid = unique;

      //return  (TOS_CALL_COMMAND(IBCAST_ENQUEUE_MSG)(VAR(msg)));
      // call Leds.redOn();
      dbg(DBG_USR2, "IBcast: from app: sending packet seq %d from local "
	  "program\n", bmsg->seq);
      return call TxManEnqueue.enqueue(pkt);
    }

    /* if we are not the source */
    // Check if this is a new *broadcast* message
    if (pkt->addr == TOS_BCAST_ADDR) {
      if ((check_forwarding(bmsg)) > 0) {
	// TODO: fix this! this appears to be wrong!
	// savedMsg=pkt;

	//return (TOS_CALL_COMMAND(IBCAST_ENQUEUE_MSG)(VAR(msg)));
	dbg(DBG_USR1, "IBcast: from app: sending BROADCAST packet from node %d\n",
	    bmsg->source);
	return call TxManEnqueue.enqueue(pkt);
      } else {
	//return 0;
	return SUCCESS;
      }
    } else {
      /* Why would I be sending unicast messages??? */
      //return (TOS_CALL_COMMAND(IBCAST_ENQUEUE_MSG)(msg));
      //call Leds.redOn();
      //return call TxManEnqueue.enqueue(savedMsg);
      dbg(DBG_ERROR, "IBcast: BUG!!! from app: forwarding UNICAST packet from "
	  "node %d!!\n", bmsg->source);
      return call TxManEnqueue.enqueue(pkt);
    }

    return SUCCESS;
  }

  /*
  TOS_TASK(TXTick)
  {
	  TOS_CALL_COMMAND(IBCAST_TXMAN_TICK)();
  }
  */

  // Decision whether the message is new: it has to be within 65535 sequence
  // numbers of the last number 


  char check_forwarding(struct bcastmsg *bmsg)
  { 
    uint8_t i;

    if ((bmsg->source == TOS_LOCAL_ADDRESS) || (bmsg->ttl == 0) 
	|| (bmsg->ttl > MAX_TTL) 
	// This check is to enable simulations to use node 0 as passive "sink"s.
	|| TOS_LOCAL_ADDRESS == 0) {
      // Don't forward your own messages
      // Don't forward anything with ttl == 0
      return TTL_OR_ADDRESS_CHECK_F;
    }

    for (i = 0;i < MAX_SOURCES;i++) {
      // see if we already have the source
      if (cache[i].source == bmsg->source) {
	// We have the source, check the sequence numbers
	if (bmsg->seq <= SQN_GBAND) {		// node is in startup mode
	    int16_t n = (bmsg->seq - cache[i].seq);

	    // positive n is normal
	    // if uid is greater, that node was reset
	    // On reset, update uid and forward packet
	    // Worst case flooding: send 1 extra duplicate due to
	    // forwarding even when n < 0
	    if (n > 0) {
	      // Normal case during bootstart : forward
	      cache[i].seq = bmsg->seq;
	      return GB_POSN_FORWARD;
	    } 
	    else { // n <= 0
	      // case of reboot...
	      if (bmsg->uid > cache[i].uid) {
		cache[i].seq = bmsg->seq;
		cache[i].uid = bmsg->uid;	// since node was reset
		return GB_UID_FORWARD;
	      }
	      else // case of an older packet during the bootstart phase
		return NM_SEQ_CHECK_FAIL;
	    }

	}  else  {	// bmsg->seq > SQN_GBAND
	  if ((int16_t)(bmsg->seq - cache[i].seq) > 0) {
	    // Message is good to go, update sequence number
	    cache[i].seq = bmsg->seq;
	    return NM_FORWARD;
	  } 
	  // this is in case all packets in the guard band are lost for
	  // some reason... so, the guard band idea (due to Thanos) does
	  // not conclusively tell us if the node rebooted (as could happen
	  // in the case of out of sequence packets in the bootstart
	  // phase), nor does it handle the case in which the node rebooted
	  // but the packets in the guardband are all lost... In both these
	  // cases, we'd need to use the "uid"... so, the guardband is not
	  // needed at all... but I've left it here for legacy reasons...  
	  else if (bmsg->uid > cache[i].uid) {
	    cache[i].seq = bmsg->seq;
	    cache[i].uid = bmsg->uid;	// since node was reset
	    return GB_UID_FORWARD;
	  }
	}	// if (bmsg->seq <= SQN_GBAND)
	return NM_SEQ_CHECK_FAIL;
      }	// if (cache[i].source == bmsg->source)	
    }			

    // We can't reach this part unless the source was a new one
    // if we don't have the source anywhere in the cache, we create
    // an entry for it, by picking the first available element in the
    // cache	
    for (i = 0; i < MAX_SOURCES; i++) {
      if (cache[i].source == 0) {	// Empty element
	cache[i].source = bmsg->source;
	cache[i].seq = bmsg->seq;
	cache[i].uid = bmsg->uid;
	// Always forward first packet from new source, no matter what
	// the seq is
	return NS_FORWARD;
      }
    }

    // This part is reached if we couldn't find an empty element
    dbg(DBG_USR1,"IBcast: check_forwarding: CACHE_FULL!!\n");
    return CACHE_FULL;
  }

  // Handler for data message flooding. 
  // TOS_MsgPtr TOS_MSG_EVENT(IBCAST_RX_PACKET)(TOS_MsgPtr msg) 
  // TODO: really take care to figure out what is returned...
  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr msg)
  {
    int8_t n = 0;
    struct bcastmsg *bmsg = (struct bcastmsg *)(msg->data);
    TOS_MsgPtr tmp = msg;
    // Commented out for now
    // TODO: uncomment this
    /*
      if (msg->group != group) {
	udb_printf("Group check failed, msg->group is %d, my group is %d\n",
	msg->group, group);
	return NULL;
      }
    */

    //call Leds.greenOn();
    if (bmsg == NULL || bmsg->source == 0 || bmsg->seq == 0 || bmsg->ttl == 0) {
      // XXX: should NOT return null
      // return NULL;
      return msg;
    }
    
    flip_rx_led();			
    // Check if this is a new *broadcast* message
    if (msg->addr == TOS_BCAST_ADDR) {
      n = check_forwarding(bmsg);
      if (n > 0) {	
	// Decrement the TTL
	// Redundant check but necessary until I determine what is wrong
	if (bmsg->ttl > 0)
	  bmsg->ttl--;
	else
	  goto done;
	// Return a message buffer to the lower levels
	// and hold on to the current buffer
	tmp = savedMsg;	
	savedMsg = msg;		
	//TOS_CALL_COMMAND(IBCAST_ENQUEUE_MSG)(VAR(msg));
	dbg(DBG_USR2, "IBcast: from network: forwarding packet from node %d: "
	    "ttl = %d, seq = %d\n",
	    bmsg->source, bmsg->ttl, bmsg->seq);
	call TxManEnqueue.enqueue(savedMsg);
      } 
      // redundant code: else { }
    } else if (msg->addr == TOS_LOCAL_ADDRESS) { // Message is for us
      //TOS_SIGNAL_EVENT(IBCAST_UNICAST_MSG_RCVD)(VAR(msg));
      // NOTE: modification to buffer management logic
      dbg(DBG_USR1, "IBcast: from network: signalling app: UNICAST packet"
	  " from node %d\n",
	  bmsg->source);
      savedMsg = signal IBcastReceiveMsg.receive(savedMsg);
    }

  done:

    udb_printf("check_forwarding returned %d\n", n);
    udb_printf("Source: %2d, Seqnum: %2d, TTL: %2d, UID: %2d\n", 
	       bmsg->source, bmsg->seq, bmsg->ttl, bmsg->uid);
    return tmp;
  }


  event void OCEEPROM.asyncWriteDone(char success)
  {
    return;
  }

  // Handler for control message flooding. Not implemented yet
  // I think the above data handler can be re-used here
  // NOTE: not implemented
  /*
  TOS_MsgPtr TOS_MSG_EVENT(IBCAST_CTRL_UPDATE)(TOS_MsgPtr msg) 
  {
    return msg;
  }



  // NOTE: NOT USED
  char TOS_EVENT(IBCAST_UART_TX_PACKET_DONE)(TOS_MsgPtr packet)
  {
	  return 0;
  }

  TOS_MsgPtr TOS_EVENT(IBCAST_UART_RX_PACKET_DONE)(TOS_MsgPtr packet)
  {
	  return packet;
  }

  }
  */
}

// OLD CODE from .comp file
/* 
ACCEPTS{
	// StdControl.init()
	char IBCAST_INIT(void);
	// StdControl.start()
	char IBCAST_START(void);
	// Enqueue.enqueue()
	char IBCAST_TX_MSG(TOS_MsgPtr data);
};

SIGNALS{
	// UnicastReceiveMsg.receive()
	TOS_MsgPtr IBCAST_UNICAST_MSG_RCVD(TOS_MsgPtr msg);
};

HANDLES{
	// CommReceiveMsg[uint8_t id].receive(); 
	TOS_MsgPtr IBCAST_RX_PACKET(TOS_MsgPtr data);
	// remove
	char IBCAST_UART_TX_PACKET_DONE(TOS_MsgPtr packet);
	// remove
	TOS_MsgPtr IBCAST_UART_RX_PACKET_DONE(TOS_MsgPtr packet);
};

USES{
	// remove
	char IBCAST_SUB_INIT();
	char IBCAST_TIMER_INIT();
	// TxManStdControl.init() --> removed to one level up
	char IBCAST_TXMAN_INIT();
	// TxManControl.tick()
	void IBCAST_TXMAN_TICK();
	// remove
	char IBCAST_UART_INIT();
	// remove
	char IBCAST_RFM_INIT();
	// remove
	// replace by Timer.start();
	char IBCAST_ADD_TIMER(Timer *t, uint32_t tick);
	// remove
	char IBCAST_SUB_TX_PACKET(TOS_MsgPtr data);
	// remove
	char IBCAST_DEL_TIMER(Timer *t);
	// Pot.init()
	char IBCAST_POT_INIT(char val);
	// Pot.set()
	void IBCAST_POT_SET(char val);
	// Pot.get()
	char IBCAST_POT_GET();
	// TxManEnqueue.enqueue();
	char IBCAST_ENQUEUE_MSG(TOS_MsgPtr msg);     
	short IBCAST_RAND();
	// remove
	char IBCAST_UART_TX_PACKET(TOS_MsgPtr data);
	// OCEEPROM.read()
	void IBCAST_OCEEPROM_READ(int addr, int size, char *buf);
	// OCEEPROM.write()
	void IBCAST_OCEEPROM_WRITE(int addr, int size, char *buf);
};
*/
