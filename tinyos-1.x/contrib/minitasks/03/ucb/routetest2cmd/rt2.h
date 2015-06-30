/*									
 *
 *
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
 * Author: Naveen Sastry, nks
 */

#ifndef RT_2_H
#define RT_2_H

#include <ERoute.h>

typedef enum {
  RT2MCD_TREE_ROOT = 1,
  RT2MCD_CRUMB_BUILD = 2,
  RT2MCD_ROUTE = 3,
  RT2CMD_CLEARLEDS = 4
} __attribute__((packed)) RT2CommandType;

// when routing a command, what do we want to do with it?
typedef enum {
  RT2A_LEDS = 1
} __attribute__((packed)) RT2ActionType;

struct RT2Action {
  RT2ActionType action;
  uint8_t value;
} __attribute__((packed));

typedef struct 
{
  RT2CommandType cmd;
  EREndpoint dest;
  struct RT2Action  action; // used for the route command
} __attribute__((packed)) RT2Command;

enum {
  RT_CMD_MSG_HANDLER = 50,
  RT_REBROADCAST_HANDLER = 51
};

typedef struct {
  uint16_t dest; 
  RT2Command cmd;
} __attribute__((packed)) RebroadcastCmd;

#endif
