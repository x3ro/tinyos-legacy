// $Id: TinySecApp.nc,v 1.1.1.1 2007/11/05 19:09:04 jpolastre Exp $

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

/* Authors: Naveen Sastry
 * Date:    6/4/03
 */

/**
 * Library to provide application level encryption / decryption support using
 * TinySec. 
 * @author Naveen Sastry
 */
interface TinySecApp
{
  /**
   * Initializes the library using the given key. This key will be used for
   * all operations until another key reset.
   *
   * @param key a pointer to the key buffer. it must be one block size in
   *        length.
   * @param globalkey if true, indicates that the key is shared by other
   *        nodes; the library then changes its behavior accordingly to include
   *        the TOS_LOCAL_ADDRESS in the IV when possible. This is only
   *        necessary, though, if the key is shared with other nodes.
   * @returns whether the initialization was successful or not. This can return
   *        FAILURE if the mode could not be initialized properly.
   */
  command result_t init (uint8_t * key, bool globalkey);

  /**
   * Encrypts the given plaintext data in the ciphertext buffer. Furthermore,
   * IVlength bytes of an initialization vector will be created and populated
   * into the buffer pointed by IV. 
   *
   * In place encryption should work provided that the plain and and cipher
   * buffer are the same. (they may either be the same or
   * non-overlapping. partial overlaps are not supported).
   *
   * @param plaintext the original, cleartext buffer
   * @param plainLength length of the cleartext. This must be at least
   *        blcoksize bytes.
   * @param IVlength number of bytes to use for the IV. This must not be
   *        greater the blocksize. Confidentiality and semantic security
   *        increases with larger iv lengths.
   * @param IV the system will generate the IV and place a copy of the IVlength
   *        bytes in this buffer. The IV is necessary to decrypt the
   *        ciphertext.
   * @param ciphertext the resulting encrypted data. this pointer may EITHER
   *        be exactly the same as plaintext or it must not overlap with the
   *        plaintext buffer.
   * @returns whether or not the operation was successful. This operation can
   *        fail if the task queue fills up, or if the underlying mode fails,
   *        or if the plainLength is not at least the block size.
   */
  command result_t encryptData (uint8_t * plaintext,
                                uint8_t plainLength, 
                                uint8_t IVlength,
                                uint8_t * IV,
                                uint8_t * ciphertext);

  /**
   * Event signalled wehn the encrypt operation completes.
   *
   * @param result whether the encryption operation was successful or not.
   * @param ciphertext the ciphertext buffer that was passed in during the
   *        encrypt operation.
   * @return whether the event was successfully handled. 
   */
  event result_t encryptDataDone (result_t result,
                                  uint8_t* ciphertext);

  /**
   * Decrypts the given ciphertext data in the plaintext buffer. 
   *
   * In place decryption should work provided that the plain and and cipher
   * buffer are the same. (they may either be the same or
   * non-overlapping. partial overlaps are not supported).
   *
   * @param ciphertext the original, encrypted data
   * @param cipherLengh length of the ciphertext. This must be at least
   *        blcoksize bytes.
   * @param IVlength number of bytes to use for the IV. This must not be
   *        greater the blocksize. Confidentiality and semantic security
   *        increases with larger iv lengths.
   * @param IV the initializtion vector for this buffer.
   * @param plaintext the resulting encrypted data. this pointer may EITHER
   *        be exactly the same as ciphertext or it must not overlap with the
   *        ciphertext buffer.
   * @returns whether or not the operation was successful. This operation can
   *        fail if the task queue fills up, or if the underlying mode fails,
   *        or if the plainLength is not at least the block size.
   */
  command result_t decryptData (uint8_t * ciphertext,
                                uint8_t cipherLength, 
                                uint8_t IVlength,
                                uint8_t * IV,
                                uint8_t * plaintext);

  /**
   * Event signalled wehn the decrypt operation completes.
   *
   * @param result whether the decryption operation was successful or not.
   * @param ciphertext the plaintext buffer that was passed in during the
   *        decrypt operation.
   * @return whether the event was successfully handled. 
   */
  event result_t decryptDataDone (result_t result, uint8_t* plaintext);
}
