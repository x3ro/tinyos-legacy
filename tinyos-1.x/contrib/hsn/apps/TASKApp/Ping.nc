// $Id: Ping.nc,v 1.3 2004/12/31 20:08:22 yarvis Exp $

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
includes PingReplyMsg;
module Ping
{
  provides interface StdControl;
  uses {
    interface CommandRegister as PingCmd;
    interface AttrUse;
  }
}
implementation {
  char *rbuf;

  command result_t StdControl.init() {
    ParamList paramList;

    rbuf = NULL;
    paramList.numParams = 0;
    return call PingCmd.registerCommand("Ping", VOID, 0, &paramList);
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t PingCmd.commandFunc(char *commandName, char *resultBuf, SchemaErrorNo *errorNo, ParamVals *params) {
    SchemaErrorNo error;

    if (rbuf)
      return FAIL;
    rbuf = resultBuf;

    *errorNo = SCHEMA_RESULT_PENDING;
    call AttrUse.getAttrValue("parent", resultBuf, &error);
    call AttrUse.getAttrValue("freeram", resultBuf + sizeof(uint16_t), &error);
    call AttrUse.getAttrValue("voltage", resultBuf + 2 * sizeof(uint16_t), &error);
    call AttrUse.getAttrValue("qlen", resultBuf + 3 * sizeof(uint16_t), &error);
    call AttrUse.getAttrValue("mhqlen", resultBuf + 3 * sizeof(uint16_t) + sizeof(uint8_t), &error);
    call AttrUse.getAttrValue("depth", resultBuf + 3 * sizeof(uint16_t) + 2 * sizeof(uint8_t), &error);
    call AttrUse.getAttrValue("qual", resultBuf + 3 * sizeof(uint16_t) + 3 * sizeof(uint8_t), &error);
    call AttrUse.getAttrValue("qids", resultBuf + 3 * sizeof(uint16_t) + 4 * sizeof(uint8_t), &error);

    return SUCCESS;
  }

  event result_t AttrUse.getAttrDone(char *name, char *resultBuf, SchemaErrorNo errorNo) {
    if (resultBuf == rbuf + 2 * sizeof(uint16_t))
      {
	call PingCmd.commandDone("Ping", rbuf, SCHEMA_RESULT_READY);
	rbuf = NULL;
      }
    return SUCCESS;
  }

  event result_t AttrUse.startAttrDone(uint8_t id)
  {
  	return SUCCESS;
  }
}
