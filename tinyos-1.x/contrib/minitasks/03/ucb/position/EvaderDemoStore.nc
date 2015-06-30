/*									tab:4
 *
 *
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*
 * Authors:   Philip Levis <pal@cs.berkeley.edu>
 * Description: Simple data store component for July demo.
 * History:   July 9, 2003         Inception.
 *
 */
includes LocalizationConfig;

interface EvaderDemoStore {

  // Components using location should use these three functions
  // and these three functions only.
  command uint16_t getPositionX();
  command uint16_t getPositionY();
  command location_t getPosition();
 
  // Configuration: whether to use localized position or omniscient
  // word-of-god position, whether we're an anchor, etc.
  // POSITION_LOCALIZED, POSITION_WORD, POSITION_HARDCODED
  command void useWhichPosition(PositionType type);
  command void setIsAnchor(bool isAnchor);
  command bool getIsAnchor();
  command void setPosition(LocationInfo_t pos);

  // Setting and getting localized values.
  command uint16_t getLocalizedPositionX();
  command uint16_t getLocalizedPositionY();
  command location_t getLocalizedPosition();
  command void setLocalizedPosition(uint16_t x, uint16_t y);
  command void setLocalizedLoc(location_t loc);

  // Setting and getting word-of-god values.
  command uint16_t getRealPositionX();
  command uint16_t getRealPositionY();
  command location_t getRealPosition();
  command void setRealPosition(uint16_t x, uint16_t y);
  command void setRealLoc(location_t loc);
  
  // Setting and hardcoded values.
  command uint16_t getHardcodedPositionX();
  command uint16_t getHardcodedPositionY();
  command location_t getHardcodedPosition();
  command void setHardcodedPosition(uint16_t x, uint16_t y);
  command void setHardcodedLoc(location_t loc);
  
  // Components using evader location should use these three functions
  // and these three functions only.
  command uint16_t getEvaderX();
  command uint16_t getEvaderY();
  command location_t getEvader();
 
  // Configuration: use estimated values or word-of-god, setting
  // overall values.
  command void setEvader(LocationInfo_t pos);
  command void useEstimatedEvader(bool use);

  // Getting and setting estimated positions
  command uint16_t getEstimatedEvaderX();
  command uint16_t getEstimatedEvaderY();
  command location_t getEstimatedEvader();
  command void setEstimatedEvader(uint16_t x, uint16_t y);
  command void setEstimatedEvaderLoc(location_t loc);

  // Getting and setting word-of-god positions
  command uint16_t getRealEvaderX();
  command uint16_t getRealEvaderY();
  command location_t getRealEvader();
  command void setRealEvader(uint16_t x, uint16_t y);
  command void setRealEvaderLoc(location_t loc);
}
