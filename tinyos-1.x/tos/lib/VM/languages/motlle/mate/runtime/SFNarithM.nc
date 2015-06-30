/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
module SFNarithM {
  provides {
    interface MateBytecode as Nlt;
    interface MateBytecode as Nle;
    interface MateBytecode as Ngt;
    interface MateBytecode as Nge;
    interface MateBytecode as Add;
    interface MateBytecode as Subtract;
    interface MateBytecode as Multiply;
    interface MateBytecode as PositiveP;
    interface MateBytecode as NegativeP;
    interface MateBytecode as ZeroP;
    interface MateBytecode as OddP;
    interface MateBytecode as EvenP;
    interface MateBytecode as Or;
    interface MateBytecode as And;
    interface MateBytecode as Xor;
    interface MateBytecode as Quotient;
    interface MateBytecode as SRemainder;
    interface MateBytecode as Modulo;
  }
  uses {
    interface MotlleStack as S;
    interface MotlleTypes as T;
    interface MateError as E;
  }
}
implementation {
  mvalue pop_number(MateContext *context) {
    mvalue x = call S.pop(context, 1);

    if (call T.numberp(x))
      return x;
    call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return call T.make_int(1);
  }

  vint ipop_number(MateContext *context) {
    mvalue x = call S.pop(context, 1);

    if (call T.intp(x))
      return call T.intv(x);
    call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return 1;
  }

  //FN <: n1 n2 -> b. True if n1 < n2
  command result_t Nlt.execute(uint8_t instr, MateContext* context) {
    mvalue y = call S.pop(context, 1);
    mvalue x = call S.pop(context, 1);

    if (call T.int_intp(x, y))
      {
	vint ix = call T.intv(x), iy = call T.intv(y);
	call S.qpush(context, call T.make_bool(ix < iy));
      }
    else if (call T.promotep(x, y))
      {
	vreal rx = call T.number(x), ry = call T.number(y);
	call S.qpush(context, call T.make_bool(rx < ry));
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    
    return SUCCESS;
  }

  command uint8_t Nlt.byteLength() {
    return 1;
  }

  //FN >: n1 n2 -> b. True if n1 > n2
  command result_t Ngt.execute(uint8_t instr, MateContext* context) {
    mvalue y = call S.pop(context, 1);
    mvalue x = call S.pop(context, 1);

    if (call T.int_intp(x, y))
      {
	vint ix = call T.intv(x), iy = call T.intv(y);
	call S.qpush(context, call T.make_bool(ix > iy));
      }
    else if (call T.promotep(x, y))
      {
	vreal rx = call T.number(x), ry = call T.number(y);
	call S.qpush(context, call T.make_bool(rx > ry));
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);

    return SUCCESS;
  }

  command uint8_t Ngt.byteLength() {
    return 1;
  }

  //FN <=: n1 n2 -> b. True if n1 <= n2
  command result_t Nle.execute(uint8_t instr, MateContext* context) {
    mvalue y = call S.pop(context, 1);
    mvalue x = call S.pop(context, 1);

    if (call T.int_intp(x, y))
      {
	vint ix = call T.intv(x), iy = call T.intv(y);
	call S.qpush(context, call T.make_bool(ix <= iy));
      }
    else if (call T.promotep(x, y))
      {
	vreal rx = call T.number(x), ry = call T.number(y);
	call S.qpush(context, call T.make_bool(rx <= ry));
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    
    return SUCCESS;
  }

  command uint8_t Nle.byteLength() {
    return 1;
  }

  //FN >=: n1 n2 -> b. True if n1 >= n2
  command result_t Nge.execute(uint8_t instr, MateContext* context) {
    mvalue y = call S.pop(context, 1);
    mvalue x = call S.pop(context, 1);

    if (call T.int_intp(x, y))
      {
	vint ix = call T.intv(x), iy = call T.intv(y);
	call S.qpush(context, call T.make_bool(ix >= iy));
      }
    else if (call T.promotep(x, y))
      {
	vreal rx = call T.number(x), ry = call T.number(y);
	call S.qpush(context, call T.make_bool(rx >= ry));
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    
    return SUCCESS;
  }

  command uint8_t Nge.byteLength() {
    return 1;
  }

  //FN +: n1 ... -> n. n = n1 + ...
  command result_t Add.execute(uint8_t nargs, MateContext* context) {
    mvalue x = call T.make_int(0);

    while (nargs--)
      {
	mvalue y = pop_number(context);

	if (call T.promotep(x, y))
	  x = call T.make_real(call T.number(x) + call T.number(y));
	else
	  x = call T.make_int(call T.intv(x) + call T.intv(y));
      }
    call S.qpush(context, x);

    return SUCCESS;
  }

  command uint8_t Add.byteLength() {
    return 1;
  }

  //FN *: n1 ... -> n. n = n1 * ...
  command result_t Multiply.execute(uint8_t nargs, MateContext* context) {
    mvalue x = call T.make_int(1);

    while (nargs--)
      {
	mvalue y = pop_number(context);

	if (call T.promotep(x, y))
	  x = call T.make_real(call T.number(x) * call T.number(y));
	else
	  x = call T.make_int(call T.intv(x) * call T.intv(y));
      }
    call S.qpush(context, x);


    return SUCCESS;
  }

  command uint8_t Multiply.byteLength() {
    return 1;
  }

  //FN -: n1 ... -> n. n = n1 - n2 or n = -n1
  command result_t Subtract.execute(uint8_t nargs, MateContext* context) {
    if (nargs == 1)
      {
	mvalue x = pop_number(context);

	if (call T.realp(x))
	  call S.qpush(context, call T.make_real(-call T.real(x)));
	else
	  call S.qpush(context, call T.make_int(-call T.intv(x)));
      }
    else if (nargs == 2)
      {
	mvalue y = call S.pop(context, 1);
	mvalue x = call S.pop(context, 1);

	if (call T.int_intp(x, y))
	  {
	    vint ix = call T.intv(x), iy = call T.intv(y);
	    call S.qpush(context, call T.make_int(ix - iy));
	  }
	else if (call T.promotep(x, y))
	  {
	    vreal rx = call T.number(x), ry = call T.number(y);
	    call S.qpush(context, call T.make_real(rx - ry));
	  }
	else
	  call E.error(context, MOTLLE_ERROR_BAD_TYPE);
      }
    else
      call E.error(context, MOTLLE_ERROR_WRONG_PARAMETERS);
    return SUCCESS;
  }

  command uint8_t Subtract.byteLength() {
    return 1;
  }

  //FN |: n1 ... -> n. n = n1 | ...
  command result_t Or.execute(uint8_t nargs, MateContext* context) {
    if (nargs < 1)
      call E.error(context, MOTLLE_ERROR_WRONG_PARAMETERS);
    else
      {
	vint x = ipop_number(context);

	while (--nargs)
	  x |= ipop_number(context);
	call S.qpush(context, call T.make_int(x));
      }

    return SUCCESS;
  }

/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
  command uint8_t Or.byteLength() {
    return 1;
  }

  //FN &: n1 ... -> n. n = n1 & ...
  command result_t And.execute(uint8_t nargs, MateContext* context) {
    if (nargs < 1)
      call E.error(context, MOTLLE_ERROR_WRONG_PARAMETERS);
    else
      {
	vint x = ipop_number(context);

	while (--nargs)
	  x &= ipop_number(context);
	call S.qpush(context, call T.make_int(x));
      }
    return SUCCESS;
  }

  command uint8_t And.byteLength() {
    return 1;
  }

  //FN ^: n1 ... -> n. n = n1 ^ ...
  command result_t Xor.execute(uint8_t nargs, MateContext* context) {
    if (nargs < 1)
      call E.error(context, MOTLLE_ERROR_WRONG_PARAMETERS);
    else
      {
	vint x = ipop_number(context);

	while (--nargs)
	  x ^= ipop_number(context);
	call S.qpush(context, call T.make_int(x));
      }
    return SUCCESS;
  }

  command uint8_t Xor.byteLength() {
    return 1;
  }

  //FN odd?: n -> b. True if n is odd
  command result_t OddP.execute(uint8_t nargs, MateContext* context) {
    call S.qpush(context, call T.make_bool(ipop_number(context) & 1));
    return SUCCESS;
  }

  command uint8_t OddP.byteLength() {
    return 1;
  }

  //FN even?: n -> b. True if n is even
  command result_t EvenP.execute(uint8_t nargs, MateContext* context) {
    call S.qpush(context, call T.make_bool(!(ipop_number(context) & 1)));
    return SUCCESS;
  }

  command uint8_t EvenP.byteLength() {
    return 1;
  }

  //FN zero?: n -> b. True if n is zero
  command result_t ZeroP.execute(uint8_t nargs, MateContext* context) {
    mvalue x = call S.pop(context, 1);

    if (call T.intp(x))
      call S.qpush(context, call T.make_bool(call T.intv(x) == 0));
    else if (call T.realp(x))
      call S.qpush(context, call T.make_bool(call T.real(x) == 0));
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t ZeroP.byteLength() {
    return 1;
  }

  //FN positive?: n -> b. True if n is positive
  command result_t PositiveP.execute(uint8_t nargs, MateContext* context) {
    mvalue x = call S.pop(context, 1);

    if (call T.intp(x))
      call S.qpush(context, call T.make_bool(call T.intv(x) > 0));
    else if (call T.realp(x))
      call S.qpush(context, call T.make_bool(call T.real(x) > 0));
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t PositiveP.byteLength() {
    return 1;
  }

  //FN negative?: n -> b. True if n is negative
  command result_t NegativeP.execute(uint8_t nargs, MateContext* context) {
    mvalue x = call S.pop(context, 1);

    if (call T.intp(x))
      call S.qpush(context, call T.make_bool(call T.intv(x) < 0));
    else if (call T.realp(x))
      call S.qpush(context, call T.make_bool(call T.real(x) < 0));
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t NegativeP.byteLength() {
    return 1;
  }

  // Assuming that /, % round towards zero

  //FN quotient: n1 n2 -> n3. n3 = integer division of n1, n2
  command result_t Quotient.execute(uint8_t nargs, MateContext* context) {
    mvalue y = call S.pop(context, 1);
    mvalue x = call S.pop(context, 1);

    if (call T.int_intp(x, y))
      {
	vint ix = call T.intv(x), iy = call T.intv(y);

	if (iy == 0)
	  call E.error(context, MOTLLE_ERROR_DIVIDE_BY_ZERO);
	else
	  call S.qpush(context, call T.make_int(ix / iy));
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    
    return SUCCESS;
  }

  command uint8_t Quotient.byteLength() {
    return 1;
  }

  //FN remainder: n1 n2 -> n3. n3 = integer division of n1, n2
  command result_t SRemainder.execute(uint8_t nargs, MateContext* context) {
    mvalue y = call S.pop(context, 1);
    mvalue x = call S.pop(context, 1);

    if (call T.int_intp(x, y))
      {
	vint ix = call T.intv(x), iy = call T.intv(y);

	if (iy == 0)
	  call E.error(context, MOTLLE_ERROR_DIVIDE_BY_ZERO);
	else
	  call S.qpush(context, call T.make_int(ix % iy));
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    
    return SUCCESS;
  }

  command uint8_t SRemainder.byteLength() {
    return 1;
  }

  //FN modulo: n1 n2 -> n3. n3 = integer division of n1, n2
  command result_t Modulo.execute(uint8_t nargs, MateContext* context) {
    mvalue y = call S.pop(context, 1);
    mvalue x = call S.pop(context, 1);

    if (call T.int_intp(x, y))
      {
	vint ix = call T.intv(x), iy = call T.intv(y);

	if (iy == 0)
	  call E.error(context, MOTLLE_ERROR_DIVIDE_BY_ZERO);
	else
	  {
	    vint r = ix % iy;

	    if ((r < 0 && iy > 0) || (r > 0 && iy < 0))
	      r += iy;
	    call S.qpush(context, call T.make_int(r));
	  }
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    
    return SUCCESS;
  }

  command uint8_t Modulo.byteLength() {
    return 1;
  }

}
