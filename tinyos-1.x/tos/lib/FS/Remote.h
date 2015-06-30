// $Id: Remote.h,v 1.2 2003/10/07 21:46:18 idgay Exp $

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
  FSOP_DIR_START,
  FSOP_DIR_READNEXT,
  FSOP_DIR_END,
  FSOP_DELETE,
  FSOP_RENAME,
  FSOP_READ_OPEN,
  FSOP_READ,
  FSOP_READ_CLOSE,
  FSOP_READ_REMAINING,
  FSOP_WRITE_OPEN,
  FSOP_WRITE,
  FSOP_WRITE_CLOSE,
  FSOP_WRITE_SYNC,
  FSOP_WRITE_RESERVE,
  FSOP_FREE_SPACE
};

enum {
  FS_ERROR_REMOTE_UNKNOWNCMD = 0x80,
  FS_ERROR_REMOTE_BAD_ARGS,
  FS_ERROR_REMOTE_CMDFAIL
};

struct FSOpMsg
{
  uint8_t op;
  uint8_t data[];
};

struct FSReplyMsg
{
  uint8_t op;
  fileresult_t result;
  uint8_t data[];
};

enum {
  AM_FSOPMSG = 0x42,
  AM_FSREPLYMSG = 0x54,
  MAX_REMOTE_DATA = DATA_LENGTH - offsetof(struct FSReplyMsg, data)
};
