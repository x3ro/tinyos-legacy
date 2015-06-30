/* "Copyright (c) 2000-2002 University of Virginia.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF VIRGINIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * VIRGINIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF VIRGINIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF VIRGINIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 * 
 * Authors: Brain Blum,Tian He 
 */

#ifndef __TRACKING_H__
#define __TRACKING_H__

#include "SystemParameters.h"

typedef struct {
  uint16_t eventID[MAX_EVENTS];
  uint16_t remoteGroup[MAX_EVENTS];
  uint16_t remotePort[MAX_EVENTS];
  uint16_t localGroup[MAX_EVENTS];
  uint16_t localPort[MAX_EVENTS];
  char sensing[MAX_EVENTS];
  uint16_t size;
} TrackingTable;

enum {	
  TRACKING_INFO_MSG =1,
  NODE_STATUS_MSG = 2,
//0406B
  ROUTING_INITAL_DELAY_IN_SECONDS = 5,
  TRACKING_INITAL_DELAY_IN_SECONDS = 5,
//0406E
};
  
typedef struct {
  uint16_t group;
  uint16_t port;
} Endpoint;

/* only the first two data structures are being properly sent
   I might want to just send local group and node_id to simplify */
typedef struct {
  uint16_t lGroup;
  uint16_t x;
  uint16_t y;
  uint16_t eventRec;
  uint16_t leaderID;
  uint16_t currentDataSeqNo;
  uint8_t confidenceLevel;
} TrackingRecord; /* Report to the Base Station */

typedef struct {
  uint16_t leader;
  uint16_t sourceID;  
  uint16_t data;
  uint16_t x;
  uint16_t y;
  uint16_t z;
} DataUpdate; /* Report to the leader */

#endif
