module MOPcontrolM {
  provides {
    interface MateBytecode as Branch;
    interface MateBytecode as BranchIfFalse;
    interface MateBytecode as BranchIfTrue;
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

  command result_t Branch.execute(uint8_t instr, MateContext *context) {
    branch(instr - OP_MBA3, TRUE, context);
    return SUCCESS;
  }

  command uint8_t Branch.byteLength() {
    return 1;
  }

  command result_t BranchIfTrue.execute(uint8_t instr, MateContext *context) {
    mvalue v = call S.pop(context, 1);
    branch(instr - OP_MBT3, call T.truep(v), context);
    return SUCCESS;
  }

  command uint8_t BranchIfTrue.byteLength() {
    return 1;
  }

  command result_t BranchIfFalse.execute(uint8_t instr, MateContext *context) {
    mvalue v = call S.pop(context, 1);
    branch(instr - OP_MBF3, !call T.truep(v), context);
    return SUCCESS;
  }

  command uint8_t BranchIfFalse.byteLength() {
    return 1;
  }
}

