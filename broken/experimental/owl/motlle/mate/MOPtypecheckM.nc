module MOPtypecheckM {
  provides {
    interface MateBytecode as StackCheck;
    interface MateBytecode as VarCheck;
  }
  uses {
    interface MotlleStack as S;
    interface MotlleTypes as T;
    interface MateError as E;
    interface MotlleVar as LV;
    interface MotlleCode as C;
  }
}
implementation {
  command result_t StackCheck.execute(uint8_t instr, MateContext *context) {
    mvalue v = call S.get(context, 0);

    if (call T.user_type(v) != instr - OP_MSCHECK4)
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t StackCheck.byteLength() {
    return 1;
  }

  command result_t VarCheck.execute(uint8_t instr, MateContext *context) {
    mvalue v = call LV.read(context, call C.read_local_var(context));

    if (call T.user_type(v) != instr - OP_MVCHECK4)
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t VarCheck.byteLength() {
    return 1;
  }
}
