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
 * Authors: Chris Karlof
 * Date:    9/26/02
 */
includes AM;
interface TinySec
{
  /**
   * Signals completed encryption from data in buffer pointed to by 
   * cleartext_ptr to buffer pointed to by ciphertext_ptr. Success 
   * is indicated by result.
   *
   * @param result whether encryption was successful
   * @param cleartext_ptr pointer to buffer containing unencrypted data
   * @param ciphertext_ptr pointer to buffer for writing encrypted data
   * @return Whether the signal handler was successful. Currently 
   *         always succesful.
   */    
  event result_t encryptDone(result_t result, TOS_Msg* cleartext_ptr, TinySec_Msg* ciphertext_ptr);

  /**
   * Signals completed computation of MAC of data in buffer pointed to by 
   * cleartext_ptr to buffer pointed to by ciphertext_ptr. Success 
   * is indicated by result.
   *
   * @param result whether MAC computation was successful
   * @param cleartext_ptr pointer to buffer containing unencrypted data
   * @param ciphertext_ptr pointer to buffer for writing encrypted data
   * @return Whether the signal handler was successful. Currently 
   *         always succesful.
   */    
  event result_t computeMACDone(result_t result, TOS_Msg* cleartext_ptr, TinySec_Msg* ciphertext_ptr);

  /**
   * Signals completed decryption from data in buffer pointed to by 
   * ciphertext_ptr to buffer pointed to by cleartext_ptr. Success 
   * is indicated by result.
   *
   * @param result whether decryption was successful
   * @param cleartext_ptr pointer to buffer containing unencrypted data
   * @param ciphertext_ptr pointer to buffer for writing encrypted data
   * @return Whether the signal handler was successful. Currently 
   *         always succesful.
   */      
  event result_t decryptDone(result_t result, TOS_Msg* cleartext_ptr, TinySec_Msg* ciphertext_ptr);


  /**
   * Posts a task for encrypting data in the buffer pointed to by cleartext_ptr into the 
   * buffer pointed to by ciphertext_ptr.
   *
   * Pre-condition:
   * All fields in buffer pointed to by ciphertext_ptr are valid &&
   * ciphertext_ptr->length <= TOSH_DATA_LENGTH &&
   * TinySec is initialized
   *
   * Post-condition:
   * Encryption task for (cleartext_ptr,ciphertext_ptr) is posted 
   *
   * @param cleartext_ptr pointer to buffer containing unencrypted data
   * @param ciphertext_ptr pointer to buffer for writing encrypted data
   * @return Whether posting the task for encryption resulted in an error. Reasons 
   *         for failure include failure to initialize TinySec and illegal length field in 
   *         buffer pointed to by ciphertext_ptr.
   */    
  command result_t encrypt(TOS_Msg* cleartext_ptr, TinySec_Msg* ciphertext_ptr);

  /**
   * Posts a task for computing the MAC over the buffer pointed to by ciphertext_ptr.
   *
   * Pre-condition:
   * Encryption of data in buffer pointed to by cleartext_ptr has completed and encryption is 
   * in buffer pointed to by ciphertext_ptr &&
   * All fields in buffer pointed to by ciphertext_ptr are valid &&
   * ciphertext_ptr->length <= TOSH_DATA_LENGTH &&
   * TinySec is initialized
   *
   * Post-condition:
   * MAC computation task for (cleartext_ptr,ciphertext_ptr) is posted 
   *
   * @param cleartext_ptr pointer to buffer containing unencrypted data
   * @param ciphertext_ptr pointer to buffer containing encrypted data
   * @return Whether posting the task for MAC verification resulted in an error. Reasons 
   *         for failure include failure to initialize TinySec and illegal length field in 
   *         buffer pointed to by ciphertext_ptr.
   */    
  command result_t computeMAC(TOS_Msg* cleartext_ptr, TinySec_Msg* ciphertext_ptr);

  /*
   * Posts a task for decrypting data in the buffer pointed to by cleartext_ptr into the 
   * buffer pointed to by ciphertext_ptr.
   *
   * Pre-condition:
   * All fields in buffer pointed to by ciphertext_ptr are valid &&
   * ciphertext_ptr->length <= TOSH_DATA_LENGTH &&
   * TinySec is initialized
   *
   * Post-condition:
   * Decryption task for (cleartext_ptr,ciphertext_ptr) is posted 
   *
   * @param cleartext_ptr pointer to buffer for writing unencrypted data
   * @param ciphertext_ptr pointer to buffer containing encrypted data
   * @return Whether posting the task for decryption resulted in an error. Reasons 
   *         for failure include failure to initialize TinySec and illegal length field in 
   *         buffer pointed to by ciphertext_ptr.
   */ 
 /*   command result_t decrypt(TOS_Msg* cleartext_ptr, TinySec_Msg* ciphertext_ptr); */

