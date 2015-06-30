// $Id: EEPROMRead.nc,v 1.2 2003/10/07 21:46:14 idgay Exp $

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
 * Date last modified:  6/25/02
 */

/**
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */


includes EEPROM;

/**
 * Read interface for the non-volatile storage EEPROM
 */
interface EEPROMRead {

  /** 
   * Read a line from the EEPROM.  Each line is 16 bytes.
   * Effects: try to read line <code>line</code> from the eeprom into buffer
   *
   * @param line the address of the line to be read
   * @param buffer an allocated buffer to read the line into
   *
   * @return FAIL if the component is busy or the line is invalid,
   *         SUCCESS otherwise.  If SUCCESS, will signal 
   *         <code>readDone()</code> when read completes.
   */
  command result_t read(uint16_t line, uint8_t *buffer);

  /**
   * Notification that the read has been completed.
   * 
   * @param buffer buffer the line has been read into
   * @param success SUCCESS if the read was successful
   *
   * @return SUCCESS always
   */ 
  event result_t readDone(uint8_t *buffer, result_t success);

}
