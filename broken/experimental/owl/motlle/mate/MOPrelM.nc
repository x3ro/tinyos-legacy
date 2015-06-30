module MOPrelM {
  provides {
    interface MateBytecode as Rel;
  }
  uses {
    interface MotlleStack as S;
    interface MotlleTypes as T;
    interface MateError as E;
  }
#include "massert.h"
}
implementation {
  result_t floatOp(uint8_t instr, vreal x, vreal y, MateContext *context) {
    bool r;

    switch (instr)
      {
      case OP_MLT: r = x < y; break;
      case OP_MLE: r = x <= y; break;
      case OP_MGT: r = x > y; break;
      case OP_MGE: r = x >= y; break;
      default: assert(0); r = 0; break;
      }
    call S.qpush(context, call T.make_bool(r));
    return SUCCESS;
  }

  command result_t Rel.execute(uint8_t instr, MateContext *context) {
    mvalue y = call S.pop(context, 1), x = call S.pop(context, 1);

    if (call T.int_intp(x, y))
      {
	vint ix = call T.intv(x), iy = call T.intv(y);
	bool r;

	switch (instr)
	  {
	  case OP_MLT: r = ix < iy; break;
	  case OP_MLE: r = ix <= iy; break;
	  case OP_MGT: r = ix > iy; break;
	  case OP_MGE: r = ix >= iy; break;
	  default: assert(0); r = 0; break;
	  }
	call S.qpush(context, call T.make_bool(r));
	return SUCCESS;
      }
    else if (call T.real_realp(x, y))
      return floatOp(instr, call T.real(x), call T.real(y), context);
    else if (call T.real_intp(x, y))
      return floatOp(instr, call T.real(x), call T.intv(y), context);
    else if (call T.real_intp(y, x))
      return floatOp(instr, call T.intv(x), call T.real(y), context);

    call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t Rel.byteLength() {
    return 1;
  }
}
