// $Id: DataCollector.h,v 1.1 2006/12/01 00:09:07 binetude Exp $

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
 *
 * Authors:		Sukun Kim
 * Date last modified:  11/30/06
 *
 */

/**
 * @author Sukun Kim
 */

#include "AM.h"
#include "CmdMsg.h"
#include "ReplyMsg.h"
enum {
  IDLE_STATE = 0,
};
enum {
  PROFILE_EEPROM_ID = unique("ByteEEPROM"),
  DATA_EEPROM_ID = unique("ByteEEPROM"),

  STRAW_DATA_ID = 11,

  MAX_EEPROM_USAGE = 524000UL,//20000,//65536UL,524000UL,524288UL,
  MAX_CHANNEL = 6,
};

typedef struct {
  uint16_t seqNo;
  uint32_t nSamples;
  uint32_t intrv;
  uint8_t chnlSelect;
  uint16_t samplesToAvg;
  uint32_t startTime;
  uint8_t integrity;
  uint8_t lenOfNm;
  uint8_t nm[MAX_START_SENSING_NAME];
} __attribute__ ((packed)) dataPrfl;

