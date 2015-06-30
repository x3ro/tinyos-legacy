// $Id: Drain.h,v 1.1 2005/10/27 21:31:04 gtolle Exp $

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


#ifndef __DRAIN_H__
#define __DRAIN_H__

enum drainMsgs {
  AM_DRAINMSG = 4,
  AM_DRAINBEACONMSG = 7,
  AM_DRAINGROUPREGISTERMSG = 89,
};

enum drainConsts {
  DRAIN_SEND_QUEUE_SIZE = 3, 
  DRAIN_FWD_QUEUE_SIZE = 12,
  DRAIN_MAX_RETRANSMITS = 0, // does nothing, for now.
  DRAIN_MAX_MISSED_BEACONS = 5,
  DRAIN_MAX_BACKOFF = 12,
  DRAIN_UNKNOWN_ACK_EST = 127,
  DRAIN_MAX_ROUTES = 2,
  DRAIN_MAX_TTL = 16,
  DRAIN_INVALID_DEST = 0,
  DRAIN_INVALID_SLOT = 0xFF,
  DRAIN_MAX_CHILDREN = 8,
  DRAIN_QUEUE_SEND = 1,
  DRAIN_QUEUE_FWD = 2,
};

enum drainAddresses {
  DRAIN_GROUP_ALL = 0xFEFFU,
  DRAIN_GROUP_MULTICAST = 0xFEFEU,
  TOS_DEFAULT_ADDR = 0,
};

typedef struct DrainMsg {
  uint8_t type;
  uint8_t ttl;
  uint8_t seqNo;
  uint16_t source;
  uint16_t dest;
  uint8_t data[0];
} DrainMsg;

typedef struct DrainBeaconMsg {
  uint16_t linkSource;

  uint16_t source;
  uint16_t parent;
  uint16_t cost;
  uint8_t  ttl;

  uint8_t  beaconSeqno;
  uint8_t  beaconDelay;
  uint8_t  treeInstance;
  uint16_t beaconOffset;
  
  bool     defaultRoute;
} DrainBeaconMsg;

typedef struct DrainGroupRegisterMsg {
  uint16_t group;
  uint16_t timeout;
} DrainGroupRegisterMsg;

typedef struct DrainRouteEntry {
  uint16_t dest;

  uint16_t nextHop;
  uint16_t nextHopCost;
  uint16_t nextHopLinkEst;

  uint8_t  destDistance;
  uint8_t  treeInstance;
  
  uint8_t  announceSeqno;
  uint8_t  announceDelay;
  uint16_t announceOffset;
  uint16_t announceCountdown;
  bool     sendWaiting:1;
  bool     defaultRoute:1;
  bool     pad:6;
  
  uint16_t  sentPackets;
  uint16_t  successPackets;
  uint16_t  successRate;
  uint8_t   parentSwitches;

} DrainRouteEntry;

#endif


