// $Id: FormatM.nc,v 1.4 2005/07/28 19:34:34 jwhui Exp $

/*									tab:2
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
 */

/*
 * @author: Jonathan Hui <jwhui@cs.berkeley.edu>
 */

module FormatM {
  provides {
    interface StdControl;
  }
  uses {
    interface FormatStorage;
    interface Leds;
    interface Timer;
  }
}

implementation {

  command result_t StdControl.init() {
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Timer.start(TIMER_ONE_SHOT, 1024);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t Timer.fired() {

    result_t result;

    call Leds.set(4);

    result = call FormatStorage.init();

    /* we need perhaps 6 deluge image slots */
    result = rcombine(call FormatStorage.allocate(0xD0, STORAGE_BLOCK_SIZE), result);
    result = rcombine(call FormatStorage.allocate(0xD1, STORAGE_BLOCK_SIZE), result);
    result = rcombine(call FormatStorage.allocate(0xD2, STORAGE_BLOCK_SIZE), result);
    result = rcombine(call FormatStorage.allocate(0xD3, STORAGE_BLOCK_SIZE), result);
    result = rcombine(call FormatStorage.allocate(0xD4, STORAGE_BLOCK_SIZE), result);
    result = rcombine(call FormatStorage.allocate(0xD5, STORAGE_BLOCK_SIZE), result);
    result = rcombine(call FormatStorage.allocate(0xD6, STORAGE_BLOCK_SIZE), result);

    /* we need 1 slot for the golden image (in protected flash) */
    result = rcombine(call FormatStorage.allocateFixed(0xDF, 0xF0000, STORAGE_BLOCK_SIZE), result);

    /* The other 9 slots we will format for data logging */
    result = rcombine(call FormatStorage.allocate(0x00, STORAGE_BLOCK_SIZE), result);
    result = rcombine(call FormatStorage.allocate(0x01, STORAGE_BLOCK_SIZE), result);
    result = rcombine(call FormatStorage.allocate(0x02, STORAGE_BLOCK_SIZE), result);
    result = rcombine(call FormatStorage.allocate(0x03, STORAGE_BLOCK_SIZE), result);
    result = rcombine(call FormatStorage.allocate(0x04, STORAGE_BLOCK_SIZE), result);
    result = rcombine(call FormatStorage.allocate(0x05, STORAGE_BLOCK_SIZE), result);
    result = rcombine(call FormatStorage.allocate(0x06, STORAGE_BLOCK_SIZE), result);
    result = rcombine(call FormatStorage.allocate(0x07, STORAGE_BLOCK_SIZE), result);

    result = rcombine(call FormatStorage.commit(), result);

    if (result != SUCCESS)
      call Leds.set(1);

    return SUCCESS;

  }

  event void FormatStorage.commitDone(storage_result_t result) {
    if (result == STORAGE_OK)
      call Leds.set(2);
    else
      call Leds.set(1);
  }

}
