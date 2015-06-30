/* $Id: CC1000SquelchP.nc,v 1.1.2.1 2005/08/07 22:42:34 scipio Exp $
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
 
/**
 * Clear threshold estimation based on RSSI measurements.
 *
 * @author Philip Buonadonna
 * @author Jaein Jeong
 * @author Joe Polastre
 * @author David Gay
 * @author David Moss
 */
  
includes CC1000Const;

module CC1000SquelchM {
  provides {
    interface StdControl;
    interface CC1000Squelch;
  }
}

implementation {

  uint16_t clearThreshold = CC1K_SquelchInit;
  
  uint16_t squelchTable[CC1K_SquelchTableSize];
  
  uint8_t squelchIndex;
  
  uint8_t squelchCount;

  /***************** StdControl Commands ****************/
  command result_t StdControl.init() {
    uint8_t i;

    for (i = 0; i < CC1K_SquelchTableSize; i++) {
      squelchTable[i] = CC1K_SquelchInit;
    }

    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  /***************** CC1000 Squelch Commands ****************/
  async command void CC1000Squelch.adjust(uint16_t data) {
    atomic {
      uint16_t squelchTab[CC1K_SquelchTableSize];
      uint16_t lastMinValue;
      uint8_t i;
      uint8_t j;
      uint8_t minIndex;

      squelchTable[squelchIndex++] = data;
      if (squelchIndex >= CC1K_SquelchTableSize) {
        squelchIndex = 0;
      }
    
      if (squelchCount <= CC1K_SquelchCount) {
        squelchCount++;  
      }
    
      /*
       * Order the entries in our squelch table from quietest
       * to loudest.  If there is a jump from being quiet
       * to being loud, the "loudest" quiet value is our 
       * squelch threshold.  Testing showed there is a difference
       * of around 25-50 in the RSSI value between a quiet and loud
       * threshold.  This is characterized with the (lastMinValue >> 3) 
       * condition, which keeps the threshold between quiet and loud 
       * into proportion.
       */
      memcpy(squelchTab, squelchTable, sizeof(squelchTable));
      lastMinValue = 0;
      for (j = 0; j < CC1K_SquelchTableSize - 1; j++) {
        minIndex = 0;
        for (i = 0; i < CC1K_SquelchTableSize - 1; i++) {
          if (squelchTab[i] > squelchTab[minIndex]) {
            minIndex = i;
          }
        }

        if(j != 0 && squelchTab[minIndex] < lastMinValue - (lastMinValue >> 3)) {
          break;
          
        } else {
          lastMinValue = squelchTab[minIndex];
        }
        
        squelchTab[minIndex] = 0;
      }
      
      clearThreshold = (clearThreshold + lastMinValue) / 2;
    }
  }

  async command uint16_t CC1000Squelch.get() {
    return clearThreshold;
  }

  command bool CC1000Squelch.settled() {
    return squelchCount > CC1K_SquelchCount;
  }
}
