// $Id: 

/*									tab:4
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2004 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/* Authors:  Philip Levis
 *
 */

/**
 * Implementation for Blink application.  Toggle the red LED when the
 * timer fires, using tasks.
 * @author Su Ping <sping@intel-research.net>
 * @author Intel Research Berkeley Lab
 **/

module MaxCliqueM {
  provides {
    interface StdControl;
  }
  uses {
    interface StdControl as SubControl;

    interface Leds;
    interface Random;
    interface RouteQuery;

    interface Timer as StartTimer;
    interface Timer as ResponseTimer;
    interface Timer as CliqueTimer;
    interface Timer as CliqueSendTimer;
    
    interface Send;
    
    interface SendMsg as SendClique;
    interface ReceiveMsg as ReceiveClique;

    interface SendMsg as SendCliqueResponse;
    interface ReceiveMsg as ReceiveCliqueResponse;

  }
}


implementation {

  enum {
    CLIQUE_ADD,
    CLIQUE_VERIFY,
  };
  
  int16_t startCounter;
  int16_t cliqueCounter;
  int16_t responseCounter;
  
  int8_t cliqueCount;
  uint16_t myClique[CLIQUE_SIZE];
  bool cliqueResponse[CLIQUE_SIZE];
  bool sendingClique;
  bool sendingResponse;
  uint8_t cliqueState;
  
  TOS_Msg msg;

  TOS_Msg routeBuffer;
  bool routeBusy;
  
  TOS_Msg responseBuffer;
  
  TOS_Msg recvBuffer;
  TOS_MsgPtr recvPointer;
  

  void printClique() {
#ifdef PLATFORM_PC
    int i;
    char tBuf[128];
    printTime(tBuf, 128);
    dbg(DBG_USR2, "CLIQUE: ");
    for (i = 0; i < cliqueCount; i++) {
      dbg_clear(DBG_USR2, "[0x%hx]", myClique[i]);
    }
    dbg_clear(DBG_USR2, "@ %s\n", tBuf);
#endif
    if (!routeBusy) {
      uint16_t len;
      uint8_t* buf = call Send.getBuffer(&routeBuffer, &len);
      if (len > CLIQUE_SIZE * sizeof(uint16_t)) {
	len = (CLIQUE_SIZE) * sizeof(uint16_t);
      }
      memcpy(buf, myClique, len);
      if (call Send.send(&routeBuffer, len) == SUCCESS) {
	routeBusy = TRUE;
      }
    }
  }
  
  void pushToClique(uint16_t addr) {
    myClique[cliqueCount] = addr;
    cliqueCount++;
  }

  uint16_t popFromClique() {
    uint16_t rval;
    cliqueCount--;
    rval = myClique[cliqueCount];
    myClique[cliqueCount] = TOS_BCAST_ADDR;
    return rval;
  }

  bool cliqueContains(uint16_t addr) {
    int i;
    for (i = 0; i < cliqueCount; i++) {
      if (myClique[i] == addr) {
	return TRUE;
      }
    }
    return FALSE;
  }
  
  command result_t StdControl.init() {
    call Leds.init();
    call Random.init();
    call SubControl.init();
    recvPointer = &recvBuffer;
    sendingClique = FALSE;
    sendingResponse = FALSE;
    routeBusy = FALSE;
    cliqueCount = 0;
    cliqueState = CLIQUE_ADD;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call SubControl.start();
    startCounter = (call Random.rand() % 15) + 60;
    return call StartTimer.start(TIMER_REPEAT, 1000);
  }

  /**
   * Start things up.  This just sets the rate for the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.stop() {
    call SubControl.stop();
    call StartTimer.stop();
    call ResponseTimer.stop();
    call CliqueTimer.stop();
    return SUCCESS;
  }


  event result_t StartTimer.fired() {
    int i;

    if (--startCounter <= 0) {
      dbg(DBG_USR3, "CLIQUE: Init period complete. Starting detection.\n");
      call StartTimer.stop();
      for (i = 0; i < CLIQUE_SIZE; i++) {
	myClique[i] = TOS_BCAST_ADDR;
      }
      pushToClique(TOS_LOCAL_ADDRESS);
      call CliqueTimer.start(TIMER_REPEAT, 1000);
    }
    return SUCCESS;
  }

  event result_t CliqueTimer.fired() {
    if (cliqueCounter-- >= 0) {
      if (cliqueState == CLIQUE_ADD) {
	// Try adding someone to the clique
	uint8_t parentCount = call RouteQuery.getParentCount();
	int i;
	uint8_t randVal = (uint8_t)call Random.rand();

	cliqueState = CLIQUE_VERIFY;
	dbg(DBG_USR3, "CLIQUE: I have %i parents.\n", (int)parentCount);
	printClique();
	for (i = 0; i < parentCount; i++) {
	  uint8_t which = (i + randVal) % parentCount;
	  uint16_t addr = call RouteQuery.getParentID(which);
	  dbg(DBG_USR3, "CLIQUE: Try adding %i (%i)?\n", (int)addr, (int)call RouteQuery.getParentQuality(which));
	  // Is this a new, valid neighbor?
	  if (!cliqueContains(addr) &&
	      addr != TOS_LOCAL_ADDRESS &&
	      addr != TOS_BCAST_ADDR &&
	      addr != TOS_UART_ADDR &&
	      (call RouteQuery.getParentQuality(which) > QUALITY_THRESHOLD)) {
	    int j;
	    for (j = 0; j < CLIQUE_SIZE; j++) {
	      cliqueResponse[j] = 0;
	    }
	    dbg(DBG_USR2, "CLIQUE: Going to try adding %i to my clique.\n", (int)addr);
	    pushToClique(addr);
	    break;
	  }
	  else {
	    dbg(DBG_USR3, "CLIQUE: Verifying current clique.\n");
	  }
	}
      }
      else {
	// Just verify the current clique.
	dbg(DBG_USR2, "CLIQUE: Verify clique.\n");
	cliqueState = CLIQUE_ADD;
      }
      call CliqueTimer.stop();
      cliqueCounter = 3;
      memcpy(msg.data, myClique, CLIQUE_SIZE * sizeof(uint16_t));
      call CliqueSendTimer.start(TIMER_REPEAT, 2000);
    }
    return SUCCESS;
  }

  event result_t CliqueSendTimer.fired() {
    if (!sendingClique && 
	(cliqueCounter-- > 0)) {
      if (call SendClique.send(TOS_BCAST_ADDR, CLIQUE_SIZE, &msg) == SUCCESS) {
	sendingClique = TRUE;
	dbg(DBG_USR3, "CLIQUE: Sending clique advertisement.\n");
      }
      else {
	cliqueCounter++;
      }
    }
    else if (cliqueCounter <= 0) {
      int i;
      responseCounter = cliqueCount * 3;
      for (i = 1; i < (cliqueCount - 1); i++) {
	myClique[i] = FALSE;
      }
      call CliqueSendTimer.stop();
      call ResponseTimer.start(TIMER_REPEAT, 1000);
    }
    return SUCCESS;
  }

  
  event result_t ResponseTimer.fired() {
    if (responseCounter-- <= 0) {
      int i;
      for (i = 1; i < (cliqueCount - 1); i++) { // Skip the first one, it's us
	if (myClique[i] == FALSE) {
	  uint16_t id = popFromClique();
	  dbg(DBG_USR3, "CLIQUE: Popping %i from clique, %i didn't respond.\n", (int)id, (int)myClique[i]);
	  break;
	}
      }
      dbg(DBG_USR3, "CLIQUE: Response period complete.\n");
      call ResponseTimer.stop();
      cliqueCounter = 1;
      call CliqueTimer.start(TIMER_REPEAT, 1000);
    }
    return SUCCESS;
  }

  task void receiveTask() {
    CliqueMsg* cmsg = (CliqueMsg*)recvPointer->data;
    bool success = TRUE;
    int i;
    if (sendingResponse) {return;}
    
    for (i = 0; i < CLIQUE_SIZE; i++) {
      bool contains = FALSE;
      uint8_t numParents = call RouteQuery.getParentCount();
      uint16_t prospective = cmsg->elements[i];
      if (prospective == TOS_BCAST_ADDR) {break;}
      if (prospective == TOS_LOCAL_ADDRESS) {continue;}
      else {
	int j;
	for (j = 0; j < numParents; j++) {
	  uint16_t existing = call RouteQuery.getParentID(j);
	  uint16_t quality = call RouteQuery.getParentQuality(j);
	  if (existing == prospective) {
	    //dbg(DBG_USR3, "CLIQUE: Testing member %i, quality %i.\n", (int)existing, quality);
	    if (quality >= QUALITY_THRESHOLD) {
	      contains = TRUE;
	    }
	  }
	}
	if (!contains) {
	  success = FALSE;
	  break;
	}
      }
    }
    if (success) {
      CliqueResponseMsg* rmsg = (CliqueResponseMsg*)responseBuffer.data;
      rmsg->cliqueID = cmsg->elements[0];
      rmsg->address = TOS_LOCAL_ADDRESS;
      rmsg->response = CLIQUE_ACCEPT;
      dbg(DBG_USR3, "CLIQUE: Accepting the clique from %i.\n", (int)cmsg->elements[0]);
    }
    else {
      CliqueResponseMsg* rmsg = (CliqueResponseMsg*)responseBuffer.data;
      rmsg->cliqueID = cmsg->elements[0];
      rmsg->address = TOS_LOCAL_ADDRESS;
      rmsg->response = CLIQUE_REJECT;
      dbg(DBG_USR3, "CLIQUE: Rejecting the clique from %i.\n", (int)cmsg->elements[0]);
    }

    if (call SendCliqueResponse.send(cmsg->elements[i], sizeof(CliqueResponseMsg), &responseBuffer) == SUCCESS) {
      sendingResponse = TRUE;
    }
  }
  

  event TOS_MsgPtr ReceiveClique.receive(TOS_MsgPtr m) {
    TOS_MsgPtr tmp = recvPointer;
    CliqueMsg* cmsg = (CliqueMsg*)m->data;
    int i;
    for (i = 0; i < CLIQUE_SIZE; i++) {
      if (cmsg->elements[i] == TOS_LOCAL_ADDRESS) {
	dbg(DBG_USR3, "CLIQUE: Heard a clique advertisement of which I am a member.\n");
	post receiveTask();
	break;
      }
    }
    recvPointer = m;
    return tmp;
  }
  
  event TOS_MsgPtr ReceiveCliqueResponse.receive(TOS_MsgPtr m) {
    CliqueResponseMsg* rmsg = (CliqueResponseMsg*)m->data;
    if (rmsg->cliqueID == TOS_LOCAL_ADDRESS &&
	rmsg->response == CLIQUE_ACCEPT) {
      int i;
      for (i = 0; i < CLIQUE_SIZE; i++) {
	if (myClique[i] == rmsg->address) {
	  dbg(DBG_USR3, "CLIQUE: %i accepted the clique.\n", (int)myClique[i]);
	  cliqueResponse[i] = TRUE;
	}
      }
    }
    return m;
  }


  event result_t SendClique.sendDone(TOS_MsgPtr m, result_t success) {
    sendingClique = FALSE;
    return SUCCESS;
  }
  
  event result_t SendCliqueResponse.sendDone(TOS_MsgPtr m, result_t success) {
    sendingResponse = FALSE;
    if (m->ack) {
      responseCounter = -1;
    }
    return SUCCESS;
  }

  event result_t Send.sendDone(TOS_MsgPtr m, result_t success) {
    routeBusy = FALSE;
    return SUCCESS;
  }
  
}

