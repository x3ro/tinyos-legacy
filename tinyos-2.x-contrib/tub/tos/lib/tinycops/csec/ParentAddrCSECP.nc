/* 
 * Copyright (c) 2007, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $
 * $Date: 2008/02/15 13:59:01 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
#include "PS.h"
#include "Attributes.h"
module ParentAddrCSECP {
  uses {
     interface NotificationFilter<CSEC_OUTBOUND> as NotificationFilterOut;
     interface NotificationFilter<CSEC_INBOUND> as NotificationFilterIn;
     interface PSMessageAccess;
     interface Leds;
  }
} implementation {
  enum {
    NO_PARENT = 0xFFFF,
  };

  // signalled once on the origin (publisher) node
  event bool NotificationFilterOut.forward(notification_handle_t nHandle, subscription_handle_t sHandle, bool isIntercept)
  {
    avpair_t *avpair;
    avpair = call PSMessageAccess.allocateAttribute(nHandle, 2);
    if (avpair){
      avpair->attributeID = ATTRIBUTE_PARENT_ADDR;
      *((nx_uint16_t*) avpair->value) = NO_PARENT;
    }
    return TRUE;
  }

  // signalled on intermediate hops and destination (subscriber)
  event bool NotificationFilterIn.forward(notification_handle_t nHandle, subscription_handle_t sHandle, bool isIntercept)
  {
    uint8_t valueSize;
    avpair_t *avpair;
    avpair = call PSMessageAccess.getAttributeViaId(nHandle, ATTRIBUTE_PARENT_ADDR, &valueSize);
    if (avpair)
      if (*((nx_uint16_t*) avpair->value) == NO_PARENT)
        *((nx_uint16_t*) avpair->value) = TOS_NODE_ID;
    return TRUE;
  }
}
