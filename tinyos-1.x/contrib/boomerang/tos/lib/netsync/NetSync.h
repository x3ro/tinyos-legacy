/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
#ifndef NETSYNC_H
#define NETSYNC_H

typedef struct NetSyncMsg {
  uint16_t addr;         // 2
  uint32_t on;           // 4
  uint32_t off;          // 4
  uint32_t period;       // 4
  uint32_t local_time;   // 4
  uint32_t global_time;  // 4
  uint8_t hopcount;      // 1
  uint8_t seqno;         // 1 -- 24 bytes total
} syncmsg_t;

enum {
  AM_NETSYNCMSG = 21,
};
  
#ifndef NETSYNC_PERIOD_LOG2
#define NETSYNC_PERIOD_LOG2 16
#endif

#ifndef NETSYNC_DUTYCYCLE
#define NETSYNC_DUTYCYCLE 5
#endif

#define NETSYNC

#endif// NETSYNC_H

