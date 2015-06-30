/*									
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
 * Author: August Joki <august@berkeley.edu>
 *
 *
 *
 */


includes LinkQHood;

module LinkQHoodM {
  provides interface LinkQHood;
  uses interface Timer;
}

implementation {
  LinkQ links[LQ_NUM_NEIGHBORS];
  //uint8_t numNeighbors;
  uint8_t latestSeqNoHeard;
  uint8_t latestSeqNoSent;
  uint16_t sendTo;

  int getIndex(uint16_t id) {
    int i;
    for (i = 0; i < LQ_NUM_NEIGHBORS; i++) {
      if (links[i].id == id) {
	return i;
      }
    }
    return -1;
  }

  int sortSendLinkQFunction(const void *x, const void *y) {
    LinkQ *lx = (LinkQ *)x;
    LinkQ *ly = (LinkQ *)y;
    float qx, qy;
    if (lx->id == 0) {
      if (ly->id != 0) {
	return 1;
      }
      else {
	return 0;
      }
    }
    else {
      if (ly->id == 0) {
	return -1;
      }
    }
    qx = call LinkQHood.getSendQ(lx->id);
    qy = call LinkQHood.getSendQ(ly->id);
    if (qx > qy) return -1;
    if (qx == qy) return 0;
    if (qx < qy) return 1;
    return 0; //to keep compiler happy
  }

  int sortRecvLinkQFunction(const void *x, const void *y) {
    LinkQ *lx = (LinkQ *)x;
    LinkQ *ly = (LinkQ *)y;
    float qx, qy;
    if (lx->id == 0) {
      if (ly->id != 0) {
	return 1;
      }
      else {
	return 0;
      }
    }
    else {
      if (ly->id == 0) {
	return -1;
      }
    }
    qx = call LinkQHood.getRecvQ(lx->id);
    qy = call LinkQHood.getRecvQ(ly->id);
    if (qx > qy) return -1;
    if (qx == qy) return 0;
    if (qx < qy) return 1;
    return 0; //to keep compiler happy
  }

  void sortSend() {
    qsort(links, LQ_NUM_NEIGHBORS, sizeof(LinkQ), sortSendLinkQFunction);
  }
  
  void sortRecv() {
    qsort(links, LQ_NUM_NEIGHBORS, sizeof(LinkQ), sortRecvLinkQFunction);
  }

  int addNeighbor(uint16_t id) {
    int i;
    for (i = 0; i < LQ_NUM_NEIGHBORS; i++) {
      if (links[i].id == 0) {
	links[i].id = id;
	//numNeighbors++;
	return i;
      }
    }
    sortSend();
    links[i].id = id;
    return i;
  }

  command result_t LinkQHood.init() {
    int i;
    for (i = 0; i < LQ_NUM_NEIGHBORS; i++) {
      links[i].id = 0;
    }
    latestSeqNoHeard = 0;
    latestSeqNoSent = 0;
    sendTo = 0;
    call Timer.start(TIMER_REPEAT, LQ_TIMEOUT);
    return SUCCESS;
  }

  command result_t LinkQHood.messageReceived(uint16_t id, uint8_t macSeqNo, uint8_t routingSeqNo) {
    int ind = getIndex(id);
    if (ind == -1) {
      ind = addNeighbor(id);
    }
    //dbg(DBG_USR3, "[LinkQHood] received macSeqNo: %d, seqNo: %d from: %d\n", macSeqNo, routingSeqNo, id);
    links[ind].alive = TRUE;
    if (routingSeqNo > latestSeqNoHeard) {
      /*
      int i;
      for (i = 0; i < LQ_NUM_NEIGHBORS; i++) {
	if (links[i].id != 0 || links[i].id != id) {
	  links[i].numMissed++;
	}
      }
      */
      //dbg(DBG_USR3, "[LinkQHood] received new routing sequence number\n");
      latestSeqNoHeard = routingSeqNo;
    }
    /*
    if (routingSeqNo > links[ind].lastRoutingSeqNo) {
      links[ind].numMissed--;
    }
    */
    links[ind].numMissed += macSeqNo - links[ind].lastMACSeqNo - 1;
    links[ind].lastMACSeqNo = macSeqNo;
    links[ind].lastRoutingSeqNo = routingSeqNo;

    if ((id == sendTo || sendTo == TOS_BCAST_ADDR) && routingSeqNo == latestSeqNoSent) {
      links[ind].numAcked++;
    }
    return SUCCESS;
  }

  command result_t LinkQHood.messageSent(uint16_t id, uint8_t seqNo) {
    int ind = getIndex(id);
    if (ind == -1 && id != TOS_BCAST_ADDR) {
      ind = addNeighbor(id);
    }
    sendTo = id;
    if (id == TOS_BCAST_ADDR) {
      int i;
      for (i = 0; i < LQ_NUM_NEIGHBORS; i++) {
	if (links[i].id != 0) {
	  links[i].numSent++;
	}
      }
    }
    else {
      links[ind].numSent++;
    }
    latestSeqNoSent = seqNo;
    return SUCCESS;
  }


  command float LinkQHood.getSendQ(uint16_t id) {
    int ind = getIndex(id);
    if (ind != -1) {
      if (links[ind].numSent != 0) {
	//dbg(DBG_USR3, "[LinkQHood] link quality to %d: %f\n", id, ((float) links[ind].numAcked/(float) links[ind].numSent)/(call LinkQHood.getRecvQ(id)));
	return ((float) links[ind].numAcked/(float) links[ind].numSent)/(call LinkQHood.getRecvQ(id));
      }
    }
    return 0.0;
  }

  command float LinkQHood.getRecvQ(uint16_t id) {
    int ind = getIndex(id);
    if (ind != -1) {
      //dbg(DBG_USR3, "[LinkQHood] link quality from %d: %f\n", id, ((float) links[ind].lastMACSeqNo - (float) links[ind].numMissed) / ((float) links[ind].lastMACSeqNo));
      return ((float) links[ind].lastMACSeqNo - (float) links[ind].numMissed) / ((float) links[ind].lastMACSeqNo);
    }
    return 0.0;
  }

  command result_t LinkQHood.getNeighbors(uint16_t *motes, uint8_t len, bool bySend) {
    int l;
    if (bySend) {
      sortSend();
    }
    else {
      sortRecv();
    }
    if (len > LQ_NUM_NEIGHBORS) {
      //dbg(DBG_ERROR, "[LinkQHood] Too many neighbors requested %d out of %d\n", len, LQ_NUM_NEIGHBORS);
    }
    else {
      for (l = 0; l < len; l++) {
	motes[l] = links[l].id;
      }
    }
    return SUCCESS;
  }

  command bool LinkQHood.isNeighbor(uint16_t id) {
    int ind = getIndex(id);
    if (ind == -1) {
      return FALSE;
    }
    else {
      return TRUE;
    }
  }

  event result_t Timer.fired() {
    int i;
    for (i = 0; i < LQ_NUM_NEIGHBORS; i++) {
      if (links[i].id == 0) {
	continue;
      }
      if (!links[i].alive) {
	links[i].id = 0;
	//numNeighbors--;
      }
      links[i].alive = FALSE;
      // decay linkQs somehow
    }
    return SUCCESS;
  }
}
