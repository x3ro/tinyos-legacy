module MOPneM {
  provides {
    interface MateBytecode as Ne;
  }
  uses {
    interface MotlleStack as S;
    interface MotlleTypes as T;
    interface MateError as E;
  }
}
implementation {
  bool float_eq(mvalue x, mvalue y) {
    return call T.real_intp(x, y) && call T.real(x) == call T.intv(y);
  }

  command result_t Ne.execute(uint8_t instr, MateContext *context) {
    mvalue x = call S.pop(context, 1), y = call S.pop(context, 1);
    bool ne = x != y && !float_eq(x, y) && !float_eq(y, x);
    call S.qpush(context, call T.make_bool(ne));
    return SUCCESS;
  }

  command uint8_t Ne.byteLength() {
    return 1;
  }
}
