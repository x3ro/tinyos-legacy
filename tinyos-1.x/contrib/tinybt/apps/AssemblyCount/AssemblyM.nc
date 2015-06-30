/*
  Assembly program - second version of self assembly program
  Based on an approach where children are looking for their parents.

  Copyright (C) 2002 & 2003 Mads Bondo Dydensborg <madsdyd@diku.dk>

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

/* Enable this to get debug information on the leds */
#define ASSEMBLY_DEBUG 1

/* This to get some ascii information over the "bluetooth chain" */
#define ASSEMBLY_CHATTER 1

/* This must be changed both here and in AssemblyC.nc */
// #define CLOCK_DEBUG 1

/* This enables some very special code, if we are running the
   "Friday 2003.04.04" test (which is taking place Saturday morning... 
   The basic idea is to always be able to form a network like this:
   laptop <--> bc/xx <--> be/yy <--> [bf/zz & bd/vv]
*/
//#define FRIDAY_TEST 1


/* Weird compiler stuff */
includes btpackets;
#ifndef HCI_DM1
/* HCI Packet types */
#define HCI_DM1 	0x0008
#define HCI_DM3 	0x0400
#define HCI_DM5 	0x4000
#define HCI_DH1 	0x0010
#define HCI_DH3 	0x0800
#define HCI_DH5 	0x8000
#endif

/** 
 * Assembly module that uses two Bluetooth devices and builds
 * a simple tree. 
 *
 * <p>The way the tree is built is quite simple. There are two major
 * ways; we can be asked to become a network (assemble command) or
 * join another network (join).</p>
 *
 * <p>If we become a network, others can join us. If we join another
 * network, we will allow others to join us. If we loose the
 * connection to the node we joined, we will disconnect all the nodes
 * that have joined us, thereby initiating a resamble of the network.</p>
 * 
 * <p>Please note, that this component does not try to handle more
 * than 7 slaves per piconet, although this could easily be build into
 * the component.</p>
 * 
 * <p>The calls to inqCancel are probably not neccessary --- the state
 * machine could probably be simplified somewhat.</p> */
module AssemblyM { 
  provides {
    interface StdControl;
    interface AssemblyI as Assembly;
  }
  uses {
    // interface HPLUART as userUART;
    interface Bluetooth as Bluetooth0;
    interface Bluetooth as Bluetooth1;
#ifdef CLOCK_DEBUG
    interface Clock;
#endif
    interface Interrupt;
    interface LedDebugI as Debug;
  }
}

/* These macros give rise to a number of warnings. */
#define INT_START { bool interruptOn;
#define INT_STOP }  

#define INT_DISABLE interruptOn = call Interrupt.disable();
/* At least for INT_ENABLE it does not matter - it is only called if interrupts are off 
   So, all read accesses to interruptOn are OK. */
#define INT_ENABLE if (interruptOn) call Interrupt.enable();

#include "debug.h"

#ifndef ASSEMBLY_DEBUG
#define debug(a)
#else
#define debug(a) call Debug.debug(a)
#endif

