/*									tab:4
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
 * AUTHOR: nks
 * DATE:   6/19/03
 */

#ifndef __EROUTE_H_
#define __EROUTE_H_

#include <AM.h>

// constants
enum {
  MAX_TREES = 2,
  MAX_MOBILE_AGENTS = 4,
  NO_ROUTE = 0xffff
};

// destinations
typedef enum  {
  TREE_LANDMARK = 0,
  TREE_BASESTATION = 1,
  MA_PURSUER1 = 2,
  MA_PURSUER2 = 3,
  MA_PURSUER3 = 4, 
  MA_PURSUER4 = 5,
  MA_VIZ      = 5,
  MA_ALL = 16
} __attribute__((packed)) EREndpoint;

// ---------------------- PRIVATE ---------------------------

// message types
typedef enum {
  TREE_BUILD = 1,
  CRUMB_BUILD = 2,
  MSG_TO_BASE = 3, 
  CRUMB_TO_BASE = 4,
  CRUMB_TO_MOBILE = 5
} __attribute__((packed)) ERType;

// message sizes.
enum {
  ER_HEADER_SIZE = (sizeof(ERType) + sizeof(EREndpoint)),
  ER_TREE_BUILD_SIZE = ER_HEADER_SIZE + sizeof(uint8_t) + sizeof(uint16_t),
  ER_CRUMB_BUILD_SIZE = (ER_HEADER_SIZE + sizeof (EREndpoint) +
                         2 * sizeof(uint16_t)),
  ER_BASE_HDR_SIZE = ER_HEADER_SIZE + sizeof (uint8_t),
  ER_LM_HDR_SIZE = ER_HEADER_SIZE + sizeof(EREndpoint) + sizeof(uint8_t),
  ER_LMM_HDR_SIZE = ER_HEADER_SIZE + sizeof(uint16_t) + sizeof(uint8_t)
};

// a tree build message: used to build the spanning tree.
typedef struct {
  uint8_t hopCount;
  uint16_t parent;
} __attribute__((packed)) ERTReeBuild;

// a message to lay the crumb trail. 
typedef struct {
  EREndpoint mobileAgent;
  uint16_t crumbNumber;
  uint16_t parent;
} __attribute__((packed)) ERCrumbBuild;

// message destined for the landmark (basestion).
typedef struct {
  uint8_t len;
  uint8_t data[TOSH_DATA_LENGTH - ER_BASE_HDR_SIZE];
} __attribute__((packed)) ERBase;

// message destined for a mobile agent but on the first leg towards the
// landmark (basestation) it'll use the spanning tree (namedin the msg struct)
// for route selection. 
typedef struct {
  EREndpoint destination;
  uint8_t len;
  uint8_t data[TOSH_DATA_LENGTH - ER_LM_HDR_SIZE];  
} __attribute__((packed)) ERLM;

// message destined for a mobile agent but on the secon leg (after it's gone
// through the basestation. this time it'll use the crumb trail (treeNumber)
// for routing). 
typedef struct {
  uint16_t crumbNumber;
  uint8_t len;
  uint8_t data[TOSH_DATA_LENGTH - ER_LMM_HDR_SIZE];
} __attribute__((packed)) ERLMMobile;

// the general message structure.
typedef struct {
  ERType type;
  // destination on this leg. 
  EREndpoint treeNumber;
  union {
    ERTReeBuild  treeBuild;
    ERCrumbBuild crumbBuild;
    ERBase       base;
    ERLM         lm;
    ERLMMobile   lmm;
  } __attribute__((packed)) u;
} __attribute__((packed)) ERMsg;

enum {
  // am handler for flooding and spanning tree creation.
  ERBCAST_AMHANDLER = 53,
  // am handler for point to point routing. 
  ROUTE_AMHANDLER = 54
};

#endif//__EROUTE_H_

