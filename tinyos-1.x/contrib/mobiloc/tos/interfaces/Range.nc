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
 * Authors:		Sarah Bergbreiter
 * Date last modified:  11/11/03
 *
 * The Range interface signals an event when new range data is available or
 * when its about to become available.
 *
 */

interface Range {

  /**
   * rangeBegin.
   * @param seqNum: the sequence number of the ultrasound beep
   *                (used to correlate with other range estimates)
   * @return Always returns SUCCESS.
   */
  event result_t rangeBegin(uint16_t seqNum);

  /**
   * rangeDone.
   * @param seqNum: the sequence number of the ultrasound beep
   *                (used to correlate with other range estimates)
   * @param range: the estimated range in centimeters
   * @param ts: the time stamp that the estimate was gathered at
   * @param confidence: no idea what this will be yet
   * @return Always returns SUCCESS.
   */
  event result_t rangeDone(uint16_t seqNum,
			   uint16_t range,
			   uint16_t ts,
			   uint8_t confidence);

}
