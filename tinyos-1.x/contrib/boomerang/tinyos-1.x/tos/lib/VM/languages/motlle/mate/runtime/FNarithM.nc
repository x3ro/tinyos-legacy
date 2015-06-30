/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
module FNarithM {
  provides {
    interface MateBytecode as IntegerP;
    interface MateBytecode as NumberP;
    interface MateBytecode as RealP;
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
  mvalue pop_number(MateContext *context) {
    mvalue x = call S.pop(context, 1);

    if (call T.numberp(x))
      return x;
    call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return call T.make_int(1);
  }

  //FN max: n1 n2 ... -> n. n = max(n1, n2, ...)
  command result_t Max.execute(uint8_t nargs, MateContext* context) {
    if (nargs < 1)
      call E.error(context, MOTLLE_ERROR_WRONG_PARAMETERS);
    else
      {
	mvalue x = pop_number(context);

	while (--nargs)
	  {
	    mvalue y = pop_number(context);

	    if (call T.int_intp(x, y))
	      {
		if (call T.intv(y) > call T.intv(x))
		  x = y;
	      }
	    else
	      {
		if (call T.number(y) > call T.number(x))
		  x = y;
	      }
	  }
	call S.qpush(context, x);
      }
    return SUCCESS;
  }

  command uint8_t Max.byteLength() {
    return 1;
  }

  //FN min: n1 n2 ... -> n. n = min(n1, n2, ...)
  command result_t Min.execute(uint8_t nargs, MateContext* context) {
    if (nargs < 1)
      call E.error(context, MOTLLE_ERROR_WRONG_PARAMETERS);
    else
      {
	mvalue x = pop_number(context);

	while (--nargs)
	  {
	    mvalue y = pop_number(context);

	    if (call T.int_intp(x, y))
	      {
		if (call T.intv(y) < call T.intv(x))
		  x = y;
	      }
	    else
	      {
		if (call T.number(y) < call T.number(x))
		  x = y;
	      }
	  }
	call S.qpush(context, x);
      }
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

  //FN number?: x -> b. TRUE if x is a number
  command result_t NumberP.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1);
    call S.qpush(context, call T.make_bool(call T.numberp(x)));
    return SUCCESS;
  }

  command uint8_t NumberP.byteLength() {
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

  //FN real?: x -> b. TRUE if x is a number
  command result_t RealP.execute(uint8_t instr, MateContext* context) {
    return call NumberP.execute(instr, context);
  }

  command uint8_t RealP.byteLength() {
    return 1;
  }
}
