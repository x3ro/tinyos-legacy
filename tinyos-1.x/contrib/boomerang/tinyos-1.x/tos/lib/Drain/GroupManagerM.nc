//$Id: GroupManagerM.nc,v 1.1.1.1 2007/11/05 19:09:10 jpolastre Exp $

/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 */

/**
 * @author Gilman Tolle <get@cs.berkeley.edu>
 */

includes GroupManager;

module GroupManagerM {
  provides {
    interface StdControl;
    interface GroupManager;
  }
  uses interface Timer;
}
implementation {

  bool timerActive;

  uint16_t groups[GROUPMANAGER_MAX_GROUPS];
  uint16_t groupTimeouts[GROUPMANAGER_MAX_GROUPS];
  uint16_t forwardGroups[GROUPMANAGER_MAX_GROUPS];
  uint16_t forwardGroupTimeouts[GROUPMANAGER_MAX_GROUPS];

  void clearGroups();
  void setTimer();

  command result_t StdControl.init() { clearGroups(); return SUCCESS; }
  command result_t StdControl.start() { return SUCCESS; }
  command result_t StdControl.stop() { return SUCCESS; }

  void clearGroups() {
     uint8_t i;

     for (i = 0; i < GROUPMANAGER_MAX_GROUPS; i++) {
       groups[i] = GROUPMANAGER_INVALID_GROUP;
       groupTimeouts[i] = 0;
       forwardGroups[i] = GROUPMANAGER_INVALID_GROUP;
       forwardGroupTimeouts[i] = 0;
     }
  }

  command bool GroupManager.isMember(uint16_t groupID) {
    uint8_t i;

    if (groupID == GROUPMANAGER_INVALID_GROUP)
      return FALSE;

    for (i = 0; i < GROUPMANAGER_MAX_GROUPS; i++) {
      if (groups[i] == groupID) {
	dbg(DBG_USR1, "GroupManagerM: Is a member of group %d\n", groupID);	
	return TRUE;
      }
    }
//    dbg(DBG_USR1, "GroupManagerM: Is NOT a member of group %d\n", groupID);	
    return FALSE;
  }

  command result_t GroupManager.joinGroup(uint16_t groupID, 
					  uint16_t timeout) {
    uint8_t i;

    if (groupID == GROUPMANAGER_INVALID_GROUP)
      return FALSE;

    if (call GroupManager.isMember(groupID))
      return SUCCESS;

    for (i = 0; i < GROUPMANAGER_MAX_GROUPS; i++) {
      if (groups[i] == GROUPMANAGER_INVALID_GROUP) {
	groups[i] = groupID;
	groupTimeouts[i] = timeout;
	setTimer();
	dbg(DBG_USR1, "GroupManagerM: Joined group %d\n", groupID);
	return SUCCESS;
      }
    }

    return FAIL;
  }

  command result_t GroupManager.leaveGroup(uint16_t groupID) {
    uint8_t i;

    if (groupID == GROUPMANAGER_INVALID_GROUP)
      return FALSE;

    for (i = 0; i < GROUPMANAGER_MAX_GROUPS; i++) {
      if (groups[i] == groupID) {
	groups[i] = GROUPMANAGER_INVALID_GROUP;
	groupTimeouts[i] = 0;
	dbg(DBG_USR1, "GroupManagerM: Left group %d\n", groupID);
	return SUCCESS;
      }
    }    
    return FAIL;
  }

  command bool GroupManager.isForwarder(uint16_t groupID) {
    uint8_t i;

    if (groupID == GROUPMANAGER_INVALID_GROUP)
      return FALSE;

    for (i = 0; i < GROUPMANAGER_MAX_GROUPS; i++) {
      if (forwardGroups[i] == groupID) {
	dbg(DBG_USR1, "GroupManagerM: Is forwarding for group %d\n", groupID);	
	return TRUE;
      }
    }
//    dbg(DBG_USR1, "GroupManagerM: Is NOT forwarding for group %d\n", groupID);	
    return FALSE;
  }

  command result_t GroupManager.joinForward(uint16_t groupID, uint16_t timeout) {
    uint8_t i;

    if (groupID == GROUPMANAGER_INVALID_GROUP)
      return FALSE;

    if (call GroupManager.isForwarder(groupID))
      return SUCCESS;

    for (i = 0; i < GROUPMANAGER_MAX_GROUPS; i++) {
      if (forwardGroups[i] == GROUPMANAGER_INVALID_GROUP) {
	forwardGroups[i] = groupID;
	forwardGroupTimeouts[i] = timeout;
	setTimer();
	dbg(DBG_USR1, "GroupManagerM: Started forwarding for group %d\n", groupID);
	return SUCCESS;
      }
    }

    return FAIL;
  }

  command result_t GroupManager.leaveForward(uint16_t groupID) {
    uint8_t i;

    if (groupID == GROUPMANAGER_INVALID_GROUP)
      return FALSE;

    for (i = 0; i < GROUPMANAGER_MAX_GROUPS; i++) {
      if (forwardGroups[i] == groupID) {
	forwardGroups[i] = GROUPMANAGER_INVALID_GROUP;
	forwardGroupTimeouts[i] = 0;
	dbg(DBG_USR1, "GroupManagerM: Stopped forwarding for group %d\n", groupID);
	return SUCCESS;
      }
    }
    
    return FAIL;
  }

  void setTimer() {
    uint16_t minTime = -1;
    uint8_t i;

    if (timerActive) {
      return;
    }

    timerActive = FALSE;

    for (i = 0; i < GROUPMANAGER_MAX_GROUPS; i++) {
      if (groups[i] != GROUPMANAGER_INVALID_GROUP) {
	if (groupTimeouts[i] < minTime) {
	  minTime = groupTimeouts[i];
	}
      }

      if (forwardGroups[i] != GROUPMANAGER_INVALID_GROUP) {
	if (forwardGroupTimeouts[i] < minTime) {
	  minTime = forwardGroupTimeouts[i];
	}
      }
    }

    if (minTime < -1) {

      for (i = 0; i < GROUPMANAGER_MAX_GROUPS; i++) {
	if (groups[i] != GROUPMANAGER_INVALID_GROUP) {
	  groupTimeouts[i] -= minTime;
	}
	
	if (forwardGroups[i] != GROUPMANAGER_INVALID_GROUP) {
	  forwardGroupTimeouts[i] -= minTime;
	}
      }
    
      timerActive = TRUE;
      call Timer.start(TIMER_ONE_SHOT, minTime * 1024);
      return;
    }
  }
  
  event result_t Timer.fired() {
    uint8_t i;

    for (i = 0; i < GROUPMANAGER_MAX_GROUPS; i++) {
      if (groupTimeouts[i] == 0)
	groups[i] = GROUPMANAGER_INVALID_GROUP;
      
      if (forwardGroupTimeouts[i] == 0)
	forwardGroups[i] = GROUPMANAGER_INVALID_GROUP;
    }

    timerActive = FALSE;
    setTimer();
    return SUCCESS;
  }
}
