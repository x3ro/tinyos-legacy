module FNrealM {
  provides {
    interface MateBytecode as FloatP;
    interface MateBytecode as NumberP;
    interface MateBytecode as Floor;
    interface MateBytecode as Ceiling;
    interface MateBytecode as Truncate;
  }
  uses {
    interface MotlleStack as S;
    interface MotlleTypes as T;
    interface MateError as E;
  }
}
implementation {
  //FN floor: r -> i. Return greatest int <= r
  command result_t Floor.execute(uint8_t instr, MateContext *context) {
    mvalue x = call S.pop(context, 1);
    if (call T.realp(x))
      {
	vint ix = floor(call T.real(x));
	call S.qpush(context, call T.make_int(ix));
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t Floor.byteLength() {
    return 1;
  }

  //FN ceiling: r -> i. Return smallest int >= r
  command result_t Ceiling.execute(uint8_t instr, MateContext *context) {
    mvalue x = call S.pop(context, 1);
    if (call T.realp(x))
      {
	vint ix = ceil(call T.real(x));
	call S.qpush(context, call T.make_int(ix));
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t Ceiling.byteLength() {
    return 1;
  }

  //FN truncate: r -> i. Return greatest int (in absolute value) <= r
  command result_t Truncate.execute(uint8_t instr, MateContext *context) {
    mvalue x = call S.pop(context, 1);
    if (call T.realp(x))
      {
	vint ix = call T.real(x);
	call S.qpush(context, call T.make_int(ix));
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t Truncate.byteLength() {
    return 1;
  }

  //FN number?: x -> b. TRUE if x is a number
  command result_t NumberP.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1);
    call S.qpush(context, call T.make_bool(call T.numberp(x)));
    return SUCCESS;
  }

  command uint8_t NumberP.byteLength() {
    return 1;
  }

  //FN float?: x -> b. TRUE if x is a float
  command result_t FloatP.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1);
    call S.qpush(context, call T.make_bool(call T.realp(x)));
    return SUCCESS;
  }

  command uint8_t FloatP.byteLength() {
    return 1;
  }
}
