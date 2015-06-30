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
/**
 *
 * Revision:	$Id: SerialId.nc,v 1.1.1.1 2007/11/05 19:10:11 jpolastre Exp $
 *
 * The mica2dot platform does not have a DS2401, nor does it have a SERIAL_ID pin.  
 * This is a dummy module that acts as a placeholder so applications can compile.
 * It DOES NOT return a unique serial ID.
 */

module SerialId {
  provides interface StdControl;
  provides interface HardwareId;
}

implementation {
  bool gfReadBusy;
  uint8_t *serialId;

#warning "SERIALID NOT SUPPORTED ON MICA2DOT PLATFORM!"
  command result_t StdControl.init() {
    gfReadBusy = FALSE;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  task void serialIdRead() {
    uint8_t i;

    for (i = 0; i < HARDWARE_ID_LEN; i++) {
      serialId[i] = 0xff;
    }

    signal HardwareId.readDone(serialId, FALSE);

  }
  
  command result_t HardwareId.read(uint8_t *id) {
    if (!gfReadBusy) {
      gfReadBusy = TRUE;
      serialId = id;
      post serialIdRead();
      return SUCCESS;
    }
    return FAIL;
  }
  
}
