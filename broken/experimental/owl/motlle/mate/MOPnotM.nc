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
