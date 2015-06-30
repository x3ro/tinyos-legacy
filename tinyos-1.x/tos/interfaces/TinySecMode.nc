// $Id: TinySecMode.nc,v 1.2 2003/10/28 05:42:20 ckarlof Exp $

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

/* Authors: Chris Karlof
 * Date:    10/27/02
 */

/**
 * @author Chris Karlof
 */

interface TinySecMode
{
  /**
   * Sets the transmit mode for TinySec. 
   *
   * @param mode should be one of TINYSEC_AUTH_ONLY, TINYSEC_ENCRYPT_AND_AUTH,
   *        or TINYSEC_DISABLED
   * @return SUCCESS if the mode parameter is valid, FAIL otherwise.
   */
  command result_t setTransmitMode(uint8_t mode);

  /**
   * Sets the receive mode for TinySec. 
   *
   * @param mode should be one of TINYSEC_RECEIVE_AUTHENTICATED,
   *        TINYSEC_RECEIVE_CRC, or TINYSEC_RECEIVE_ANY
   * @return SUCCESS if the mode parameter is valid, FAIL otherwise.
   */
  command result_t setReceiveMode(uint8_t mode);

  /**
   * Gets the current transmit mode for TinySec. 
   *
   * @return The current transmit mode.
   */
  command uint8_t getTransmitMode();

  /**
   * Gets the current receive mode for TinySec. 
   *
   * @return The current receive mode.
   */
  command uint8_t getReceiveMode();
  
}
