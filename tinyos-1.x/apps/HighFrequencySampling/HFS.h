// $Id: HFS.h,v 1.3 2003/10/07 21:44:50 idgay Exp $

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
enum {
  HFS_EEPROM_ID = unique("ByteEEPROM"),
  AM_READREQUESTMSG = 52,
  AM_READDATAMSG = 53,
  AM_SAMPLEREQUESTMSG = 50,
  AM_SAMPLEDONEMSG = 51,
  MAX_SAMPLES = 65536UL
};

typedef uint16_t sample_t;	/* The type of samples */

// Outcomes from sampling (report in SampleDoneMsg)
enum {
  SAMPLE_SUCCESS,
  SAMPLE_NOTREADY,
  SAMPLE_FAILED
};

// Kinds of messages for the data read "protocol" (see ReadDataMsg)
enum {
  DATAMSG_LAST, // last data message
  DATAMSG_MORE, // at least 1 message follows
  DATAMSG_FAIL  // some problem encountered (expect no more messages)
};

// Message formats

// Request sampling
struct SampleRequestMsg {
  uint32_t sampleInterval; // in microseconds
  uint32_t sampleCount;
};

struct SampleDoneMsg {
  uint8_t outcome; // See SAMPLE_xxx constants
  uint32_t bytesUsed;
};

// Read n samples (argument is needed as mote may have been reset)
struct ReadRequestMsg {
  uint32_t count;
};

// A message with samples. The sample count can be deduced from the message
// length
struct ReadDataMsg {
  uint8_t status; // See DATAMSG_xxx
  uint16_t samples[0];
};
