/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

#ifndef COUNTMSG_H
#define COUNTMSG_H

enum
{
  AM_COUNT_MSG = 4,
};

typedef struct
{
  nx_uint16_t n;
  nx_uint16_t src;
} CountMsg_t;

#endif
