/*									tab:4
 * "Copyright (c) 2002-2005 The Regents of the University  of California.  
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

/*
 * Author:      Barbara Hohlt	
 * Project:	Flexible Power Scheduling
 */

/** 
 * Neighborhood interface to a software neighborhood component. 
 * @author Barbara Hohlt 
 */

interface Neighborhood {

  /**
   * Convert mote-id to grid location 
   * 
   * @param moteid Id to convert.  
   * 
   * @return grid location 
   * 
   */
   command uint8_t mote2Grid(uint16_t moteid) ;

  /**
   * Set load 
   * 
   * @param l Set traffic load of this mote. 
   * 
   * @return void 
   * 
   */
  command void setLoad(uint8_t l);

  /**
   * Set new parent 
   * 
   * @param pid 
   * @param pdepth 
   * @param pload 
   * 
   * @return void 
   * 
   */
  command void setParent(uint16_t pid, uint8_t pdepth, uint8_t pload);

  /**
   * Set parent unknown
   * 
   * @return void 
   * 
   */
  command void unsetParent();

  /**
   * Determine if this is a one hop neighbor. 
   * 
   * @param nMsg Message from neighbor.
   * 
   * @return TRUE or FALSE 
   * 
   */
  command bool isNeighbor(TOS_MsgPtr nMsg);

  /**
   * Get a measure of goodness for this link compared to the current parent 
   * 
   * @param qMsg Message from neighbor.
   * 
   * @return A value between 0-256 where 256 represent the best
   * goodness
   */
  command uint8_t compareQuality(TOS_MsgPtr qMsg);
}
