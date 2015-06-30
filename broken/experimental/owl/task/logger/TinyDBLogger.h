// $Id: TinyDBLogger.h,v 1.3 2004/05/27 19:12:04 idgay Exp $

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
 * Copyright (c) 2002-2004 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
enum {
  TINYDB_EEPROM_ID = unique("ByteEEPROM"),
  AM_LREADREQUESTMSG = 52,
  AM_LREADDATAMSG = 53,
};

// Kinds of messages for the data read "protocol" (see ReadDataMsg)
enum {
  DATAMSG_SIZE, // first message, with size
  DATAMSG_LAST, // last data message
  DATAMSG_MORE, // at least 1 message follows
  DATAMSG_FAIL  // some problem encountered (expect no more messages)
};

// Message formats

// Read data 
struct LReadRequestMsg {
  uint32_t start, count;
};

// A message with some amount of data.
struct LReadDataMsg {
  uint8_t status; // See DATAMSG_xxx
  uint32_t offset; // size for DATAMSG_SIZE
  int8_t data[];
};

struct OffsetReplyMsg {
  uint32_t count;
};
