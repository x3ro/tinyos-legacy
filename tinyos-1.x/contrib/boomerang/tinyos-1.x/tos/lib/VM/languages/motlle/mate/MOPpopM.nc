/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
module MOPpopM {
  provides {
    interface MateBytecode as Pop;
    interface MateBytecode as ExitN;
  }
  uses {
    interface MotlleStack as S;
    interface MotlleCode as C;
  }
}
implementation {
  command result_t Pop.execute(uint8_t instr, MateContext *context) {
    call S.pop(context, 1);
    return SUCCESS;
  }

  command uint8_t Pop.byteLength() {
    return 1;
  }

  command result_t ExitN.execute(uint8_t instr, MateContext *context) {
    call S.pop(context, call C.read_uint8_t(context));
    return SUCCESS;
  }

  command uint8_t ExitN.byteLength() {
    return 1;
  }
}
