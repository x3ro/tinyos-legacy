/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
module SFNrealM {
  provides interface Divide;
  uses {
    interface MotlleStack as S;
    interface MotlleTypes as T;
    interface MateError as E;
  }
}
implementation {
  vreal fpop_number(MateContext *context) {
    mvalue x = call S.pop(context, 1);

    if (call T.numberp(x))
      return call T.number(x);
    call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return 1;
  }

  //FN /: n1 n2 -> n. n = n1 / n2
  command result_t Divide.execute(uint8_t instr, MateContext* context) {
    if (nargs == 1)
      {
	vreal x = fpop_number(context);

	if (x == 0)
	  call E.error(context, MOTLLE_ERROR_DIVIDE_BY_ZERO);
	else
	  call S.qpush(context, call T.make_real(1 / x));
      }
    else if (nargs == 2)
      {
	vreal y = fpop_number(context);
	vreal x = fpop_number(context);

	if (y == 0)
	  call E.error(context, MOTLLE_ERROR_DIVIDE_BY_ZERO);
	else
	  call S.qpush(context, call T.make_real(x / y));
      }
    return SUCCESS;
  }

  command uint8_t Divide.byteLength() {
    return 1;
  }

}
