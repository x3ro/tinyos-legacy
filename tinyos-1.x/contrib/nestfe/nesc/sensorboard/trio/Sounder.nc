//$Id: Sounder.nc,v 1.2 2005/07/06 17:25:04 cssharp Exp $
/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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

/**
 * Interface for Sounder. <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong
 */

interface Sounder {
  /**
   * Turns on/off a sounder
   *
   * @param high If TRUE, turns on the sounder.
   * If FALSE, turns off the sounder.
   * @return SUCCESS if the sounder is successfully turned on/off.
   */
  command result_t setStatus(bool high);
  /**
   * Initiates a read of the status of a sounder.
   * @return SUCCESS if the read is successfully requested.
   */
  command result_t getStatus();
  /**
   * Indicates the status of a sounder as a result of 
   * <code>getStatus()</code> command.
   *
   * @param high TRUE when the sounder is on, 
   * FALSE when the sounder is off.
   * @param result SUCCESS if the read is successfully done.
   */
  event void getStatusDone(bool high, result_t result);
}