  /**
   * Initializes incremental MAC computation.
   *
   * Pre-condition:
   * All fields in the TinySec_Msg buffer pointed to by ciphertext_ptr are valid and the 
   *   length field is <= TOSH_DATA_LENGTH  &&  
   * TinySec is initialized &&
   * There is no concurrently running incremental MAC computation && 
   * Interrupts are disabled
   *
   * Post-condition:
   * Incremental MAC computation on the buffer pointed to by ciphertext_ptr 
   *    buffer is initialized and ready.
   *
   * @param ciphertext_ptr pointer to the TinySec_Msg buffer over which the MAC is to be computed 
   * 
   * @return Whether incremental MAC computation initialization was
   *         successful. Reasons for failure include failure to
   *         initialize TinySec, length field is too long,
   *         concurrently running incremental MAC computation, and
   *         failure in incremental MAC initialization.
   */
  command result_t computeMACIncrementalInit(TinySec_Msg* ciphertext_ptr);

  /**
   * Computes an incremental MAC computation over the buffer initialized in
   * TinySec.computeMACincrementalInit. The buffer is treated as an array of bytes. Incremental
   * MAC computation is continued at incr_mac_start for amount bytes.
   *
   * Pre-condition:
   * TinySec was initialized for incremental MAC computation with TinySec.computeMACIncrementalInit &&
   * TinySec is initialized &&
   * Interrupts are disabled
   *
   * Post-condition:
   * Incremental MAC computation on the buffer initialized in TinySec.computeMACIncremental is 
   *    is done over amount bytes starting at incr_mac_start
   *
   * @param incr_mac_start byte position in buffer to continue MAC computation
   * @param amount number of bytes (starting at incr_mac_start) over which to compute the 
   *          incremental MAC computation (usually BLOCK_SIZE)
   * @return Whether incremental MAC computation was successful. Reasons 
   *         for failure include failure to initialize TinySec, failure to initialize 
   *         incremental MAC computation, concurrently running incremental MAC computation, 
   *         illegal start position, and internal failure in incremental MAC computation.
   */
  command result_t computeMACIncremental(TinySec_Msg * ciphertext_ptr, uint8_t position, uint8_t amount);

  /**
   * Finalizes an incremental MAC computation over the buffer initialized in
   * TinySec.computeMACincrementalInit or posts that task for completion if incremental MAC 
   * computation is still ongoing. 
   *
   * Pre-condition:
   * TinySec was initialized for incremental MAC computation with TinySec.computeMACIncrementalInit &&
   * TinySec is initialized &&
   * Interrupts are disabled
   *
   * Post-condition:
   * Incremental MAC computation is finalized on the buffer initialized in 
   * TinySec.computeMACIncremental. TinySec.verifyMAC can now be called to verify MAC.
   *
   * @return Whether incremental MAC computation was successful. Reasons 
   *         for failure include failure to initialize TinySec, failure to initialize 
   *         incremental MAC computation, concurrently running incremental 
   *         MAC computation, internal error, and internal failure in MAC computation finalization.
   */
  command result_t computeMACIncrementalFinish(TinySec_Msg * ciphertext_ptr);

  /**
   * Checks to see if the calculated MAC matches the one sent in the packet. 
   *
   * Pre-condition:
   * MAC computation was completed for the buffer pointed to by ciphertext_ptr &&
   * TinySec is initialized
   *
   * Post-condition:
   * ciphertext_ptr->validMAC indicates the validity of the received MAC vs. the calculated MAC 
   *
   * @param ciphertext_ptr pointer to buffer over which the MAC is to be verified
   * @return Whether MAC verification resulted in an error. Reasons 
   *         for failure include failure to initialize TinySec and incomplete MAC computation.
   */  
  command result_t verifyMAC(TinySec_Msg* ciphertext_ptr);

  command result_t decryptIncrementalInit(TinySec_Msg* ciphertext_ptr);

  command result_t decryptIncremental(TinySec_Msg* ciphertext_ptr, TOS_Msg * plaintext_ptr, uint8_t incr_decrypt_start, uint8_t amount);
  
  /**
   * Pads the data in the buffer pointed to by cleartext_ptr to BLOCK_SIZE bytes.
   *
   * Pre-condition:
   * cleartext_ptr->length is valid
   *
   * Post-condition:
   * If cleartext_ptr->length < BLOCK_SIZE, cleartext_ptr->data is padded to BLOCK_SIZE bytes, 
   * otherwise TRUE. 
   *
   * @param cleartext_ptr pointer to buffer containing unencrypted data to be padded
   * @return Whether padding data in buffer pointed to by cleartext_ptr resulted in an error. 
   *         Currently always successful.
   */ 
  command result_t preparePadding(TOS_Msg* cleartext_ptr); 

  /**
   * Removes padding from data in the buffer pointed to by cleartext_ptr.
   *
   * Pre-condition:
   * cleartext_ptr->length is valid
   *
   * Post-condition:
   * If cleartext_ptr->length < BLOCK_SIZE, padding is removed from cleartext_ptr->data, 
   * otherwise TRUE. 
   *
   * @param cleartext_ptr pointer to buffer containing unencrypted data from which padding is 
   *        to be removed
   * @return Whether padding removal in buffer pointed to by cleartext_ptr resulted in an error. 
   *         Currently always successful.
   */   
  command result_t removePadding(TOS_Msg* cleartext_ptr); 

}