implementation {
  /* Buffer handling */
#define NUM_BUFFERS 6
#define NUM_BUFFERPS (NUM_BUFFERS + 2)
  /** Buffers to store packets in, managed by buffer_put and buffer_get.*/
  static gen_pkt buffers[NUM_BUFFERS];
  /** Pointers to the buffers, managed by buffer_put and buffer_get. */
  static gen_pkt * bufferps[NUM_BUFFERPS];
  
  /* Delay buffer handling */
#define NUM_DELAY_BUFFERPS (NUM_BUFFERPS + 4)
  /** Buffers that queue packets to be send, one queue for each interface */
  static hci_acl_data_pkt * delay_bufferps[2][NUM_DELAY_BUFFERPS];
  /** First pending packet */
  static int delay_first[2]; 
  /** Index for next empty queue slot */
  static int delay_next[2]; 
  enum childState_t {
    csNotReady = 0, 
    csReadBDAddrPending = 1, 
    csScanEnablePending = 2, 
    csIdle = 3,
    csInqPending = 4, 
    csConnCompletePending = 5, 
    csWriteLinkPolicyPending = 6, 
    csInqCancelPending = 7, 
    csScanDisablePending = 8, 
    csHaveParent = 9, 
    csWaitForParentInqDisable = 10};
  enum parentState_t {
    psNotReady = 0, 
    psClosed = 1, 
    psScanEnablePending = 2,
    psScanDisablePending = 3, 
    psClosing = 4,
    psOpen = 5};

  /** The state of the child (bt0) interface */
  enum childState_t childState;
  /** The state of the parent (bt1) interface */
  enum parentState_t parentState;

  /* **********************************************************************
   * Variables related to the child interface (handling our parent)
   * *********************************************************************/

  /** Used to hold the bd address of the child (bt0) interface.  This
     is actually only used as a debug/info thing. We do not depend on
     it - handles are used for the connections. It is used in the
     Assembly layer also. */
  static bdaddr_t childAddr;

  /** Used to keep an inq result for the child (bt0) interface in */
  static inq_resp_pkt * childInqResultPkt;

  /* **********************************************************************
   * Variables related to the parent interface (handling children)
   * *********************************************************************/
  /** The connections that the parent (bt1) interface maintain. The
      data structures type is provided for other applications in
      assembly.h */
  static connectionId connections[MAX_NUM_CONNECTIONS];
  /** 
   * Initialize the parent interface connections. 
   *
   * <p>Sets all connections state to invalid.</p> */
  static void connections_init() {
    uint8_t i;
    for (i = 0; i < MAX_NUM_CONNECTIONS; i++) {
      connections[i].state = invalid;
    }
  }

  /* **********************************************************************
   * Various (interrupt, counts, debugs)
   * *********************************************************************/

  /** How many numbers of Bluetooth errors to ignore on startup */
  static uint8_t btCountIgnore;

#ifdef CLOCK_DEBUG
  /* This is used to flash the leds, when debugging with the Clock on */
  static uint8_t countClock; 
#endif




  /* **********************************************************************
   * **********************************************************************
   * FUNCTIONS
   * **********************************************************************
   * *********************************************************************/


  /* **********************************************************************
   * btfail - fail hard, if we get fails from the bluetooth device we
   * can't
   * handle
   * *********************************************************************/

  /**
   * Fail hard, if we get fails from the bluetooth device we can't
   * handle.
   *
   * <p>Checks for common "situations" that we don't mind, fail
   * for all others, flashing the 4 lower bits of code, and all the
   * bits of param.</p>
   * 
   * @param btdev the btdevice which failed
   * @param code the error code from the device
   * @param param optional parameters for the error */
  static void btfail(btdevnum_t btdev, int code, uint16_t param) {
    INT_START
    INT_DISABLE
    /* Wellknown "errors" that we simply ignore */

    /* Superflous zeros when starting */
    if (UNKNOWN_PTYPE == code) { //  && param == 0) {
      /*      if (btCountIgnore != 0) {
	btCountIgnore--;
      */	INT_ENABLE
	return;
      /*}*/
    }

    /* Really unknown events - we trigger some due to our misuse of
       the ACL packets */
    if (UNKNOWN_EVENT == code && 
	(
	 ((param & 0xFF) == 0xFF)    // Really not known
	 || ((param & 0xFF) == 0x1B) // Baseband packet size change..
	 // (((param & 0xFF) == 0x69) || // dunno
	 // ((param & 0xFF) == 0x6d) || // dunno
	 // ((param & 0xFF) == 0x19)    // dunno
	 || ((param & 0xFF) == 0x00) // dunno
	 )
	) {
      INT_ENABLE
      return;
    }

    /* Fail on this error */
    FAIL4(FAIL_BT | btdev, code, param, param >> 4);
    INT_STOP
  }


  /* **********************************************************************
   * Buffer memory management
   * *********************************************************************/
  /**
   * Initialize the buffer manager.
   * 
   * <p>Initialize all the buffers to point at something, or NULL.</p> */
  static void buffers_init() {
    int i;
    for (i = 0; i < NUM_BUFFERPS; i++) {
      if (i < NUM_BUFFERS) {
	bufferps[i] = &(buffers[i]);
      } else {
	bufferps[i] = NULL;
      }
    }
  }

  /**
   * Get a buffer.
   *
   * <p>Get a free buffer from the buffer pool.</p>
   * @return A pointer to a free buffer, or NULL if no free was found */
  static gen_pkt * buffer_get() {
    gen_pkt * res;
    int i;
    INT_START
    INT_DISABLE;
    for (i = 0; i < NUM_BUFFERPS; i++) {
      if (bufferps[i] != NULL) {
	res = bufferps[i];
	bufferps[i] = NULL;
	INT_ENABLE;
	return res;
      }
    }
    INT_STOP
    FAIL2(FAIL_BUFFER, FAIL_BUFFER_GET);
    // INT_ENABLE;
    return NULL;
  }

  /**
   * Free a buffer.
   *
   * <p>Free a buffer and put it back into the buffer pool.</p>
   *
   * @return NULL if OK, else buf */
  static gen_pkt * buffer_put(gen_pkt * buf) {
    int i;
    INT_START
    INT_DISABLE;
    for (i = 0; i < NUM_BUFFERPS; i++) {
      if (bufferps[i] == NULL) {
	bufferps[i] = buf;
	INT_ENABLE;
	return NULL;
      } else { /* Checking for "double-freeing" */
	if (bufferps[i] == buf) {
	  FAIL2(FAIL_BUFFER, FAIL_BUFFER_PUTDUPLICATE);
	}
      }
    }
    INT_STOP
    FAIL2(FAIL_BUFFER, FAIL_BUFFER_PUT);
    // INT_ENABLE;
    return buf;
  }

  /* **********************************************************************
   * Delay buffer memory management
   * *********************************************************************/
  /**
   * Initialize the buffer queue.
   * 
   * <p>Initialize the buffer queue to be empty.</p> 
   *
   * <p>The buffer queue is a FIFO queue used to delay sending a bit, 
   * when the Bluetooth layer (temporarily) can not handle the buffer.</p> */
  static void delay_buffers_init() {
    int i;
    for (i = 0; i < NUM_DELAY_BUFFERPS; i++) {
      delay_bufferps[bt_dev_0][i] = NULL;
      delay_bufferps[bt_dev_1][i] = NULL;
    }
    delay_first[bt_dev_0] = 0;
    delay_next[bt_dev_0]  = 0;
    delay_first[bt_dev_1] = 0;
    delay_next[bt_dev_1]  = 0;
  };
  
  /**
   * Check if the buffer queue is non-empty.
   * 
   * @param btdev <code>bt_dev_0</code> or <code>bt_dev_1</code>
   * @return TRUE if there are buffers to be send, FALSE otherwise */
  static bool delay_pending(btdevnum_t btdev) {
    return delay_first[btdev] != delay_next[btdev];
  }
  
  /**
   * Insert a buffer into the buffer queue.
   * 
   * @param btdev <code>bt_dev_0</code> or <code>bt_dev_1</code>
   * @param buf A pointer to the buffer that needs to be inserted
   * @return NULL if successful, buf otherwise */
  static hci_acl_data_pkt * delay_put(btdevnum_t btdev, hci_acl_data_pkt * buf) {
    INT_START
    INT_DISABLE;
    if (buf == NULL) {
      FAIL3(FAIL_DELAY_BUFFER | btdev, FAIL_DELAY_PUT, 
	    FAIL_DELAY_NULLBUF);
    }
    if (delay_bufferps[btdev][delay_next[btdev]] != NULL) {
      FAIL3(FAIL_DELAY_BUFFER | btdev, FAIL_DELAY_PUT, 
	    FAIL_DELAY_BUSYSLOT);
    }

    delay_bufferps[btdev][delay_next[btdev]] = buf;

    // delay_next[btdev]++; 
    // delay_next[btdev] = delay_next[btdev] % NUM_DELAY_BUFFERPS;
    delay_next[btdev]++;
    if (delay_next[btdev] >= NUM_DELAY_BUFFERPS) {
      delay_next[btdev] = 0;
    }

    /* Semantics is, that first and next equal == empty queue,
       this actually wastes a pointer, but that is like wasting a flag, I guess. */
    if (delay_next[btdev] == delay_first[btdev]) {
      FAIL4(FAIL_DELAY_BUFFER | btdev, FAIL_DELAY_PUT, 
	    FAIL_DELAY_OUTOFSLOTS, delay_first[btdev]);
    }
    INT_ENABLE;
    INT_STOP
    return NULL;
  }

  /**
   * Insert a buffer into the buffer queue at the front.
   *
   * <p>Used to insert a buffer back into the queue, if the Bluetooth 
   * layer can still not handle it.</p>
   * 
   * @param btdev <code>bt_dev_0</code> or <code>bt_dev_1</code>
   * @param buf A pointer to the buffer that needs to be inserted
   * @return NULL if successful, buf otherwise */
  static hci_acl_data_pkt * delay_putfront(btdevnum_t btdev, hci_acl_data_pkt * buf) {
    INT_START
    INT_DISABLE;
    // FAIL2(FAIL_GENERAL, FAIL_DELAY_BUFFERPUTFRONT);
    // FAIL2(FAIL_DELAY_BUFFER | btdev, FAIL_DELAY_PUTFRONT);
    delay_first[btdev]--;
    if (delay_first[btdev] < 0) {
      delay_first[btdev] = NUM_DELAY_BUFFERPS;
    }
    if (delay_next[btdev] == delay_first[btdev]) {
      FAIL4(FAIL_DELAY_BUFFER | btdev, FAIL_DELAY_PUTFRONT, 
	    FAIL_DELAY_OUTOFSLOTS, delay_first[btdev]);
    }

    /* I am not sure this should ever really happen... 
       But I have seen it. Probably a bug here somewhere.. sigh */
    if (delay_bufferps[btdev][delay_first[btdev]] != NULL) {
      FAIL3(FAIL_DELAY_BUFFER | btdev, FAIL_DELAY_PUTFRONT, 
	    FAIL_DELAY_BUSYSLOT);
    }
    delay_bufferps[btdev][delay_first[btdev]] = buf;
    INT_ENABLE;
    INT_STOP
    return NULL;
  }

  /**
   * Get a buffer from the buffer queue.
   *
   * <p>Get the front buffer out of the queue.</p>
   * 
   * @param btdev <code>bt_dev_0</code> or <code>bt_dev_1</code>
   * @return A pointer to the first buffer if successful, NULL otherwise */
  static hci_acl_data_pkt * delay_get(btdevnum_t btdev) {
    hci_acl_data_pkt * res;
    INT_START;
    INT_DISABLE;
    if (!delay_pending(btdev)) {
      FAIL3(FAIL_DELAY_BUFFER | btdev, FAIL_DELAY_GET, 
	    FAIL_DELAY_NO_PENDING);
    }
    res = delay_bufferps[btdev][delay_first[btdev]];
    if (res == NULL) {
      FAIL5(FAIL_DELAY_BUFFER | btdev, FAIL_DELAY_GET, 
	    FAIL_DELAY_NULLBUF, delay_first[btdev], delay_next[btdev]); 
    }
    /* Reset the one we got ... */
    delay_bufferps[btdev][delay_first[btdev]] = NULL;
    delay_first[btdev]++;
    if (delay_first[btdev] >= NUM_DELAY_BUFFERPS) {
      delay_first[btdev] = 0;
    }
    INT_ENABLE;
    INT_STOP;
    return res;
  }

  /* **********************************************************************
   * Helper functions
   * *********************************************************************/

  /* These are the modes used for the different scan modes */
  /* or these together */
  // #define SCAN_DISABLE 0x00
  // #define PSCAN_ENABLE 0x02
  // #define ISCAN_ENABLE 0x01
  // #define SCAN_ENABLE 0x03
#define CHILD_SCAN_ENABLEMODE    0x2
#define CHILD_SCAN_DISABLEMODE   0x0
#define PARENT_SCAN_ENABLEMODE   0x3
#define PARENT_SCAN_DISABLEMODE  0x0

  /**
   * Function used to enable and disable scans.
   *
   * <p>A helper function used to set the scan mode on the different
   * interfaces.</p>
   *
   * @param btdev <code>bt_dev_0</code> or <code>bt_dev_1</code>
   * @param mode New mode, use one of<br>
   * <code>CHILD_SCAN_ENABLEMODE</code><br>
   * <code>CHILD_SCAN_DISABLEMODE</code><br>
   * <code>PARENT_SCAN_ENABLEMODE</code><br>
   * <code>PARENT_SCAN_DISABLEMODE</code> */
  static void postScanChange(btdevnum_t btdev, uint8_t mode) {
    gen_pkt * cmd_buffer = buffer_get();
    rst_send_pkt(cmd_buffer);
    // cmd_buffer->end      = &cmd_buffer->data[200 - 1];
    cmd_buffer->start    = cmd_buffer->end - 1;
    /* 3 == inq and scan */
    (*(cmd_buffer->start)) = mode;
    if (bt_dev_0 == btdev) {
      if (FAIL == (call Bluetooth0.postWriteScanEnable(cmd_buffer))){
	FAIL2(FAIL_POST | bt_dev_0, FAIL_POST_SCANCHANGE);
      }
    } else {
      if (FAIL == (call Bluetooth1.postWriteScanEnable(cmd_buffer))){
	FAIL2(FAIL_POST | bt_dev_1, FAIL_POST_SCANCHANGE);
      }
    }
  }
  
  /**
   * Convert a bdaddr to an ascii string.
   * 
   * <p>Function that writes a bdaddr_t to a char * and terminates with a 0.</p>
   *
   * @param buf buffer to write into - caller has allocated space.
   * @param address bdaddr_t to write
   * @return address of 0 */
  static char * bdaddrToAscii(char * buf, bdaddr_t * address) {
    uint8_t * i = (uint8_t *) address;
    uint8_t * stop = i + sizeof(bdaddr_t);
    uint8_t v;
    int sep = FALSE;
    while(i < stop) {
      if (sep) {
	*buf = ':';
	++buf;
      }
      v = (0xF0 & *i) >> 4; // left digit
      if (v < 0xA) {
	*buf = v + '0';
      } else {
	*buf = v - 0xA + 'A';
      }
      ++buf;
      v = 0x0F & *i; // right digit
      if (v < 0xA) {
	*buf = v + '0';
      } else {
	*buf = v - 0xA + 'A';
      }
      buf++; ++i; sep = TRUE;
    }
    *buf = 0;
    return buf;
  }

  /* **********************************************************************
   * A method to send or queue an acl packet
   * *********************************************************************/
  /** 
   * Send an ACL packet.
   *
   * <p>Send a wellformed ACL packet out on an interface.</p>
   *
   * @param btdev <code>bt_dev_0</code> or <code>bt_dev_1</code>
   * @param pkt The ACL packet to send */
  static void sendAcl(btdevnum_t btdev, hci_acl_data_pkt * pkt) {
    if (bt_dev_0 == btdev) {
      if (SUCCESS != call Bluetooth0.postAcl(pkt)) {
	delay_put(bt_dev_0, (hci_acl_data_pkt *) pkt);
      } 
    } else {
      if (SUCCESS != call Bluetooth1.postAcl(pkt)) {
	delay_put(bt_dev_1, (hci_acl_data_pkt *) pkt);
      }
    }
  }

  /* **********************************************************************
   * sendChildCharACL
   * *********************************************************************/

#ifndef ASSEMBLY_CHATTER
#define sendChildCharACL(a)
#else
  /**
   * Send a string message via the ACL connection on the child (bt0) interface.
   *
   * <p>This function takes the string passed to it, prepends the
   * local Bluetooth Address and sends it via the child (bt0)
   * interface as an ACL packet.</p>
   *
   * <p>This function will fail if the child interface is not
   * connected (in the <code>csHaveParent</code> state.</p>
   *
   * @param buf 0 terminated string to send */
  static void sendChildCharACL(char * buf) {
    /* Buf is 0 terminated always */
    char * tmpp;
    int leng = strlen(buf) + 1; // Remember trailing 0! (damnit)
    hci_acl_data_pkt * data_send_buffer; 

    if (csHaveParent != childState
	|| connections[PARENT_CONNECTION_NUM].state != connected) {
      return;
      /* Used to fail - now is ignored to allow the assemble command to work. */
      // FAIL2(FAIL_GENERAL, FAIL_CHILD_WRONGSTATE_SCCA);
    }

    data_send_buffer = (hci_acl_data_pkt *) buffer_get(); 
    /* Send the stuff over bluetooth */
    rst_send_pkt((gen_pkt *) data_send_buffer);
    //    data_send_buffer->end = data_send_buffer->data
    //  + 200; //+ HCIPACKET_BUF_SIZE;
    // 17 is the length of a btaddress
    // 2 is =>
    data_send_buffer->start = (hci_acl_hdr*)
      (data_send_buffer->end - (leng + 17 + 2));
    tmpp = (char *) data_send_buffer->start;
    tmpp = bdaddrToAscii(tmpp, &childAddr);
    *tmpp = '='; tmpp++;
    *tmpp = '>'; tmpp++;
    /* Actually copy the string into the buffer - including the trailing 0 */
    strcpy(tmpp, buf);
    data_send_buffer->start
      = (hci_acl_hdr*)(((uint8_t*) data_send_buffer->start) -
		       sizeof(hci_acl_hdr));
    data_send_buffer->start->handle = connections[PARENT_CONNECTION_NUM].handle;
    /* I hope these are the right values to set the flags for... */
    data_send_buffer->start->pb = 1;
    data_send_buffer->start->bc = 0;
    data_send_buffer->start->dlen = leng + 19;
    
    sendAcl(bt_dev_0, data_send_buffer);
  }
#endif

  /* **********************************************************************
   * The StdControl stuff
   * *********************************************************************/
  
  /**
   * Initialize the component.
   *
   * <p>No big deal here - interfaces are initalised, states set to
   * NotReady, variables initialized.</p> */
  command result_t StdControl.init() {
    result_t res;

    // Will only be cleared if we are actually using the debug stuff.
    debug(0);

    /* Clear out the buffers */
    buffers_init();
    delay_buffers_init();

    /* Set the states of the interfaces */
    childState  = csNotReady;
    parentState = psNotReady;

    /* Client interface variables */
    // TODO: Race conditions on the way this variable is used?
    childInqResultPkt     = NULL;

    /* Parent interface variables */
    /* Clear out our childInfos */
    connections_init();
    
    btCountIgnore         = 4; // This may be a bit problematic...
#ifdef CLOCK_DEBUG
    countClock            = 0;
#endif
    /* Init the bluetooth interfaces */
    res = call Bluetooth0.init(buffer_get());
    res = res & call Bluetooth1.init(buffer_get());
    if (res != SUCCESS) {
      dbg(DBG_USR1, "Assembly.init() failed to init bluetooth devices");
      FAIL2(FAIL_GENERAL, FAIL_BT_INIT);
    } else {
      // debug(DEBUG_BT_INIT);
    }
    
    return res;
  }

  /**
   * Start the component.
   *
   * <p>Start the Clock, if we are using it.</p> */
  command result_t StdControl.start() {
#ifdef CLOCK_DEBUG
    /* We do not want to use the clock right now... */
    return call Clock.setRate(TOS_I1PS, TOS_S1PS);
#else
    return SUCCESS;
#endif
  }

  /** Stop the component. */
  command result_t StdControl.stop() {
#ifdef CLOCK_DEBUG
    return call Clock.setRate(TOS_I0PS, TOS_S0PS);
#else
    return SUCCESS;
#endif
  }


  /* **********************************************************************
   * **********************************************************************
   * Timer testing
   * **********************************************************************
   * *********************************************************************/
#ifdef CLOCK_DEBUG
  /** 
   * Handler for the Clock.fire event.
   * 
   * <p>Increase the countClock variable, set the leds to reflect
   * this.</p> */
  event result_t Clock.fire() {
    countClock++;
    call debug(countClock);
    return SUCCESS;
  }
#endif
  

  /* **********************************************************************
   * Handle commands associated with the assembly interface
   * *********************************************************************/
  /**
   * Join an existing network.
   *
   * <p>Check if the state is right, then performs an inquery and changes the
   * state.</p> */
  command result_t Assembly.join() {
    if (csIdle != childState) {
      return FAIL;
    }
    if (FAIL == call Bluetooth0.postInquiryDefault(buffer_get())) {
      return FAIL;
    }
    childState = csInqPending;
    debug(DEBUG_CHILDSTATE_INQPENDING);
    return SUCCESS;
  }

  /* Forward declare parent interface method that opens the parent
     interface for connections. */
  task void openParentInterface();
  
  /**
   * Assemble the network.
   *
   * <p>Checks the state, then opens the parent interface.</p> */
  command result_t Assembly.assemble() {
    if (csIdle != childState) {
      return FAIL;
    }
    post openParentInterface();
    return SUCCESS;
  }
  
  /**
   *  Get a pointer to an array of connections.
   * 
   * @return pointer to the connections array */
  command connectionId * Assembly.getConnections() {
    return connections;
  }

  /**
   * Send an ACL packet on a given connection.
   * 
   * <p>This functions fill ins part of the ACL header, then calls
   * <code>sendAcl</code>.</p>
   *
   * @param connection The connection to send data to
   * @param pkt the packet to send. Flags and handle will be set by the 
   *            assembly layer, but the packet must be formatted correctly
   *             otherwise
   * @return SUCCESS or FAILURE (fail is not connected) */
  command result_t Assembly.postSend(connectionId * connection, hci_acl_data_pkt * pkt) {
    if (connection->state != connected) {
      return FAIL;
    }
    /* Change ACL flags - wont go through otherwise */
    ((hci_acl_hdr*)pkt->start)->pb     = 1;
    ((hci_acl_hdr*)pkt->start)->bc     = 0;
    /* Set the outgoing handle */
    ((hci_acl_hdr*)pkt->start)->handle = connection->handle;
    /* Post it on the right interface */
    sendAcl(connection->btdev, pkt);
    return SUCCESS;
}

    /**
   * Send a string on a given connection.
   * 
   * <p>This functions sends a string to the connection, by allocating
   * a packet, filling it in, and calling <code>postSend</code>./p>
   *
   * @param connection The connection to send data to
   * @param str The string to send
   * @return SUCCESS or FAILURE (fail is not connected) */
  command result_t Assembly.postSendString(connectionId * connection, char * str) {
    /* Buf is 0 terminated always */
    char * tmpp;
    int leng = strlen(str); /* Do not include trailing 0! */
    hci_acl_data_pkt * data_send_buffer = (hci_acl_data_pkt *) buffer_get(); 
    /* Send the stuff over bluetooth */
    rst_send_pkt((gen_pkt *) data_send_buffer);
    data_send_buffer->start = (hci_acl_hdr*)
      (data_send_buffer->end - leng);
    tmpp = (char *) data_send_buffer->start;
    /* Actually copy the string into the buffer - excluding the trailing 0 */
    memcpy(tmpp, str, leng);
    /* Set the start pointer rigth */
    data_send_buffer->start
      = (hci_acl_hdr*)(((uint8_t*) data_send_buffer->start) -
		       sizeof(hci_acl_hdr));
    data_send_buffer->start->dlen = leng;
    if (SUCCESS != call Assembly.postSend(connection, data_send_buffer)) {
      buffer_put((gen_pkt *) data_send_buffer);
      return FAIL;
    } else {
      return SUCCESS;
    }
  }

  /* Memory management for your convenience, etc. */
  /** 
   * Get a _uninitialized_ buffer.
   * 
   * <p>Simply calls buffer_get.</p>
   * @return a pointer to a free buffer or NULL if no free (FAIL) */
  async command hci_acl_data_pkt * Assembly.getBuffer() {
    return (hci_acl_data_pkt *) buffer_get();
  }
  
  /** 
   * Put a buffer that are no longer used .
   * 
   * <p>Simply calls buffer_put.</p>
   *
   * @param pkt pointer to unused buffer
   * @return NULL if success, the pointer itself otherwise (FAIL) */
  async command hci_acl_data_pkt * Assembly.putBuffer(hci_acl_data_pkt * pkt) {
    return (hci_acl_data_pkt *) buffer_put((gen_pkt *) pkt);
  }

  /**
   * Send a buffer towards the root of the Bluetooth tree.
   * 
   * <p>Simply calls sendChildCharACL</p>
   *
   * @param buf The nulterminated string to send up. */
  command void Assembly.sendUp(char * buf) {
    sendChildCharACL(buf);
  }

  /* Include the state machine file 

     The point of having it in its own file is simply to make it
     easier to get an overview. */

#include "AssemblyMStateMachine.nc"
} // Implementation
