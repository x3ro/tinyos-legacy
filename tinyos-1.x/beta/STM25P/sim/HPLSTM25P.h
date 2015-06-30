// $Id: HPLSTM25P.h,v 1.1 2005/06/27 17:55:09 jwhui Exp $

/*									tab:2
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * @author: Jonathan Hui <jwhui@cs.berkeley.edu>
*/

#ifndef __HPLSTM25P_H__
#define __HPLSTM25P_H__

enum {
  STM25P_FLASH_SIZE = 16L*65536L,
};

enum {
  STM25P_CMD_WREN = 0x06,
  STM25P_CMD_WRDI = 0x04,
  STM25P_CMD_RDSR = 0x05,
  STM25P_CMD_WRSR = 0x01,
  STM25P_CMD_READ = 0x03,
  STM25P_CMD_FAST_READ = 0x0b,
  STM25P_CMD_PP = 0x02,
  STM25P_CMD_SE = 0xd8,
  STM25P_CMD_BE = 0xc7,
  STM25P_CMD_DP = 0xb9,
  STM25P_CMD_RES = 0xab,
};

enum {
  WIP = 0,
  WEL = 1 << 1,
  BP = 1 << 2,
  SRWP = 1 << 7,
};

#endif

