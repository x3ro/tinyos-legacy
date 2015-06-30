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
 * Authors: Naveen Sastry
 * Date:    9/26/02
 */

/**
 * Module to exercise the block cipher interface
 *
 * The test ensures that a block cipher enciphers a known plaintext into a
 * previously verified ciphertext. It then performs 20,000 block cipher
 * operations to allow for timing. Finally, the program outputs the output
 * of the original encryption to the UART for computer verification.
 */
module CipherTestM {
  provides {
    interface StdControl;
  }
  uses {
    interface BlockCipher;
    interface BlockCipherInfo;
    interface Leds;  
    interface StdControl as CommControl;
    interface SendMsg;
  }
}

// correct rol macro, for checking compat. 
#define compatrol32(a, n) ( a = (((a) << (n)) | ((a) >> (32-(n)))))

implementation {

  struct TOS_Msg data;
  CipherContext cc;
  int k;
    
  // we use 2 sets of test vectors: one for RC5, one for SkipJack. make sure
  // they're selected appropriately.
  
  // the "key" to initialize the block cipher. not part of the test vector
  // since the key size can vary depending on the cipher imple
  uint8_t RC5Testkey[8] __attribute__((C)) = {0x52, 0x69, 0xf1, 0x49, 
                                           0xd4, 0x1b, 0xa0, 0x15}; 
  // the "key" to initialize the block cipher. not part of the test vector
  // since the key size can vary depending on the cipher imple 
  uint8_t SJTestkey[10] __attribute__((C)) = {0x00, 0x99, 0x88, 0x77, 0x66,
                                            0x55, 0x44, 0x33, 0x22, 0x11};
  // the ciphertext buffer.
  uint8_t cipher[8];

  // struct which defines the test vectors.
  typedef struct testVector {
    uint8_t plain[8];
    uint8_t correct[8];
    uint8_t * key;
    uint8_t keySize;
  } testVector;

  // initialize the RC5 test vector. This is a known encipherment
  testVector RC5 __attribute((C)) = {
    {0x65, 0xc1, 0x78, 0xb2, 0x84, 0xd1, 0x97, 0xcc}, 
    {0x03, 0x09, 0x81, 0xcc, 0xcb, 0x7c, 0xf0, 0xb9},
    RC5Testkey,
    sizeof(RC5Testkey) };

  // initialize the SkipJack test vector.
  // This is a known encipherment (from NIST)  
  testVector SJ __attribute((C)) = {
    {0x33, 0x22, 0x11, 0x00, 0xdd, 0xcc, 0xbb, 0xaa},
    {0x25, 0x87, 0xca, 0xe2, 0x7a, 0x12, 0xd3, 0x00}, 
    SJTestkey, 
    sizeof(SJTestkey) };

  // select the test vector we'll be using. this should match the cipher
  // selected in  CipherTest.nc
  testVector *test __attribute((C)) = &RC5;
    
  /**
   * Init method which does the work of testing the interface.
   *
   * Sets the leds into a known state and then initializes the cipher.
   */
  command result_t StdControl.init() {

    // only proceed if the block cipher works on 8 byte blocks.
    if (call BlockCipherInfo.getPreferredBlockSize() != 8) {
      return FAIL;
    }
    
    call Leds.init();
    call CommControl.init();

    call Leds.redOff();
    call Leds.greenOff();
    call Leds.yellowOff();

    if (call BlockCipher.init (&cc, 8, test->keySize, test->key) != SUCCESS) {
      dbg(DBG_USR1, "TestCipherM: Couldn't itialize block cipher\n");
      return FAIL;
    }
    return SUCCESS;
    
  }
  

  event result_t SendMsg.sendDone(TOS_MsgPtr sent, result_t success) {
    return SUCCESS;
  }

  /**
   * Commences the test.
   */
  command result_t StdControl.start() {
    uint16_t i;
    // encrypt the known plaintext (from the test vector)
    if (! call BlockCipher.encrypt(&cc, test->plain, cipher)) {
      dbg(DBG_USR1, "TestCipherM: Couldn't encyrpt block\n");
      return FAIL;
    }
    // check to make sure that it encrypted properly.
    if (!memcmp(test->correct, cipher, 8)) {
      // now decrypt it in place
      if (!call BlockCipher.decrypt( &cc, cipher, cipher)) {
        dbg(DBG_USR1, "TestCipherM: Couldn't decrypt block\n");
        return FAIL;
      }
      // and that it decrypted properly.
      if (! memcmp (test->plain, cipher, 8)) {
        call Leds.greenOn();
      }
    }
    
    // timing run:
    for (i = 0; i < 20000; i++) {
      call BlockCipher.encrypt(&cc, cipher, cipher);
    }
    call Leds.redOn();
    
    // encrypt the known plaintext (from the test vector)
    if (! call BlockCipher.encrypt(&cc, test->plain, cipher)) {
      dbg(DBG_USR1, "TestCipherM: Couldn't encyrpt block\n");
      return FAIL;
    }

    // copy from the first one to uart
    memcpy (data.data + 2, cipher, 8);
    if (call SendMsg.send( TOS_UART_ADDR, 10, &data ) ) {
      call Leds.yellowOn();
    }
    
    call Leds.yellowOn();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }
}
