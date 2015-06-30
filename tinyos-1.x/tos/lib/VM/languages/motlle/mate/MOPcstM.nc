/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
module MOPcstM {
  provides {
    interface MateBytecode as Cst;
    interface MateBytecode as Int;
    interface MateBytecode as Undefined;
  }
  uses {
    interface MotlleStack as S;
    interface MotlleTypes as T;
    interface MotlleCode as C;
  }
}
implementation {
  command result_t Cst.execute(uint8_t instr, MateContext* context) {
    call S.push(context, call C.read_value(context));
    return SUCCESS;
  }

  command uint8_t Cst.byteLength() {
    return 1;
  }

  command result_t Int.execute(uint8_t instr, MateContext* context) {
    call S.push(context, call T.make_int(instr - OP_MINT3));
    return SUCCESS;
  }

  command uint8_t Int.byteLength() {
    return 1;
  }

  command result_t Undefined.execute(uint8_t instr, MateContext* context) {
    call S.push(context, call T.make_int(42));
    return SUCCESS;
  }

  command uint8_t Undefined.byteLength() {
    return 1;
  }
}
