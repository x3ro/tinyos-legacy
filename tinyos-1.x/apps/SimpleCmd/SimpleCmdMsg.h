// $Id: SimpleCmdMsg.h,v 1.2 2003/10/07 21:45:09 idgay Exp $

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

/* 
 * File Name: SimpleCmd.h
 *
 * Description:
 * This header file defines the AM_SIMPLECMDMSG and AM_LOGMSG message
 * types for the SimpleCmd and SenseLightToLog applications.
 */

enum {
 AM_SIMPLECMDMSG = 8,
 AM_LOGMSG=9
};

enum {
  LED_ON = 1,
  LED_OFF = 2,
  RADIO_LOUDER  = 3,
  RADIO_QUIETER = 4,
  START_SENSING = 5,
  READ_LOG = 6
};

typedef struct {
    int nsamples;
    uint32_t interval;
} start_sense_args;

typedef struct {
    uint16_t destaddr;
} read_log_args;

// SimpleCmd message structure
typedef struct SimpleCmdMsg {
    int8_t seqno;
    int8_t action;
    uint16_t source;
    uint8_t hop_count;
    union {
      start_sense_args ss_args;
      read_log_args rl_args;
      uint8_t untyped_args[0];
    } args;
} SimpleCmdMsg;

// Log message structure
typedef struct LogMsg {
    uint16_t sourceaddr; 
    uint8_t log[16];
} LogMsg;

