module FNarithM {
  provides {
    interface MateBytecode as IntegerP;
    interface MateBytecode as Max;
    interface MateBytecode as Min;
    interface MateBytecode as Abs;
  }
  uses {
    interface MotlleStack as S;
    interface MotlleTypes as T;
    interface MateError as E;
  }
}
implementation {
  //FN max: n1 n2 -> n. n = max(n1, n2)
  command result_t Max.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1), y = call S.pop(context, 1);

    if (call T.int_intp(x, y))
      {
	vint ix = call T.intv(x), iy = call T.intv(y);
	call S.qpush(context, call T.make_int(ix > iy ? ix : iy));
      }
    else if (call T.promotep(x, y))
      {
	vreal rx = call T.real(x), ry = call T.real(y);
	call S.qpush(context, call T.make_real(rx > ry ? rx : ry));
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t Max.byteLength() {
    return 1;
  }

  //FN min: n1 n2 -> n. n = min(n1, n2)
  command result_t Min.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1), y = call S.pop(context, 1);

    if (call T.int_intp(x, y))
      {
	vint ix = call T.intv(x), iy = call T.intv(y);
	call S.qpush(context, call T.make_int(ix < iy ? ix : iy));
      }
    else if (call T.promotep(x, y))
      {
	vreal rx = call T.real(x), ry = call T.real(y);
	call S.qpush(context, call T.make_real(rx < ry ? rx : ry));
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t Min.byteLength() {
    return 1;
  }

  //FN abs: n1 -> n2. n2 = |n1|
  command result_t Abs.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1);

    if (call T.intp(x))
      {
	vint ix = call T.intv(x);
	call S.qpush(context, call T.make_int(ix < 0 ? -ix : ix));
      }
    else if (call T.realp(x))
      {
	vreal rx = call T.real(x);
	call S.qpush(context, call T.make_int(rx < 0 ? -rx : rx));
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t Abs.byteLength() {
    return 1;
  }

  //FN integer?: x -> b. TRUE if x is an integer
  command result_t IntegerP.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1);
    call S.qpush(context, call T.make_bool(call T.intp(x)));
    return SUCCESS;
  }

  command uint8_t IntegerP.byteLength() {
    return 1;
  }
}
