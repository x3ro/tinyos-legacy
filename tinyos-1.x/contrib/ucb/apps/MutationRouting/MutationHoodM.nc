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


includes MutationRoute;

module MutationHoodM {
  provides interface MutationHood;
  uses interface Timer;
}

implementation {
  Mutation mutations[MR_NUM_NEIGHBORS];
  uint16_t recruit;


  int getIndex(uint16_t id) {
    int i;
    for (i = 0; i < MR_NUM_NEIGHBORS; i++) {
      if (mutations[i].id == id) {
	mutations[i].timeout = 0;
	return i;
      }
    }
    return -1;
  }

  event result_t Timer.fired() {
    int i;
    for (i = 0; i < MR_NUM_NEIGHBORS; i++) {
      if (mutations[i].id == TOS_LOCAL_ADDRESS) {
	mutations[i].timeout = 0;
      }
      if (mutations[i].id != 0 && (mutations[i].timeout == 1 || (mutations[i].timeout == 0 && !mutations[i].cost && !mutations[i].seqNo))) {
	//dbg(DBG_USR3, "resetting id: %d\n", mutations[i].id);
	mutations[i].id = 0;
	mutations[i].child = 0;
	mutations[i].parent = 0;
	mutations[i].cost = 0;
	mutations[i].seqNo = 0;
	mutations[i].sendFailCount = 0;
	mutations[i].onShortcutBlacklist = 0;
	mutations[i].onRecruitBlacklist = 0;
	mutations[i].timeout = 0;
	}
      else {
	if (mutations[i].id != 0) {
	  mutations[i].timeout = 1;
	}
      }
    }
    return SUCCESS;
  }


  command result_t MutationHood.init() {
    int i;
    for (i = 0; i < MR_NUM_NEIGHBORS; i++) {
      mutations[i].id = 0;
      mutations[i].timeout = 0;
    }
    recruit = 0;
    return SUCCESS;
  }

  command result_t MutationHood.start() {
    call Timer.start(TIMER_REPEAT, HOOD_TIMEOUT);
    return SUCCESS;
  }

  command uint16_t MutationHood.getParent(uint16_t id) {
    int i;
    if (id == 0) {
      //dbg(DBG_USR3, "id = 0\n");
    }
    for (i = 0; i < MR_NUM_NEIGHBORS; i++) {
      if (mutations[i].id == id) {
	return mutations[i].parent;
      }
    }
    return 0;
  }

  command uint16_t MutationHood.getChild(uint16_t id) {
    int i;
    if (id == 0) {
      //dbg(DBG_USR3, "id = 0\n");
    }
    for (i = 0; i < MR_NUM_NEIGHBORS; i++) {
      if (mutations[i].id == id) {
	return mutations[i].child;
      }
    }
    return 0;
  }

  command uint8_t MutationHood.getCost(uint16_t id) {
    int i;
    if (id == 0) {
      //dbg(DBG_USR3, "id = 0\n");
    }
    for (i = 0; i < MR_NUM_NEIGHBORS; i++) {
      if (mutations[i].id == id) {
	return mutations[i].cost;
      }
    }
    return 0;
  }

  command uint16_t MutationHood.getSeqNo(uint16_t id) {
    int i;
    if (id == 0) {
      //dbg(DBG_USR3, "id = 0\n");
    }
    for (i = 0; i < MR_NUM_NEIGHBORS; i++) {
      if (mutations[i].id == id) {
	return mutations[i].seqNo ;
      }
    }
    return 0;
  }

  command uint8_t MutationHood.getFailCount(uint16_t id) {
    int i;
    if (id == 0) {
      //dbg(DBG_USR3, "id = 0\n");
    }
    for (i = 0; i < MR_NUM_NEIGHBORS; i++) {
      if (mutations[i].id == id) {
	return mutations[i].sendFailCount;
      }
    }
    return 0;
  }

  command uint8_t MutationHood.getOnShortcutBlacklist(uint16_t id) {
    int i;
    if (id == 0) {
      //dbg(DBG_USR3, "id = 0\n");
    }
    for (i = 0; i < MR_NUM_NEIGHBORS; i++) {
      if (mutations[i].id == id) {
	return mutations[i].onShortcutBlacklist;
      }
    }
    return 0;
  }

  command uint8_t MutationHood.getOnRecruitBlacklist(uint16_t id) {
    int i;
    if (id == 0) {
      //dbg(DBG_USR3, "id = 0\n");
    }
    for (i = 0; i < MR_NUM_NEIGHBORS; i++) {
      if (mutations[i].id == id) {
	return mutations[i].onRecruitBlacklist;
      }
    }
    return 0;
  }

  command uint16_t MutationHood.getNumNeighbors(uint16_t id) {
    int i;
    uint16_t num = 0;
    if (id == 0) {
      //dbg(DBG_USR3, "id = 0\n");
    }
    for (i = 0; i < MR_NUM_NEIGHBORS; i++) {
      if (mutations[i].id != 0 && mutations[i].id != id) {
	num++;
      }
    }
    return num;
  }


  command uint16_t MutationHood.getLowestCostNeighbor(uint16_t id) {
    int i;
    uint8_t cost = -1;
    uint16_t lowest = -1;
    if (id == 0) {
      //dbg(DBG_USR3, "id = 0\n");
    }
    for (i = 0; i < MR_NUM_NEIGHBORS; i++) {
      if (mutations[i].id && mutations[i].seqNo) {
	if (cost > mutations[i].cost) {
	  cost = mutations[i].cost;
	  lowest = mutations[i].id;
	}
      }
    }
    return lowest;
  }

  command uint16_t MutationHood.getHighestCostNeighbor(uint16_t id) {
    int i;
    uint8_t cost = 0;
    uint16_t highest = -1;
    if (id == 0) {
      //dbg(DBG_USR3, "id = 0\n");
    }
    for (i = 0; i < MR_NUM_NEIGHBORS; i++) {
      if (mutations[i].id && mutations[i].seqNo) {
	if (cost <= mutations[i].cost) {
	  cost = mutations[i].cost;
	  highest = mutations[i].id;
	}
      }
    }
    return highest;
  }

  command uint16_t MutationHood.getGrandparent(uint16_t id) {
    int i,j;
    uint16_t parent = 0;
    if (id == 0) {
      //dbg(DBG_USR3, "id = 0\n");
    }
    for (i = 0; i < MR_NUM_NEIGHBORS; i++) {
      if (mutations[i].id == id && mutations[i].seqNo) {
	parent = mutations[i].parent;
	for (j = 0; j < MR_NUM_NEIGHBORS; j++) {
	  if (mutations[j].id == parent) {
	    parent = mutations[j].parent;
	    if(call MutationHood.getSeqNo(parent)) {
	      return parent;
	    }
	  }
	}
      }
    }
    return 0;
  }      

  command uint16_t MutationHood.getRecruit(uint16_t id) {
    if (id == 0) {
      //dbg(DBG_USR3, "id = 0\n");
    }
    return recruit;
  }

  command uint16_t MutationHood.getRoot() {
    int i;
    for (i = 0; i < MR_NUM_NEIGHBORS; i++) {
      if (mutations[i].child == mutations[i].id && mutations[i].cost == 0 && mutations[i].seqNo != 0)
	return mutations[i].id;
    }
    return 0;
  }

  command result_t MutationHood.setID(uint16_t id) {
    int i;
    if (id == 0) {
      //dbg(DBG_USR3, "id = 0\n");
    }
    for (i = 0; i < MR_NUM_NEIGHBORS; i++) {
      if (mutations[i].id == id) {
	mutations[i].timeout = 0;
	return SUCCESS;
      }
    }
    for (i = 0; i < MR_NUM_NEIGHBORS; i++) {
      if (mutations[i].id == 0) {
	mutations[i].id = id;
	mutations[i].timeout = 0;
	return SUCCESS;
      }
    }
    if (id == TOS_LOCAL_ADDRESS) {
      for (i = 0; i < MR_NUM_NEIGHBORS; i++) {
	if (mutations[i].seqNo == 0 && mutations[i].parent == 0) {
	  mutations[i].id = id;
	  mutations[i].timeout = 0;
	  return SUCCESS;
	}
      }
    }
    return FAIL;
  }

  command result_t MutationHood.setParent(uint16_t id, uint16_t parent) {
    int ind = getIndex(id);
    uint16_t oldParent;
    if (ind != -1) {
      //dbg(DBG_USR3, "set parent of %d to %d\n", mutations[ind].id, parent);
      oldParent = mutations[ind].parent;
      mutations[ind].parent = parent;
      if (oldParent && oldParent != parent) {
	call MutationHood.setSeqNo(oldParent, 0);
      }
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t MutationHood.setChild(uint16_t id, uint16_t child) {
    int ind = getIndex(id);
    if (ind != -1) {
      //dbg(DBG_USR3, "set child of %d to %d\n", mutations[ind].id, child);
      mutations[ind].child = child;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t MutationHood.setCost(uint16_t id, uint8_t cost) {
    int ind = getIndex(id);
    if (ind != -1) {
      //dbg(DBG_USR3, "set cost of %d to %d\n", mutations[ind].id, cost);
      mutations[ind].cost = cost;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t MutationHood.setSeqNo(uint16_t id, uint16_t seqNo) {
    int ind = getIndex(id);
    if (ind != -1) {
      //dbg(DBG_USR3, "set seqNo of %d to %d\n", mutations[ind].id, seqNo);
      mutations[ind].seqNo = seqNo;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t MutationHood.setFailCount(uint16_t id, uint8_t failCount) {
    int ind = getIndex(id);
    if (ind != -1) {
      //dbg(DBG_USR3, "set fail count of %d to %d\n", mutations[ind].id, failCount);
      mutations[ind].sendFailCount = failCount;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t MutationHood.setOnShortcutBlacklist(uint16_t id, uint8_t bl) {
    int ind = getIndex(id);
    if (ind != -1) {
      //dbg(DBG_USR3, "set onShortcutBlacklist of %d to %d\n", mutations[ind].id, bl);
      mutations[ind].onShortcutBlacklist = bl;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t MutationHood.setOnRecruitBlacklist(uint16_t id, uint8_t bl) {
    int ind = getIndex(id);
    if (ind != -1) {
      //dbg(DBG_USR3, "set onRecruitBlacklist of %d to %d\n", mutations[ind].id, bl);
      mutations[ind].onRecruitBlacklist = bl;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t MutationHood.checkRecruit(uint16_t id) {
    int i, j;
    uint16_t y = call MutationHood.getLowestCostNeighbor(id);
    for (i = 0; i < MR_NUM_NEIGHBORS; i++) {
      if (mutations[i].id == id) {
	continue;
      }
      if (mutations[i].seqNo && mutations[i].cost > (call MutationHood.getCost(y) + 2)) {
	if (!(mutations[i].onRecruitBlacklist) && !(call MutationHood.getOnShortcutBlacklist(y))) {
	  for (j = i+1; j < MR_NUM_NEIGHBORS; j++) {
	    if (mutations[j].seqNo && mutations[j].cost > mutations[i].cost) {
	      i = j;
	    }
	  }
	  recruit = mutations[i].id;
	  //dbg(DBG_USR3, "set recruit of %d to %d\n", id, recruit);
	  return SUCCESS;
	}
      }
    }
    recruit = 0;
    return FAIL;
  }

  command result_t MutationHood.isNeighbor(uint16_t id) {
    if (getIndex(id) == -1) {
      return FAIL;
    }
    else {
      return SUCCESS;
    }
  }
}
