/* Copyright (c) 2002 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704. Attention: Intel License Inquiry.  
 * 
 * Author: Matt Welsh <mdw@eecs.harvard.edu>
 */

includes Spantree;

/**
 * SpantreeM: Spanning tree construction, primarily used by Reduce.
 */
module SpantreeM {
  provides interface Spantree;
  provides interface StdControl;
  uses interface Timer;
  uses interface SendMsg;
  uses interface ReceiveMsg;
}
implementation {

  typedef struct {
    spantree_t stree;
    bool pending;
    bool locked;
    int8_t timeout;
    struct TOS_Msg msg;
  } stree_cache_entry;

  stree_cache_entry stree_cache[SPANTREE_CACHE_SIZE];
  int num_maketree_pending;

  command result_t StdControl.init() {
    int i;
    for (i = 0; i < SPANTREE_CACHE_SIZE; i++) {
      stree_cache[i].stree.root = EMPTY_ROOT;
      stree_cache[i].locked = FALSE;
      stree_cache[i].pending = FALSE;
    }
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  // Start generating a tree
  result_t start_maketree(uint16_t root, stree_cache_entry *entry, uint32_t timeout) {

    MaketreeMsg *maketree_msg;
    dbg(DBG_USR2, "Spantree start_maketree called, root 0x%x\n", root);

    // If we are the root, initiate the tree creation
    if (root == TOS_LOCAL_ADDRESS) {
      entry->stree.root = root;
      entry->stree.parent = TOS_LOCAL_ADDRESS;
      entry->locked = TRUE; // Initially locked
      entry->pending = FALSE;

      // Prep message
      maketree_msg = (MaketreeMsg *)entry->msg.data;
      maketree_msg->rootaddr = TOS_LOCAL_ADDRESS;
      maketree_msg->srcaddr = TOS_LOCAL_ADDRESS;
      maketree_msg->depth = 0;

      dbg(DBG_USR2, "Spantree start_maketree broadcasting creation msg\n");
      if (call SendMsg.send(TOS_BCAST_ADDR, sizeof(MaketreeMsg), &(entry->msg)) != SUCCESS) {
        dbg(DBG_USR2, "Spantree start_maketree failed to send creation msg\n");
	return FAIL;
      }
      dbg(DBG_USR2, "Spantree start_maketree done creating spantree\n");
      signal Spantree.spantreeDone(root, &(entry->stree), SUCCESS);
      return SUCCESS;
    }

    // If not the root, set up to receive notification
    dbg(DBG_USR2, "Spantree start_maketree waiting for spantree\n");
    entry->stree.root = root;
    entry->stree.parent = SPANTREE_NO_PARENT;
    entry->pending = TRUE;
    entry->timeout = timeout / SPANTREE_MS_PER_TICK;
    if (++num_maketree_pending == 1) {
      // Start timer
      dbg(DBG_USR2, "Spantree start_maketree setting timer\n");
      if (call Timer.start(TIMER_REPEAT, SPANTREE_MS_PER_TICK) != SUCCESS) {
	dbg(DBG_USR2, "Spantree start_maketree failed to set timer\n");
	num_maketree_pending--;
	entry->pending = FALSE;
        return FAIL;
      }
    }
    return SUCCESS;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    // Just ignore; don't care if message went out
    dbg(DBG_USR2, "Spantree sendDone\n");
    return SUCCESS;
  }

  // Look for pending tree requests that have timed out
  event result_t Timer.fired() {
    int i;
    dbg(DBG_USR2, "Spantree Timer.fired()\n");
    for (i = 0; i < SPANTREE_CACHE_SIZE; i++) {
      stree_cache_entry *entry = &(stree_cache[i]);
      if (entry->pending == TRUE && entry->stree.parent == SPANTREE_NO_PARENT) {
	if (--entry->timeout == 0) {
	  // Timed out
	  entry->pending = FALSE;
          dbg(DBG_USR2, "Spantree Timer.fired() entry %d timed out\n", i);
	  signal Spantree.spantreeDone(entry->stree.root, NULL, FAIL);
	  if (--num_maketree_pending == 0) call Timer.stop();
	}
      }
    }
    return SUCCESS;
  }

  /**
   * Initiate creation of the given spanning tree.
   */
  command result_t Spantree.makeSpantree(uint16_t root, uint32_t timeout) {
    int i;

    dbg(DBG_USR2, "Spantree.makeSpantree() called, root 0x%x timeout %d\n", root, timeout);
    for (i = 0; i < SPANTREE_CACHE_SIZE; i++) {
      if (stree_cache[i].pending == FALSE && stree_cache[i].stree.root == root) {
	// Already have it
        dbg(DBG_USR2, "Spantree.makeSpantree: returning tree in cache, root 0x%x parent 0x%x depth %d\n", stree_cache[i].stree.root, stree_cache[i].stree.parent, stree_cache[i].stree.depth);
	signal Spantree.spantreeDone(root, &(stree_cache[i].stree), SUCCESS);
	return SUCCESS;
      } 
    }
    // Find an empty entry 
    for (i = 0; i < SPANTREE_CACHE_SIZE; i++) {
      if (stree_cache[i].locked == FALSE && stree_cache[i].pending == FALSE) {
        dbg(DBG_USR2, "Spantree.makeSpantree: filling cache entry %d\n", i);
        return start_maketree(root, &stree_cache[i], timeout);
      }
    }
    return FAIL;
  }

  /**
   * Signalled on message reception: look up a pending tree request
   */
  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr msg) {
    MaketreeMsg *maketree_msg = (MaketreeMsg *)msg->data;
    stree_cache_entry *entry = NULL;
    bool new_entry = FALSE;
    int i;

    uint16_t root = maketree_msg->rootaddr;
    uint8_t depth = maketree_msg->depth;

    dbg(DBG_USR2, "Spantree ReceiveMsg.receive() for root 0x%x\n", root);
    // If it's from us originally, drop
    if (maketree_msg->rootaddr == TOS_LOCAL_ADDRESS || 
	maketree_msg->srcaddr == TOS_LOCAL_ADDRESS) 
      return msg;

    // See if we have a pending request for this tree
    for (i = 0; i < SPANTREE_CACHE_SIZE; i++) {
      if (stree_cache[i].stree.root == root) {
	entry = &stree_cache[i];
	if (stree_cache[i].pending == TRUE) {
	  new_entry = TRUE;
	  if (--num_maketree_pending == 0) call Timer.stop();
	}
	break;
      }
    }
    if (entry == NULL) {
      // See if there is an empty entry
      for (i = 0; i < SPANTREE_CACHE_SIZE; i++) {
        if (stree_cache[i].locked == FALSE && stree_cache[i].pending == FALSE) {
	  entry = &stree_cache[i];
	  new_entry = TRUE;
	  break;
	}
      }
    }
    // If no entry, drop msg
    if (entry == NULL) {
      dbg(DBG_USR2, "Spantree: Can't get entry, dropping\n");
      return msg; 
    }

    // If we already have it, don't retransmit or signal
    if (!new_entry) {
      dbg(DBG_USR2, "Spantree: Already have entry\n");
      return msg;
    }

    entry->stree.root = root;
    entry->stree.parent = maketree_msg->srcaddr;
    entry->stree.depth = depth+1;
    entry->locked = TRUE;  // New entries implicitly locked
    entry->pending = FALSE;

    dbg(DBG_USR2, "Spantree: Filling cache entry, root 0x%x parent 0x%x depth %d\n", root, entry->stree.parent, depth+1);

    maketree_msg = (MaketreeMsg *)entry->msg.data;
    maketree_msg->rootaddr = root;
    maketree_msg->srcaddr = TOS_LOCAL_ADDRESS;
    maketree_msg->depth = depth+1;

    // Don't actually care if we can propagate the message onwards
    dbg(DBG_USR2, "Spantree ReceiveMsg.receive() rebroadcasting\n");
    call SendMsg.send(TOS_BCAST_ADDR, sizeof(MaketreeMsg), &(entry->msg));
    dbg(DBG_USR2, "Spantree ReceiveMsg.receive() signalling done\n");
    signal Spantree.spantreeDone(root, &(stree_cache[i].stree), SUCCESS);
    return msg;
  }

  /**
   * Lock the given cache entry. May be called multiple times.
   */
  command result_t Spantree.lockSpantree(uint16_t root) {
    int i;
    for (i = 0; i < SPANTREE_CACHE_SIZE; i++) {
      if (stree_cache[i].stree.root == root) { 
	stree_cache[i].locked = TRUE;
	return SUCCESS;
      }
    }
    return FAIL;

  }

  /**
   * Unlock the given cache entry. May be called multiple times.
   */
  command result_t Spantree.unlockSpantree(uint16_t root) {
    int i;
    for (i = 0; i < SPANTREE_CACHE_SIZE; i++) {
      if (stree_cache[i].stree.root == root) { 
	stree_cache[i].locked = FALSE;
	return SUCCESS;
      }
    }
    return FAIL;
  }

}

