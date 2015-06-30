/* $Id: FormatM.nc,v 1.1 2005/07/11 23:27:38 idgay Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * @author David Gay
 */
module FormatM {
  provides interface StdControl;
  uses {
    interface Leds;
    interface FormatStorage;
  }
}
implementation {
  command result_t StdControl.init() {
    call Leds.init();
    return SUCCESS;
  }

  void rcheck(result_t ok) {
    if (ok == FAIL)
      call Leds.redOn();
  }

  command result_t StdControl.start() {
    call Leds.yellowOn();

    call FormatStorage.init();

    rcheck(call FormatStorage.allocateFixed(11, 0, 256));
    rcheck(!call FormatStorage.allocateFixed(22, 65536L, 1025));
    rcheck(!call FormatStorage.allocateFixed(22, 65534L, 1024));
    rcheck(call FormatStorage.allocateFixed(22, 65536L, 1024));
    rcheck(call FormatStorage.allocateFixed(12, 1024, 32768L));
    rcheck(call FormatStorage.allocate(1, 262144L));
    rcheck(!call FormatStorage.allocate(2, 262144L));
    rcheck(!call FormatStorage.allocate(1, 256));
    rcheck(call FormatStorage.commit());

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event void FormatStorage.commitDone(storage_result_t result) {
    if (result == STORAGE_OK)
      call Leds.greenOn();
    else
      call Leds.redOn();
  }
}
