// $Id: AppM.nc,v 1.6 2003/10/07 21:44:51 idgay Exp $

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
 * ident.c - simple people identifier application
 *	     each mote has a (programmable) ID which it broadcasts
 *	     continuously
 *
 * Authors: David Gay
 * History: created 12/6/01
 *          adaptive rate extension 12/14/01
 */
/**
 * C code for the person tracker (respond to identity control messages from
 * PC and read/write identity from/to EEPROM) * @author David Gay
 */
includes EEPROM;
includes Identity;

module AppM
{
  provides interface StdControl;

  uses {
    interface StdControl as SubControl;
    interface Leds;
    interface Ident;
    interface ReceiveMsg as ClearIdMsg;
    interface ReceiveMsg as SetIdMsg;
    interface LoggerWrite as EEPROMWrite;
    interface LoggerRead as EEPROMRead;
  }
}
implementation
{
  /* line of eeprom that holds identity.
     First byte is 0 for no identity, non-zero for identity set.
     Remaining 15 bytes are the null-terminated identity string */
  enum { IDENT_LINE = EEPROM_LOGGER_APPEND_START };

  uint8_t eepromLine[TOS_EEPROM_LINE_SIZE];
  bool eepromLineInUse;
  bool saveIdPending;

  /* Save id to eeprom if not currently saving id */
  void saveId() {
    if (eepromLineInUse)
      {
	/* save again when current write completes */
	saveIdPending = TRUE;
	return;
      }

    saveIdPending = FALSE;
    eepromLineInUse = TRUE;
    if (!call EEPROMWrite.write(IDENT_LINE, eepromLine))
      eepromLineInUse = FALSE;
  }

  void checkForSaveId() {
    if (saveIdPending)
      saveId();
  }

  event result_t EEPROMWrite.writeDone(result_t success) {
    eepromLineInUse = FALSE;
    checkForSaveId();
    return SUCCESS;
  }

  /* No identity. */
  void clearIdentity() {
    eepromLine[0] = FALSE;
    call Ident.clearId();
    call Leds.redOn();
    call Leds.greenOff();
  }

  /* An identity. */
  void setIdentity(char *newid) {
    eepromLine[0] = TRUE;
    memcpy(eepromLine + 1, newid, IDENTITY_LEN);
    call Ident.setId((identity_t *)newid);
    call Leds.redOff();
    call Leds.greenOn();
  }

  /* Read identity from EEPROM */
  void readId() {
    /* At init only, so we get to steal the eeprom line */
    eepromLineInUse = TRUE;
    if (!call EEPROMRead.read(IDENT_LINE, eepromLine))
      eepromLineInUse = FALSE;
  }

  event result_t EEPROMRead.readDone(uint8_t *buffer, result_t success) {
    if (success && buffer == eepromLine)
      {
	/* Set our id from EEPROM contents */
	if (buffer[0])
	  setIdentity(buffer + 1);
	else
	  clearIdentity();
      }
    saveIdPending = FALSE; /* We kill any id we received during startup */
    eepromLineInUse = FALSE;
  
    return SUCCESS;
  }

  command result_t StdControl.init() {
    call Leds.init();
    call SubControl.init();

    saveIdPending = FALSE;
    eepromLineInUse = FALSE;

    readId();
    dbg(DBG_BOOT, "Ident initialized.\n");
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return call SubControl.start();
  }

  command result_t StdControl.stop() {
    return call SubControl.stop();
  }

  /* Clear id request from PC */
  event TOS_MsgPtr ClearIdMsg.receive(TOS_MsgPtr m) {
    clearIdentity();
    saveId();
    return m;
  }

  /* Set id request from PC */
  event TOS_MsgPtr SetIdMsg.receive(TOS_MsgPtr m) {
    if (!call Ident.haveIdentity())
      {
	setIdentity(m->data);
	saveId();
      }
    return m;
  }
}
