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


// define AM msg type
enum {
  AM_DIAGMSG=90 ,
  AM_DIAGRSPMSG= 91
};
// define misc constants
enum{
  DIAG_MSG_LEN=12,
  DIAG_RESP_LEN=26,
  DIAG_PATTERN_REPEATS=10
};
enum {
  PACKET_LOSS=0
};

// AM_DIAGMSG format
struct DiagMsg {
	uint16_t source_mote_id;
	int16_t sequence_num;  
	uint8_t action; // what kind of diagnostics to do?
	uint8_t  reserve;  // reserved for possible argument related diff. diag. action 
	int16_t pattern;
	int16_t num_of_msg_to_send;
	int16_t interval;
};

struct DiagRspMsg {
	uint16_t source_mote_id;/* this mote ID */
	uint16_t sequence_num; 
    uint16_t param;	// for action 0 this is the total responses
	int16_t data[DIAG_PATTERN_REPEATS];
};
