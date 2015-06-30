/*
 * Copyright (c) 2002-2004 the University of Southern California
 * Copyright (c) 2004 TU Delft/TNO
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement 
 * is hereby granted, provided that the above copyright notice and the
 * following two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * COPYRIGHT HOLDERS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE COPYRIGHT HOLDERS SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER
 * IS ON AN "AS IS" BASIS, AND THE COPYRIGHT HOLDERS HAVE NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Authors:	Wei Ye (S-MAC version), Tom Parker (T-MAC modifications)
 * This file defines the packet format for TMACWrapper
 */

/**
 * @author Wei Ye
 * @author Tom Parker
 */

#ifndef TMAC_WRAPPER_MSG
#define TMAC_WRAPPER_MSG

// include TOS_Msg defination
#include "AM.h"

// define PHY_MAX_PKT_LEN before include TMACMsg.h. Otherwise default 
// value (100) will be used when TMACMsg.h includes PhyRadioMsg.h.
#define MAC_HEADER_LEN 9
#define PHY_MAX_PKT_LEN (MAC_HEADER_LEN + sizeof(TOS_Msg) + 2)

// include T-MAC header defination
#include "TMACMsg.h"

typedef MACHeader WrapHeader;

// msg to be sent on radio
typedef struct {
   WrapHeader wrapHdr;
   TOS_Msg tosMsg;
   //int16_t crc;
} __attribute__ ((packed)) WrapMsg;

#endif
