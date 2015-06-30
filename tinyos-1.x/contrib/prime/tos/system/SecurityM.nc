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

module SecurityM
{
  provides {
    interface StdControl as Control;
  }
  uses {
    interface TinySecControl;
  }
}

implementation
{

  uint8_t enc_key[TINYSEC_KEYSIZE];
  uint8_t mac_key[TINYSEC_KEYSIZE];

  // initializes TinySec
  command result_t Control.init() {
    uint8_t key_tmp[2*TINYSEC_KEYSIZE] = {TINYSEC_KEY};
    memcpy(enc_key,key_tmp,TINYSEC_KEYSIZE);
    memcpy(mac_key,key_tmp+TINYSEC_KEYSIZE,TINYSEC_KEYSIZE);
    
    if (! (call TinySecControl.init(TINYSEC_KEYSIZE,enc_key,mac_key))) {
      dbg(DBG_CRYPTO, "SecurityM: Couldn't initialize TinySecM\n");
      return FAIL;
    }

    return SUCCESS;
  }
  
  command result_t Control.start() {
    return SUCCESS;
  }

  command result_t Control.stop() {
    return SUCCESS;
  }

}
