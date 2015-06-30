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

interface TinySecControl
{
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
   *         for failure include BlockCipherMode or MAC init() failure.
   */
  command result_t init(uint8_t keySize, uint8_t * encyptionKey, uint8_t * MACKey);


}
