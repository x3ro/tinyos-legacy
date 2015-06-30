module MOParithM {
  provides {
    interface MateBytecode as Arith;
    interface MateBytecode as Unary;
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
    vreal r = 0;

    switch (instr)
      {
      case OP_MADD: r = x + y; break;
      case OP_MSUB: r = x - y; break;
      case OP_MMULTIPLY: r = x * y; break;
      case OP_MDIVIDE:
	if (y == 0)
	  call E.error(context, MOTLLE_ERROR_DIVIDE_BY_ZERO);
	else
	  r = x / y;
	break;
      default: 
	call E.error(context, MOTLLE_ERROR_BAD_TYPE);
	break;
      }
    call S.qpush(context, call T.make_real(r));
    return SUCCESS;
  }

  command result_t Arith.execute(uint8_t instr, MateContext *context) {
    mvalue y = call S.pop(context, 1), x = call S.pop(context, 1);

    if (call T.int_intp(x, y))
      {
	vint ix = call T.intv(x), iy = call T.intv(y), r = 0;

	switch (instr)
	  {
	  case OP_MADD: r = ix + iy; break;
	  case OP_MSUB: r = ix - iy; break;
	  case OP_MMULTIPLY: r = ix * iy; break;
	  case OP_MDIVIDE:
	    if (iy == 0)
	      call E.error(context, MOTLLE_ERROR_DIVIDE_BY_ZERO);
	    else
	      r = ix / iy;
	    break;
	  case OP_MREMAINDER: 
	    if (iy == 0)
	      call E.error(context, MOTLLE_ERROR_DIVIDE_BY_ZERO);
	    else
	      r = ix % iy;
	    break;
	  case OP_MBITAND: r = ix & iy; break;
	  case OP_MBITOR: r = ix | iy; break;
	  case OP_MBITXOR: r = ix ^ iy; break;
	  case OP_MSHIFTLEFT: r = ix << iy; break;
	  case OP_MSHIFTRIGHT: r = ix >> iy; break;
	  default: assert(0);
	  }
	call S.qpush(context, call T.make_int(r));
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

  command uint8_t Arith.byteLength() {
    return 1;
  }

  command result_t Unary.execute(uint8_t instr, MateContext *context) {
    mvalue x = call S.pop(context, 1);

    if (call T.intp(x))
      {
	vint ix = call T.intv(x), r = 0;

	switch (instr)
	  {
	  case OP_MNEGATE: r = -ix; break;
	  case OP_MBITNOT: r = ~ix; break;
	  default: assert(0);
	  }
	call S.qpush(context, call T.make_int(r));
      }
    else if (call T.realp(x) && instr == OP_MNEGATE)
      call S.qpush(context, call T.make_real(-call T.real(x)));
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t Unary.byteLength() {
    return 1;
  }
}
