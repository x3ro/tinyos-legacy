// $Id: EEPROMWrite.nc,v 1.3 2003/10/07 21:46:14 idgay Exp $

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
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/3/03
 */

/**
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */


includes EEPROM;

/**
 * Write interface for the non-volatile EEPROM
 * <p>
 * Write lines to the EEPROM.
 * Each line is 16 bytes.
 * <p>
 * Writes must be surrounded by a <code>startWrite</code>, 
 * <code>endWrite</code> pair. Writes
 * are only final when <code>endWrite</code> is called. 
 * If <code>endWrite</code> is not called,
 * writes written since the last <code>startWrite</code> have 
 * undefined contents.
 */
interface EEPROMWrite {

  /**
   * Tells the EEPROM that we are going to start writing a line
   *
   * @return SUCCESS if the write is accepted
   */
  command result_t startWrite();

  /**
   * Writes the line to the EEPROM
   *
   * @param line address of the line to be written
   * @param buffer buffer of the bytes to be written
   *
   * @return SUCCESS if successful
   */
  command result_t write(uint16_t line, uint8_t *buffer);

  /**
   * Tells the EEPROM that we're done writing
   *
   * @return SUCCESS if the end command is accepted
   */
  command result_t endWrite();

  /**
   * Notification that the write has been completed
   *
   * @param buffer buffer written to the EEPROM
   *
   * @return SUCCESS always
   */
  event result_t writeDone(uint8_t *buffer);
  
  /**
   * Notification that the EEPROM has completed writing and ended
   * write mode
   *
   * @param success SUCCESS if the end command was successful
   *
   * @return SUCCESS always
   */
  event result_t endWriteDone(result_t success);
}
