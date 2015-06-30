/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
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
  enum { IDENT_LINE = 4 };

  uint8_t eepromLine[TOS_EEPROM_LINE_SIZE];
  bool eepromLineInUse;
  bool saveIdPending;

  void saveId() {
    if (eepromLineInUse)
      {
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

  void clearIdentity() {
    eepromLine[0] = FALSE;
    call Ident.clearId();
    call Leds.redOn();
    call Leds.greenOff();
  }

  void setIdentity(char *newid) {
    eepromLine[0] = TRUE;
    memcpy(eepromLine + 1, newid, IDENTITY_LEN);
    call Ident.setId((identity_t *)newid);
    call Leds.redOff();
    call Leds.greenOn();
  }

  void readId() {
    /* At init only, so we get to steal the eeprom line */
    eepromLineInUse = TRUE;
    if (!call EEPROMRead.read(IDENT_LINE, eepromLine))
      eepromLineInUse = FALSE;
  }

  event result_t EEPROMRead.readDone(uint8_t *buffer, result_t success) {
    if (success && buffer == eepromLine)
      {
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
    call SubControl.init();

    saveIdPending = FALSE;
    eepromLineInUse = FALSE;

    readId();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return call SubControl.start();
  }

  command result_t StdControl.stop() {
    return call SubControl.stop();
  }

  event TOS_MsgPtr ClearIdMsg.receive(TOS_MsgPtr m) {
    clearIdentity();
    saveId();
    return m;
  }

  event TOS_MsgPtr SetIdMsg.receive(TOS_MsgPtr m) {
    if (!call Ident.haveIdentity())
      {
	setIdentity(m->data);
	saveId();
      }
    return m;
  }
}
