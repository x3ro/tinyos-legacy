/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
module MOPnotM {
  provides {
    interface MateBytecode as Not;
  }
  uses {
    interface MotlleStack as S;
    interface MotlleTypes as T;
  }
}
implementation {
  command result_t Not.execute(uint8_t instr, MateContext *context) {
    mvalue x = call S.pop(context, 1);
    call S.qpush(context, call T.make_bool(!call T.truep(x)));
    return SUCCESS;
  }

  command uint8_t Not.byteLength() {
    return 1;
  }
}
