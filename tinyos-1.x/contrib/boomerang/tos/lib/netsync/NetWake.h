/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
#ifndef NETWAKE_H
#define NETWAKE_H

typedef struct NetWakeMsg {
  uint16_t addr;
  uint16_t seqno;
  uint32_t timeon;
  uint32_t timeoff;
} netwakemsg_t;

enum {
  AM_NETWAKEMSG = 22,
  NETWAKE_MIN_INTERVAL = 1024,
};

#define NETWAKE_MAX_INIT 0x1E0000L // 60 seconds

#endif
