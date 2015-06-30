// $Id: Field.h,v 1.1 2004/05/11 21:03:33 jdprabhu Exp $

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

#include "SchemaType.h"

struct WakeupMsg
{
  uint16_t sender;		/* Id of Ipaq's mote */
};

struct FieldMsg
{
  uint16_t sender;		/* Id of Ipaq's mote */
  uint16_t cmdId;		/* Unique sequence number */
  char cmd[0];			/* In the Command.invokeBuffer format */
};

struct FieldReplyMsg
{
  uint16_t sender;
  uint16_t cmdId;
  SchemaErrorNo errorNo;	/* errorNo and result from CommandUse.invoke */
  char result[0];
};

enum {
  /* A special cmdId for responses to wakeup messages */
  WAKEUP_CMDID = 0
};

enum { 
  AM_WAKEUPMSG = 120,
  AM_FIELDMSG = 121,
  AM_FIELDREPLYMSG = 122
};
