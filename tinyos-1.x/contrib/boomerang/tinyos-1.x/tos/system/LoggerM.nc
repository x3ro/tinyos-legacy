// $Id: LoggerM.nc,v 1.1.1.1 2007/11/05 19:10:42 jpolastre Exp $

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
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 */

/**
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */


includes EEPROM;

module LoggerM
{
  provides {
    interface StdControl;
    interface LoggerWrite;
    interface LoggerRead;
  }
  uses {
    interface StdControl as EEPROMControl;
    interface EEPROMWrite;
    interface EEPROMRead;
  }
}
implementation
{
  uint16_t curWriteLine, curReadLine;
  result_t write_result;

  command result_t StdControl.init() {
    curWriteLine = EEPROM_LOGGER_APPEND_START;
    curReadLine = EEPROM_LOGGER_APPEND_START;
    return call EEPROMControl.init();
  }

  command result_t StdControl.start() {
    return call EEPROMControl.start();
  }

  command result_t StdControl.stop() {
    return call EEPROMControl.stop();
  }

  /* LoggerWrite commands ***********************************************/
  
  command result_t LoggerWrite.append(uint8_t *data) {

    if (call EEPROMWrite.startWrite() == FAIL) return FAIL;
    write_result = SUCCESS;
    if (call EEPROMWrite.write(curWriteLine, data) == FAIL) {
      write_result = FAIL;
      call EEPROMWrite.endWrite();
    }

    return SUCCESS;
  }

  command result_t LoggerWrite.write(uint16_t line, uint8_t *data) {
    if (call LoggerWrite.setPointer(line) == FAIL) return FAIL;
    return call LoggerWrite.append(data);
  }

  command result_t LoggerWrite.resetPointer() {
    curWriteLine = EEPROM_LOGGER_APPEND_START;
    return SUCCESS;
  }

  command result_t LoggerWrite.setPointer(uint16_t line) {
    if (line < EEPROM_LOGGER_APPEND_START ||
	line >= EEPROM_LOGGER_APPEND_END) {
      return FAIL;
    }
    curWriteLine = line;
    return SUCCESS;
  }

  event result_t EEPROMWrite.writeDone(uint8_t *buffer) {
    write_result = call EEPROMWrite.endWrite();
    return SUCCESS;
  }

  event result_t EEPROMWrite.endWriteDone(result_t success) {
    if (success == SUCCESS) {
      curWriteLine++;
      if (curWriteLine == EEPROM_LOGGER_APPEND_END)
       	curWriteLine = EEPROM_LOGGER_APPEND_START;
    }
    return signal LoggerWrite.writeDone(rcombine(write_result, success));
  }

  /* LoggerRead commands ***********************************************/

  command result_t LoggerRead.readNext(uint8_t *buffer) {
    return call EEPROMRead.read(curReadLine, buffer);
  }

  command result_t LoggerRead.read(uint16_t line, uint8_t *buffer) {
    if (call LoggerRead.setPointer(line) == FAIL) return FAIL;
    return call LoggerRead.readNext(buffer);
  }

  command result_t LoggerRead.resetPointer() {
    curReadLine = EEPROM_LOGGER_APPEND_START;
    return SUCCESS;
  }

  command result_t LoggerRead.setPointer(uint16_t line) {
    if (line < EEPROM_LOGGER_APPEND_START ||
	line >= EEPROM_LOGGER_APPEND_END) {
      return FAIL;
    }
    curReadLine = line;
    return SUCCESS;
  }

  event result_t EEPROMRead.readDone(uint8_t *buffer, result_t success) {
    if (success == SUCCESS) {
      curReadLine++;
      if (curReadLine == EEPROM_LOGGER_APPEND_END) {
	curReadLine = EEPROM_LOGGER_APPEND_START;
      }
    }
    return signal LoggerRead.readDone(buffer, success);
  }


}
