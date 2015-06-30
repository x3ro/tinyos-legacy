// ex: set tabstop=2 shiftwidth=2 expandtab syn=c:
// $Id: ReverseLinkInfo.h,v 1.1.1.1 2005/06/19 04:34:38 rfonseca76 Exp $
                                    
/*                                                                      
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
                                    
/*                                  
 * Authors:  Rodrigo Fonseca        
 * Date Last Modified: 2005/05/26
 */
#ifndef REV_LINK_H
#define REV_LINK_H

#include "LinkEstimator.h" 

enum {
  NUM_REVERSE_LINK_ENTRIES = 7,
  REVERSE_LINK_INVALID_ADDR = 65535u,
};

typedef struct {
  uint16_t addr;
  uint8_t quality;
} __attribute__((packed)) ReverseLinkEntry;

typedef struct {
  uint8_t num_elements;
  uint8_t total_links;
  ReverseLinkEntry entries[NUM_REVERSE_LINK_ENTRIES];
} ReverseLinkInfo;

typedef struct LE_Reverse_Link_Estimation_Msg {
  LEHeader header;
  ReverseLinkInfo info;
} __attribute__((packed)) ReverseLinkMsg;

inline result_t reverseLinkInfoInit(ReverseLinkInfo* this) {
  int i;
  if (this == NULL)
    return FAIL; 
  this->num_elements = 0;
  for (i = 0; i < NUM_REVERSE_LINK_ENTRIES; i++) {
    this->entries[i].addr = REVERSE_LINK_INVALID_ADDR;
    this->entries[i].quality = 0;
  }
  return SUCCESS;
}

inline result_t reverseLinkInfoGetQuality(ReverseLinkInfo* this, uint16_t addr, uint8_t *quality) {
  int i;
  bool found = FALSE;
  if (this == NULL)
    return FAIL;
  for (i = 0; i < this->num_elements && !found; i++) {
    found = (this->entries[i].addr == addr); 
    if (found) {
      *quality = this->entries[i].quality;
    }
  }
  return (found)?SUCCESS:FAIL;
}

inline result_t reverseLinkInfoReset(ReverseLinkInfo* this) {
  int i;
  if (this == NULL)
    return FAIL;
  for (i = 1; i < this->num_elements; i++)  {
    this->entries[i].addr = REVERSE_LINK_INVALID_ADDR; 
    this->entries[i].quality = 0;
  }
  this->num_elements = 0;
  return SUCCESS;
}

/* Appends an entry to this ReverseLinkInfo structure, unless it is full, in which case
 * it returns false. It is up to the caller to save state in order to, for example,
 * add elements in a round robin fashion across messages.
 * @return FAIL is not able to append
 */
inline result_t reverseLinkInfoAppend(ReverseLinkInfo* this, uint16_t addr, uint8_t quality) {
  if (this == NULL)
    return FAIL;
  if (this->num_elements >= NUM_REVERSE_LINK_ENTRIES)
    return FAIL;
  this->entries[this->num_elements].addr = addr;
  this->entries[this->num_elements].quality = quality;
  this->num_elements++;
  return SUCCESS;
}

inline result_t reverseLinkInfoFromMsg(ReverseLinkInfo* this, ReverseLinkMsg* msg) {
  *this = msg->info;
  if (this->num_elements > NUM_REVERSE_LINK_ENTRIES) {
    this->num_elements = NUM_REVERSE_LINK_ENTRIES;
  }
  return SUCCESS;
}

inline result_t reverseLinkInfoToMsg(ReverseLinkInfo* this, ReverseLinkMsg* msg) {
  if (this == NULL || msg == NULL)
    return FAIL;
  msg->info = *this;
  return SUCCESS;
}
#endif
