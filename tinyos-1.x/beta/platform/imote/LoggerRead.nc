// $Id: LoggerRead.nc,v 1.1 2005/09/06 08:27:59 lnachman Exp $

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
 * Authors:		Matt Welsh 
 * Date last modified:  8/27/02
 *
 *
 */

/**
 * @author Matt Welsh 
 */


//includes EEPROM;

/**
 * Interface to read a line at a time from the EEPROM, maintaining
 * an internal "current line" pointer.
 */
interface LoggerRead {

  /**
   * Read the next line from the log, wrapping around to the beginning
   * of the log.
   * @param buffer The buffer to read data into.
   * @return FAIL if the component is busy, SUCCESS otherwise.
   */
  command result_t readNext(uint8_t *buffer);

  /**
   * Equivalent to calling setPointer(line) followed by read(buffer).
   * @param line The line to read from
   * @param buffer The buffer to read data into.
   * @return FAIL if the component is busy or the line is invalid, 
   *   SUCCESS otherwise.
   */
  command result_t read(uint16_t line, uint8_t *buffer);

  /**
   * Reset the current read pointer to the beginning of the log.
   * @return Always return SUCCESS.
   */
  command result_t resetPointer();

  /**
   * Set the current read pointer to the given value.
   * Not all pointer values are valid.
   * @param line The line to set the pointer to.
   * @return FAIL if the line is invalid, SUCCESS otherwise.
   */
  command result_t setPointer(uint16_t line);

  /**
   * Signaled when a read completes. 
   * @param buffer The buffer containing the read data.
   * @param success Whether the read was successful. If FAIL, the
   *   buffer data is invalid.
   */
  event result_t readDone(uint8_t *buffer, result_t success);

}

