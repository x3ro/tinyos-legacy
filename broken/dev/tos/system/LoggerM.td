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
 *
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
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
  uint16_t cur_write_line, cur_read_line;
  result_t write_result;

  command result_t StdControl.init() {
    cur_write_line = EEPROM_LOGGER_APPEND_START;
    cur_read_line = EEPROM_LOGGER_APPEND_START;
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
    if (call EEPROMWrite.write(cur_write_line, data) == FAIL) {
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
    cur_write_line = EEPROM_LOGGER_APPEND_START;
    return SUCCESS;
  }

  command result_t LoggerWrite.setPointer(uint16_t line) {
    if (line < EEPROM_LOGGER_APPEND_START ||
	line >= EEPROM_LOGGER_APPEND_END) {
      return FAIL;
    }
    cur_write_line = line;
    return SUCCESS;
  }

  event result_t EEPROMWrite.writeDone(uint8_t *buffer) {
    write_result = call EEPROMWrite.endWrite();
    return SUCCESS;
  }

  event result_t EEPROMWrite.endWriteDone(result_t success) {
    if (success == SUCCESS) {
      cur_write_line++;
      if (cur_write_line == EEPROM_LOGGER_APPEND_END)
       	cur_write_line = EEPROM_LOGGER_APPEND_START;
    }
    return signal LoggerWrite.writeDone(rcombine(write_result, success));
  }

  /* LoggerRead commands ***********************************************/

  command result_t LoggerRead.readNext(uint8_t *buffer) {
    return call EEPROMRead.read(cur_read_line, buffer);
  }

  command result_t LoggerRead.read(uint16_t line, uint8_t *buffer) {
    if (call LoggerRead.setPointer(line) == FAIL) return FAIL;
    return call LoggerRead.readNext(buffer);
  }

  command result_t LoggerRead.resetPointer() {
    cur_read_line = EEPROM_LOGGER_APPEND_START;
    return SUCCESS;
  }

  command result_t LoggerRead.setPointer(uint16_t line) {
    if (line < EEPROM_LOGGER_APPEND_START ||
	line >= EEPROM_LOGGER_APPEND_END) {
      return FAIL;
    }
    cur_read_line = line;
    return SUCCESS;
  }

  event result_t EEPROMRead.readDone(uint8_t *buffer, result_t success) {
    if (success == SUCCESS) {
      cur_read_line++;
      if (cur_read_line == EEPROM_LOGGER_APPEND_END) {
	cur_read_line = EEPROM_LOGGER_APPEND_START;
      }
    }
    return signal LoggerRead.readDone(buffer, success);
  }


}
