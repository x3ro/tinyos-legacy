// $Id: MultiHopLayer.h,v 1.6 2004/09/21 03:57:53 gtolle Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * @author Gilman Tolle
 */


#ifndef _TOS_MULTIHOPLAYER_H
#define _TOS_MULTIHOPLAYER_H

#include "AM.h"

enum {
  AM_MULTIHOPLAYERMSG = 4,
  AM_MULTIHOPBEACONMSG = 5,
};

typedef struct MultihopLayerMsg {
  uint16_t sourceaddr;
  uint16_t originaddr;
  uint8_t ttl;
  uint8_t type;
  uint8_t data[0]; //(TOSH_DATA_LENGTH - 6)]; 
} MultihopLayerMsg;

typedef struct MultihopBeaconMsg {
  uint16_t parent;
  uint16_t sourceAddr;
  uint16_t cost;
  uint16_t treeID;
  uint32_t timestamp;
  uint16_t beaconPeriod;
  uint8_t  beaconSeqno;
} MultihopBeaconMsg;

typedef struct MultihopControlMsg {
  uint8_t maxRetransmitsChanged:1;

  uint8_t maxRetransmits;
} MultihopControlMsg;

#endif /* _TOS_COREMULTIHOP_H */


