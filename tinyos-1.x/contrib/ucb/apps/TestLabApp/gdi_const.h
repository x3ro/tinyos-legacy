/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
//  61440 = 1 min
// 122880 = 2 min
// 184320 = 3 min
// 245760 = 4 min
// 307200 = 5 min
// 614400 = 10 min

enum {
  NETWORK_UPDATE_SLOW = 614400,
  NETWORK_UPDATE_FAST = 10240,
  NETWORK_UPDATE_FAST_TIMEOUT = 614400
};

enum {
  RF_POWER_LEVEL = 0x0B
};

enum {
  MAX_STATES = CC1K_LPL_STATES - 1,
  OFF_MODE = MAX_STATES - 1,
  ON_MODE = 0
};

enum {
  DEFAULT_TIME_MIN = 5,
  DEFAULT_TIME_SEC = 0
};

enum {
  WAIT_TIME_MS     = 1024,
  WAIT_TIMEOUT     = 7
};

  enum {
    HAMAMATSU_MASK = 0x01,
    MELEXIS_MASK = 0x01,
    HUMIDITY_MASK = 0x02,
    PRESSURE_MASK = 0x04,
    TAOS_MASK = 0x08,
    TOTAL_MASK = 0x0F,
    TOTAL_MASK_B = 0x03
  };

