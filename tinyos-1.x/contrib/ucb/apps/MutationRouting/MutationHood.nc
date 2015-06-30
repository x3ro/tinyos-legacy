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
 * Author: August Joki <august@berkeley.edu>
 *
 *
 *
 */


interface MutationHood {
  command result_t init();
  command result_t start();

  command uint16_t getParent(uint16_t id);
  command uint16_t getChild(uint16_t id);
  command uint8_t getCost(uint16_t id);
  command uint16_t getSeqNo(uint16_t id);
  command uint8_t getFailCount(uint16_t id);
  command uint8_t getOnShortcutBlacklist(uint16_t id);
  command uint8_t getOnRecruitBlacklist(uint16_t id);
  command uint16_t getNumNeighbors(uint16_t id);
  command uint16_t getLowestCostNeighbor(uint16_t id);
  command uint16_t getHighestCostNeighbor(uint16_t id);
  command uint16_t getGrandparent(uint16_t id);
  command uint16_t getRecruit(uint16_t id);
  command uint16_t getRoot();

  command result_t setID(uint16_t id);
  command result_t setParent(uint16_t id, uint16_t parent);
  command result_t setChild(uint16_t id, uint16_t child);
  command result_t setCost(uint16_t id, uint8_t cost);
  command result_t setSeqNo(uint16_t id, uint16_t seqNo);
  command result_t setFailCount(uint16_t id, uint8_t failCount);
  command result_t setOnShortcutBlacklist(uint16_t id, uint8_t bl);
  command result_t setOnRecruitBlacklist(uint16_t id, uint8_t bl);
  command result_t checkRecruit(uint16_t id);
  command result_t isNeighbor(uint16_t id);

}
