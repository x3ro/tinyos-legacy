/*
 * Copyright (c) 2007, RWTH Aachen University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL RWTH AACHEN UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RWTH AACHEN
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * RWTH AACHEN UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND RWTH AACHEN UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */
 
 /**
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/
 
#ifndef _AM_TYPES_H
#define _AM_TYPES_H


enum {
	IEEE_802_15_4_TYPE = 222,
	CC1000_TYPE = 223,
};
typedef struct ScanLinkMsg {
  uint16_t parent;
  uint16_t linkid;
  uint8_t msg_type;
} ScanLinkMsg;

typedef struct GetInfoMsg {
  uint8_t type; // send or receive
  uint8_t attribute;
  uint8_t numFields;
  uint8_t fieldIdx;
  uint16_t qid;
  uint16_t linkid;
  uint16_t seq;
  uint16_t src_address;
  uint16_t dst_address;
  uint16_t data;
	uint8_t lqi;
	uint8_t rssi;
	uint8_t txPower;
	uint8_t state;
  //uint16_t data2[9];
} GetInfoMsg;

typedef struct ProbingMsg {
	uint8_t id;
	uint8_t lp_id;
	uint8_t type;
	uint8_t state;
	uint8_t lqi;
	uint8_t rssi;
	uint8_t txPower;
	
} ProbingMsg;

typedef struct FixedAttrMsg {
  uint16_t node_id;
	uint16_t source;
  uint8_t type;
	uint8_t rssi;
	uint8_t lqi;
	
} FixedAttrMsg;

// ScanLinkMsg->msg_type
enum {
  SCAN_FORWARD_MSG = 1,
  SCAN_REPLY_MSG = 2,
};

enum {
  SCAN_AVAILABLE_LINKS = 30,
  READ_AVAILABLE_LINKS = 31,
  AM_SCAN_LINKS      = 108,
  AM_GETINFO_MESSAGE = 109,
  AM_RESULT_GETINFO_MESSAGE = 110,
	AM_FIXEDATTR = 111,
};



#endif /* _AM_TYPES_H */
