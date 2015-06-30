/*
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
 * Date:    12/23/02
 */


// TODO: figure out our story about concurrent decrypts and encrypts

// Mica specific fast RC5 implementation. found in platform/mica

module TinySecM
{
  provides {
    interface TinySec;
    interface TinySecControl;
  }
  uses {
    interface BlockCipherMode;
    interface MAC;
    interface Interrupt;
    interface Random;
    interface BlockCipherInfo;
  }
}

implementation
{
  bool initialized;
  TinySec_Msg* cipher_ptr_FIXME;

  enum {
    // we allocate some static buffers on the stack; they have to be less
    // than this size
    TINYSECM_MAX_BLOCK_SIZE = 16,
    COMPUTE_MAC_IDLE, // no verify in progress
    COMPUTE_MAC_INITIALIZED, // verify has been initialized and ready for incremental computation
    COMPUTE_MAC_BUSY, // verify in the middle of incremental computation
    DECRYPT_IDLE, // no decrypt in progress
    DECRYPT_INITIALIZED, // decrypt has been initialized and is ready for incremental decryption
    DECRYPT_BUSY }; // incremental decrypt in progress

    
  uint8_t compute_mac_state;
  uint8_t decrypt_state;
  uint8_t blockSize;
  bool compute_mac_waiting;
  bool decrypt_waiting;
  struct computeMACBuffer {
    uint8_t position;
    uint8_t amount;
    bool finishMAC;
  } computeMACBuffer;

  struct decryptBuffer {
    TOS_Msg * rec_ptr;
    uint8_t position;
    uint8_t amount;
    bool finishDecrypt;
  } decryptBuffer;

  CipherModeContext cipherModeContext;
  MACContext macContext;

  uint8_t iv[TINYSECM_MAX_BLOCK_SIZE];

  /**
   * Initializes TinySec. BlockCipherMode and MAC contexts are initialized 
   * with respective keys, key size, and block size.
   *
   * @param blockSize block size of the block cipher in bytes
   * @param keySize key size of the block cipher in bytes
   * @param encryptionKey pointer to an array of keySize bytes 
   *        representing the key used for encryption
   * @param MACKey pointer to an array of keySize bytes 
   *        representing the key used for calculating MAC's
   * @return Whether TinySec initialization was successful. Reasons 
   *         for failure include BlockCipherMode or MAC init()
   */
  command result_t TinySecControl.init(uint8_t keySize, uint8_t * encryptionKey, uint8_t * MACKey) {
    result_t r1, r2, r3, r4;
    int i, local_addr;
    int node_id_length = sizeof(uint16_t);//sizeof(cipher_ptr_FIXME->addr);
    uint8_t tmp = call BlockCipherInfo.getPreferredBlockSize();
    
    if(tmp > TINYSECM_MAX_BLOCK_SIZE) {
      blockSize = 0;
      r3 = FAIL;
    }
    else {
      blockSize = tmp;
      r3 = SUCCESS;
    }
    
    compute_mac_waiting = FALSE;
    compute_mac_state = COMPUTE_MAC_IDLE;
    decrypt_state = DECRYPT_IDLE;
    decrypt_waiting = FALSE;

    computeMACBuffer.finishMAC = FALSE;
    decryptBuffer.finishDecrypt = FALSE;
    
    // FIXME: replace this with EEPROM read or random IV
    for(i=0;i<blockSize;i++) {
      iv[i] = 0;
    }

    if(TINYSEC_IV_LENGTH < node_id_length)
      r4 = FAIL;
    else
      r4 = SUCCESS;

    // write the source address into the 3rd and 4th bytes of iv
    local_addr = TOS_LOCAL_ADDRESS;
    iv[TINYSEC_IV_LENGTH-node_id_length] = local_addr & 0xff;
    for(i=1;i<node_id_length;i++) {
      local_addr = local_addr >> 8;
      iv[TINYSEC_IV_LENGTH-node_id_length+i] = local_addr & 0xff;
    }
    r1 = call BlockCipherMode.init(&cipherModeContext,keySize,encryptionKey);
    r2 = call MAC.init(&macContext,keySize,MACKey);
    if(rcombine(rcombine(r1,r2),rcombine(r3,r4)) == FAIL)
      return FAIL;
    else {
      initialized = TRUE;
      return SUCCESS;
    }
  }
  

  // WARNING: this function makes assumptions about the stucture of TinySec_Msg!!!!
  // Incremental MAC computation must be initialized before this is called.
  command result_t TinySec.decryptIncrementalInit(TinySec_Msg* ciphertext_ptr) {
    uint8_t decrypt_iv[TINYSECM_MAX_BLOCK_SIZE];
    int i;
    result_t result;
    uint16_t length;
    int length_remaining = sizeof(ciphertext_ptr->addr) + sizeof(ciphertext_ptr->type) + sizeof(ciphertext_ptr->length);

    if(decrypt_state != DECRYPT_IDLE || !initialized)
      return FAIL;
    
    if(compute_mac_state == COMPUTE_MAC_BUSY) {
      decrypt_waiting = TRUE;
      return SUCCESS;
    }

    decrypt_state = DECRYPT_BUSY;
    call Interrupt.enable();
    
    if(length_remaining > (blockSize - TINYSEC_IV_LENGTH))
      length_remaining = blockSize - TINYSEC_IV_LENGTH;
    
    // copy current iv into cipher buffer iv field
    memcpy(decrypt_iv,ciphertext_ptr->iv,TINYSEC_IV_LENGTH);
    // fill in remaining space with addr, AM type, and length
    memcpy(decrypt_iv+TINYSEC_IV_LENGTH,&(ciphertext_ptr->addr),length_remaining);
    
    // zero out the rest of the iv
    for(i=length_remaining+TINYSEC_IV_LENGTH;i<blockSize;i++) {
      decrypt_iv[i] = 0;
    }
    // if less than one block, then use one block. assumes buffer has been padded.
    if(ciphertext_ptr->length < blockSize)
      length = blockSize;
    else
      length = ciphertext_ptr->length;   

    result = call BlockCipherMode.initIncrementalDecrypt(&cipherModeContext,decrypt_iv,length);
    
    call Interrupt.disable();
    decrypt_state = DECRYPT_INITIALIZED;
    if(compute_mac_waiting) {
      compute_mac_waiting = FALSE;
      result = rcombine(result, call TinySec.computeMACIncremental(ciphertext_ptr,computeMACBuffer.position,computeMACBuffer.amount));
    }
    return result;
  }

  command result_t TinySec.decryptIncremental(TinySec_Msg * ciphertext_ptr, TOS_Msg * cleartext_ptr, uint8_t incr_decrypt_start, uint8_t amount) {
    result_t result;
    uint16_t done;

    if(decrypt_state == DECRYPT_IDLE || !initialized)
      return FAIL;
    
    if(compute_mac_state == COMPUTE_MAC_BUSY) {
      if(decrypt_waiting) {
	decryptBuffer.amount += amount;
      } else {
	decrypt_waiting = TRUE;
	decryptBuffer.rec_ptr = cleartext_ptr;
	decryptBuffer.position = incr_decrypt_start;
	decryptBuffer.amount = amount;
      }
      return SUCCESS;
    }

    if(decrypt_state == DECRYPT_BUSY) {
      if(decrypt_waiting)
	return FAIL; // error

      decrypt_waiting = TRUE;
      decryptBuffer.rec_ptr = cleartext_ptr;
      decryptBuffer.position = incr_decrypt_start;
      decryptBuffer.amount = amount;      
      return SUCCESS;
    }
    
    decrypt_state = DECRYPT_BUSY;
    call Interrupt.enable();
    result = call BlockCipherMode.incrementalDecrypt(&cipherModeContext,(ciphertext_ptr->enc)+incr_decrypt_start,cleartext_ptr->data,amount,&done);
    if(result == FAIL)
      dbg(DBG_CRYPTO,"Mode call failed.\n");
    call Interrupt.disable();
    decrypt_state = DECRYPT_INITIALIZED;
    if(compute_mac_waiting) {
      compute_mac_waiting = FALSE;
      result = rcombine(result, call TinySec.computeMACIncremental(ciphertext_ptr,computeMACBuffer.position,computeMACBuffer.amount));
    }
    if(decrypt_waiting) {
      decrypt_waiting = FALSE;
      result = rcombine(result, call TinySec.decryptIncremental(ciphertext_ptr,decryptBuffer.rec_ptr,decryptBuffer.position,decryptBuffer.amount));
    }
    if(ciphertext_ptr->length < blockSize) {
      if(done == blockSize) {
	decrypt_state = DECRYPT_IDLE;
	signal TinySec.decryptDone(result,cleartext_ptr,ciphertext_ptr);
      }
    } else {
      if(done == ciphertext_ptr->length) {
	decrypt_state = DECRYPT_IDLE;
	signal TinySec.decryptDone(result,cleartext_ptr,ciphertext_ptr);
      }
    }
    return result;
  }
 
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
  command result_t TinySec.computeMACIncrementalInit(TinySec_Msg* ciphertext_ptr) {
    result_t result;
    uint8_t length;
   
    if(compute_mac_state != COMPUTE_MAC_IDLE || !initialized)
      return FAIL;

    // make sure received packet length doesn't exceed buffer
    if(ciphertext_ptr->length > TOSH_DATA_LENGTH)
      return FAIL;

    if(ciphertext_ptr->length < blockSize)
      length = blockSize;
    else
      length = ciphertext_ptr->length;
    
    // initialize state variables in receive buffer
    ciphertext_ptr->computeMACDone = FALSE;
    ciphertext_ptr->validMAC = FALSE;
    
    compute_mac_state = COMPUTE_MAC_BUSY;
    call Interrupt.enable();
    result = call MAC.initIncrementalMAC(&macContext,sizeof(ciphertext_ptr->addr)+sizeof(ciphertext_ptr->length)+length+TOSH_AM_LENGTH+TINYSEC_IV_LENGTH);
    call Interrupt.disable();
    compute_mac_state = COMPUTE_MAC_INITIALIZED;
    return result;
  }

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
   *          incremental MAC computation (usually blockSize)
   * @return Whether incremental MAC computation was successful. Reasons 
   *         for failure include failure to initialize TinySec, failure to initialize 
   *         incremental MAC computation, concurrently running incremental MAC computation, 
   *         illegal start position, and internal failure in incremental MAC computation.
   */
  command result_t TinySec.computeMACIncremental(TinySec_Msg * ciphertext_ptr, uint8_t incr_mac_start, uint8_t amount) {
    if(!initialized)
      return FAIL;
    if(incr_mac_start >= TINYSEC_MSG_DATA_SIZE - TINYSEC_MAC_LENGTH)
      return FAIL;

    if(decrypt_state == DECRYPT_BUSY) {
      compute_mac_waiting = TRUE;
      computeMACBuffer.position = incr_mac_start;
      computeMACBuffer.amount = amount;
      return SUCCESS;
    }
    
    if(compute_mac_state == COMPUTE_MAC_BUSY) {                                                
      if(compute_mac_waiting)
	return FAIL; // mac computation already waiting
      
      compute_mac_waiting = TRUE;
      computeMACBuffer.position = incr_mac_start;
      computeMACBuffer.amount = amount;
      return SUCCESS;
    } else if(compute_mac_state == COMPUTE_MAC_IDLE) {
      return FAIL; // has not been initialized
    } else if(compute_mac_state == COMPUTE_MAC_INITIALIZED) {
      result_t result;
      compute_mac_state = COMPUTE_MAC_BUSY;
      call Interrupt.enable();
      result = call MAC.incrementalMAC(&macContext,((uint8_t*) ciphertext_ptr)+incr_mac_start,amount);
      call Interrupt.disable();
      compute_mac_state = COMPUTE_MAC_INITIALIZED;
      if(compute_mac_waiting) {
	compute_mac_waiting = FALSE;
	result = rcombine(result,call TinySec.computeMACIncremental(ciphertext_ptr,computeMACBuffer.position,computeMACBuffer.amount));
      }
      // check waiting state and finish up work
      if(computeMACBuffer.finishMAC) {
	computeMACBuffer.finishMAC = FALSE;
	result = rcombine(result,call TinySec.computeMACIncrementalFinish(ciphertext_ptr));
      }
      if(decrypt_waiting) {
	decrypt_waiting = FALSE;
	if(decrypt_state == DECRYPT_INITIALIZED) {
	  result = rcombine(result, call TinySec.decryptIncremental(ciphertext_ptr,decryptBuffer.rec_ptr,decryptBuffer.position,decryptBuffer.amount));
	} else if (decrypt_state == DECRYPT_IDLE) {
	  result = rcombine(result, call TinySec.decryptIncrementalInit(ciphertext_ptr));
	} else {
	  return FAIL;
	}
      }
      return result;
    } else 
      return FAIL;
  }

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
  command result_t TinySec.computeMACIncrementalFinish(TinySec_Msg * ciphertext_ptr) {
    if(!initialized)
      return FAIL;

    if(decrypt_state == DECRYPT_BUSY) {
      computeMACBuffer.finishMAC = TRUE;
      return SUCCESS;
    }
    
    if(compute_mac_state == COMPUTE_MAC_IDLE) {
      // this is an error. state should be unreachable
      return FAIL;
    } else if(compute_mac_state == COMPUTE_MAC_BUSY) {
      if(!compute_mac_waiting) // this is an error. state should be unreachable
	return FAIL;
      computeMACBuffer.finishMAC = TRUE; // indicates previous code should call IncrementalFinish
      return SUCCESS;
    } else if(compute_mac_state == COMPUTE_MAC_INITIALIZED) { 
      result_t result;
      compute_mac_state = COMPUTE_MAC_BUSY;
      call Interrupt.enable();
      result = call MAC.getIncrementalMAC(&macContext,ciphertext_ptr->calc_mac,TINYSEC_MAC_LENGTH+TINYSEC_ACK_LENGTH);
      call Interrupt.disable();
      compute_mac_state = COMPUTE_MAC_IDLE;
      ciphertext_ptr->computeMACDone = TRUE;
      return result;
    } else 
      return FAIL;
  }

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
  command result_t TinySec.verifyMAC(TinySec_Msg* ciphertext_ptr) {
    int i;
    
    if(!initialized) 
      return FAIL;

    // indicates incremental MAC computation has not completed
    if(compute_mac_state != COMPUTE_MAC_IDLE || !(ciphertext_ptr->computeMACDone)) {
      ciphertext_ptr->validMAC = FALSE;
      return FAIL;
    }

    // verify calculated MAC with one received in packet
    for(i=0;i<TINYSEC_MAC_LENGTH;i++) {
      if((ciphertext_ptr->calc_mac)[i] != (ciphertext_ptr->mac)[i]) {
        dbg(DBG_CRYPTO,"Invalid MAC byte %d - calcmac:%hx ciphermac:%hx\n",i,(ciphertext_ptr->calc_mac)[i],(ciphertext_ptr->mac)[i]);
	ciphertext_ptr->validMAC = FALSE;
	return SUCCESS;
      }
    } 
    ciphertext_ptr->validMAC = TRUE;
    return SUCCESS;
  }

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
  command result_t TinySec.computeMAC(TOS_Msg* cleartext_ptr, TinySec_Msg* ciphertext_ptr) {
    result_t r1, r2;
    uint8_t length;
    if(!initialized)
      return FAIL;
    if(ciphertext_ptr->length > TOSH_DATA_LENGTH)
      return FAIL;

    call Interrupt.enable();
    if(ciphertext_ptr->length < blockSize)
      length = blockSize;
    else
      length = ciphertext_ptr->length;
    r1 = call MAC.MAC(&macContext,(uint8_t*) &(ciphertext_ptr->addr),sizeof(ciphertext_ptr->addr)+sizeof(ciphertext_ptr->length)+length+TOSH_AM_LENGTH+TINYSEC_IV_LENGTH,ciphertext_ptr->calc_mac,TINYSEC_MAC_LENGTH+TINYSEC_ACK_LENGTH);
    // copy calculated mac to mac field. reason is because extra byte was calculated and stored in ack_byte
    memcpy(ciphertext_ptr->mac,ciphertext_ptr->calc_mac,TINYSEC_MAC_LENGTH);
    dbg(DBG_CRYPTO,"MAC computed: %hx %hx %hx %hx\n",(ciphertext_ptr->mac)[0],(ciphertext_ptr->mac)[1],(ciphertext_ptr->mac)[2],(ciphertext_ptr->mac)[3]);
    call Interrupt.disable();
    r2 = signal TinySec.computeMACDone(r1,cleartext_ptr,ciphertext_ptr);
    return rcombine(r1,r2);
  }

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
  command result_t TinySec.encrypt(TOS_Msg* cleartext_ptr, TinySec_Msg* ciphertext_ptr) {
    int i;
    result_t r1, r2;
    uint16_t length;
    int length_remaining;
    if(!initialized)
      return FAIL;
    if(ciphertext_ptr->length > TOSH_DATA_LENGTH)
      return FAIL;

    call Interrupt.enable();
    length_remaining = sizeof(ciphertext_ptr->addr) + sizeof(ciphertext_ptr->type) + sizeof(ciphertext_ptr->length);

    if(length_remaining > (blockSize - TINYSEC_IV_LENGTH))
      length_remaining = blockSize - TINYSEC_IV_LENGTH;

    // copy current iv into cipher buffer iv field
    memcpy(&(ciphertext_ptr->iv),iv,TINYSEC_IV_LENGTH);
    // fill in remaining space with addr, AM type, and length
    memcpy(iv+TINYSEC_IV_LENGTH,&(ciphertext_ptr->addr),length_remaining);
 
    // zero out the rest of the iv
    for(i=length_remaining+TINYSEC_IV_LENGTH;i<blockSize;i++) {
      iv[i] = 0;
    }
    // if less than one block, then use one block. assumes buffer has been padded.
    if(ciphertext_ptr->length < blockSize)
      length = blockSize;
    else
      length = ciphertext_ptr->length;
    r1 = call BlockCipherMode.encrypt(&cipherModeContext,cleartext_ptr->data,ciphertext_ptr->enc,length,iv);
    i=0;
    // update IV by one
    while(i<TINYSEC_IV_LENGTH-sizeof(uint16_t)) { //cipher_ptr_FIXME->addr)
      if(iv[i] == 0xff) {
	iv[i] = 0;
      } else {
	iv[i] = iv[i] + 1;
	break;
      }
      i++;
    }
    call Interrupt.disable();
    r2 = signal TinySec.encryptDone(r1,cleartext_ptr,ciphertext_ptr);
    return rcombine(r1,r2);
  }

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
/*    command result_t TinySec.decrypt(TOS_Msg* cleartext_ptr, TinySec_Msg* ciphertext_ptr) { */
/*      if(!initialized) */
/*        return FAIL; */
/*      if(ciphertext_ptr->length > TOSH_DATA_LENGTH) */
/*        return FAIL; */
/*      clear_ptr = cleartext_ptr; */
/*      cipher_ptr = ciphertext_ptr; */
/*      post decrypt_(); */
/*      return SUCCESS; */
/*    } */

  /**
   * Pads the data in the buffer pointed to by cleartext_ptr to blockSize bytes.
   *
   * Pre-condition:
   * cleartext_ptr->length is valid
   *
   * Post-condition:
   * If cleartext_ptr->length < blockSize, cleartext_ptr->data is padded to blockSize bytes, 
   * otherwise TRUE. 
   *
   * @param cleartext_ptr pointer to buffer containing unencrypted data to be padded
   * @return Whether padding data in buffer pointed to by cleartext_ptr resulted in an error. 
   *         Currently always successful.
   */ 
  command result_t TinySec.preparePadding(TOS_Msg* cleartext_ptr) {
    uint8_t length = cleartext_ptr->length;
    int i;
    uint16_t r;
    
    if(cleartext_ptr->length >= blockSize)
      return SUCCESS;

    r = call Random.rand();
    for(i=length;i<blockSize-1;i=i+2) {
      memcpy((cleartext_ptr->data)+i,&r,2);
      r = call Random.rand();
    }
    if(i == (blockSize-1)) {
      memcpy((cleartext_ptr->data)+i,&r,1);
    }
    return SUCCESS;
  }

  /**
   * Removes padding from data in the buffer pointed to by cleartext_ptr.
   *
   * Pre-condition:
   * cleartext_ptr->length is valid
   *
   * Post-condition:
   * If cleartext_ptr->length < blockSize, padding is removed from cleartext_ptr->data, 
   * otherwise TRUE. 
   *
   * @param cleartext_ptr pointer to buffer containing unencrypted data from which padding is 
   *        to be removed
   * @return Whether padding removal in buffer pointed to by cleartext_ptr resulted in an error. 
   *         Currently always successful.
   */ 
  command result_t TinySec.removePadding(TOS_Msg* cleartext_ptr) {
    uint8_t length = cleartext_ptr->length;
    int i;
    if(cleartext_ptr->length >= blockSize)
      return SUCCESS;

    for(i=length;i<blockSize;i++) {
      (cleartext_ptr->data)[i] = 0;
    }
    return SUCCESS;
  }

}
