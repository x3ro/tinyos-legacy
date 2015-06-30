/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
module MOPcontrolpM {
  provides {
    interface MateBytecode as BranchIfFalsePreserve;
    interface MateBytecode as BranchIfTruePreserve;
  }
  uses {
    interface MotlleTypes as T;
    interface MotlleStack as S;
    interface MotlleValues as V;
    interface MotlleCode as C;
  }
}
implementation {
  void branch(uint8_t encoding, bool doit, MateContext *context) {
    int16_t offset;

    if (encoding == 0)
      offset = call C.read_offset(context, FALSE);
    else if (encoding == 7)
      offset = call C.read_offset(context, TRUE);
    else
      offset = encoding;

    if (doit)
      context->pc += offset;
  }

  /* Branches that pop if the value is false, don't pop if it's true
     (used to support Scheme's => (in cond) and or constructions
  */
  mvalue preservePop(MateContext *context) {
    mvalue v = call S.get(context, 0);

    if (!call T.truep(v))
      call S.pop(context, 1);

    return v;
  }

  command result_t BranchIfTruePreserve.execute(uint8_t instr, MateContext *context) {
    mvalue v = preservePop(context);
    branch(instr - OP_MBTP3, call T.truep(v), context);
    return SUCCESS;
  }

  command uint8_t BranchIfTruePreserve.byteLength() {
    return 1;
  }

  command result_t BranchIfFalsePreserve.execute(uint8_t instr, MateContext *context) {
    mvalue v = preservePop(context);
    branch(instr - OP_MBFP3, !call T.truep(v), context);
    return SUCCESS;
  }

  command uint8_t BranchIfFalsePreserve.byteLength() {
    return 1;
  }
}

