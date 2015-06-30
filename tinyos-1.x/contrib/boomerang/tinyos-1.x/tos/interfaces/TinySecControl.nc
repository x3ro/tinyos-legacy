// $Id: TinySecControl.nc,v 1.1.1.1 2007/11/05 19:09:04 jpolastre Exp $

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
 * Date:    9/26/02
 */

/**
 * @author Chris Karlof
 */


interface TinySecControl
{

  /**
   * Updates the MAC key.
   *
   * @param MACKey pointer to an array of TINYSEC_KEYSIZE bytes 
   *        representing the key used for calculating MAC's
   * @return Whether key update was successful. Will return FAIL if any
   *         crypto is currently running or TinySecM is not initialized.
   */  
  command result_t updateMACKey(uint8_t * MACKey);

  /**
   * Gets the current MAC key.
   *
   * @param result pointer to an array of TINYSEC_KEYSIZE bytes 
   *        to store the current MAC key
   * @return Whether the operation was successful. Will return FAIL if
   *         TinySecM is not initialized.
   */  
  command result_t getMACKey(uint8_t * result);
  
  /**
   * Updates the encryption key. This does not change the IV. 
   *
   * @param encryptionKey pointer to an array of TINYSEC_KEYSIZE bytes 
   *        representing the key used for encryption
   * @return Whether the key update was successful. Will return FAIL if any
   *         crypto operation is currently running or TinySecM is not initialized.
   */  
  command result_t updateEncryptionKey(uint8_t * encryptionKey);

  /**
   * Gets the current encryption key.
   *
   * @param result pointer to an array of TINYSEC_KEYSIZE bytes 
   *        to store the current encryption key. 
   * @return Whether the operation was successful. Will return FAIL if
   *         TinySecM is not initialized.
   */  
  command result_t getEncryptionKey(uint8_t * result);

  /**
   * Reinitializes the counter portion of the IV.
   *
   * @return Whether the operation was successful. Will return FAIL if
   *         TinySecM is not initialized or any crypto operation is
   *         currently running.
   */  
  command result_t resetIV();

  /**
   * Gets the current IV.
   *
   * @param result pointer to an array of TINYSEC_IV_SIZE bytes 
   *        to store the IV. 
   * @return Whether the operation was successful. Will return FAIL if
   *         TinySecM is not initialized.
   */   
  command result_t getIV(uint8_t * result);
}
