// $Id: CountMsg.h,v 1.1.1.1 2007/11/05 19:08:58 jpolastre Exp $

/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/*
 * @author Cory Sharp <info@moteiv.com>
 */

#ifndef COUNTMSG_H
#define COUNTMSG_H

enum {
  AM_COUNTMSG = 4,
};

typedef struct CountMsg {
  nx_uint16_t n;
  nx_uint16_t src;
} CountMsg_t;

#endif
