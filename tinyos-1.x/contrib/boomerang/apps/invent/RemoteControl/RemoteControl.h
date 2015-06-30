/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

#ifndef REMOTECONTROL_H
#define REMOTECONTROL_H

enum {
  AM_REMOTECONTROLMSG = 50
};

typedef struct RemoteControlMsg {
  uint16_t addr;
  uint8_t count;
} remote_msg_t;

#endif
