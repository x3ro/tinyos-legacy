/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
module MOPeqM {
  provides {
    interface MateBytecode as Eq;
  }
  uses {
    interface MotlleStack as S;
    interface MotlleTypes as T;
  }
}
implementation {
  bool float_eq(mvalue x, mvalue y) {
    return call T.real_intp(x, y) && call T.real(x) == call T.intv(y);
  }

  command result_t Eq.execute(uint8_t instr, MateContext *context) {
    mvalue x = call S.pop(context, 1), y = call S.pop(context, 1);
    bool eq = x == y || float_eq(x, y) || float_eq(y, x);
    call S.qpush(context, call T.make_bool(eq));
    return SUCCESS;
  }

  command uint8_t Eq.byteLength() {
    return 1;
  }
}
