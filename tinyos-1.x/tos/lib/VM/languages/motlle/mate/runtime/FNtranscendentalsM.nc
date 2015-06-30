/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
module FNtranscendentalsM {
  provides {
    interface MateBytecode as Sqrt;
    interface MateBytecode as Sin;
    interface MateBytecode as Cos;
    interface MateBytecode as Tan;
    interface MateBytecode as Asin;
    interface MateBytecode as Acos;
    interface MateBytecode as Atan;
    interface MateBytecode as Exp;
    interface MateBytecode as Log;
    interface MateBytecode as Expt;
  }
  uses {
    interface MotlleStack as S;
    interface MotlleTypes as T;
    interface MateError as E;
  }
}
implementation {
#define TRANS(name, op) \
  { \
    mvalue x = call S.pop(context, 1); \
    if (call T.numberp(x)) \
      {
	vreal r = op(call T.number(x)); \
	call S.qpush(context, call T.make_real(r)); \
      } \
    else \
      call E.error(context, MOTLLE_ERROR_BAD_TYPE); \
    return SUCCESS; \
  }
 \
  command uint8_t name.byteLength() { \
    return 1; \
  }

  //FN sqrt: r1 -> r2. Return sqrt(r1)
  command result_t Sqrt.execute(uint8_t instr, MateContext *context) 
    TRANS(Sqrt, sqrt)

  //FN sin: r1 -> r2. Return sin(r1)
  command result_t Sin.execute(uint8_t instr, MateContext *context) 
    TRANS(Sin, sin)

  //FN cos: r1 -> r2. Return cos(r1)
  command result_t Cos.execute(uint8_t instr, MateContext *context) 
    TRANS(Cos, cos)

  //FN tan: r1 -> r2. Return tan(r1)
  command result_t Tan.execute(uint8_t instr, MateContext *context) 
    TRANS(Tan, tan)

  //FN asin: r1 -> r2. Return asin(r1)
  command result_t Asin.execute(uint8_t instr, MateContext *context) 
    TRANS(Asin, asin)

  //FN acos: r1 -> r2. Return acos(r1)
  command result_t Acos.execute(uint8_t instr, MateContext *context) 
    TRANS(Acos, acos)

  //FN exp: r1 -> r2. Return exp(r1)
  command result_t Exp.execute(uint8_t instr, MateContext *context) 
    TRANS(Exp, exp)

  //FN log: r1 -> r2. Return log(r1)
  command result_t Log.execute(uint8_t instr, MateContext *context) 
    TRANS(Log, log)


  //FN expt: r1 r2 -> r3. r3 = r1 raised to the r2'th power
  command result_t Expt.execute(uint8_t instr, MateContext *context) {
    mvalue y = call S.pop(context, 1);
    mvalue x = call S.pop(context, 1);

    if (call T.numberp(x) && call T.numberp(y))
      {
	vreal r = pow(call T.number(x), call T.number(y));
	call S.qpush(context, call T.make_real(r));
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t Expt.byteLength() {
    return 1;
  }

  //FN atan: r1 ... -> r3. r3 = atan(r1) or r3 = atan(r2/r1)
  command result_t Atan.execute(uint8_t nargs, MateContext *context) {
    vreal result = 0;

    if (nargs == 1)
      {
	mvalue x = call S.pop(context, 1);

	if (call T.numberp(x))
	  result = atan(call V.number(x));
	else
	  call E.error(context, MOTLLE_ERROR_BAD_TYPE);
      }
    else if (nargs == 2)
      {
	mvalue x = call S.pop(context, 1);
	mvalue y = call S.pop(context, 1);

	if (call T.numberp(x) && call T.numberp(y))
	  result = atan2(call V.number(y), call V.number(x));
	else
	  call E.error(context, MOTLLE_ERROR_BAD_TYPE);
      }
    else
      call E.error(context, MOTLLE_ERROR_WRONG_PARAMETERS);

    call S.qpush(context, call T.make_real(r));

    return SUCCESS;
  }

  command uint8_t Atan.byteLength() {
    return 1;
  }
}
