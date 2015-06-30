/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
module FNstringM {
  provides {
    interface MateBytecode as StringP;
    interface MateBytecode as String;
    interface MateBytecode as MakeString;
    interface MateBytecode as StringLength;
    interface MateBytecode as StringFillB;
  }
  uses {
    interface MotlleStack as S;
    interface MotlleTypes as T;
    interface MateError as E;
  }
}
implementation {
  //FN string?: x -> b. TRUE if x is a string
  command result_t StringP.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1);
    call S.qpush(context, call T.make_bool(call T.stringp(x)));
    return SUCCESS;
  }

  command uint8_t StringP.byteLength() {
    return 1;
  }

  //FN make-string: i -> s. Create an empty string of length i
  command result_t MakeString.execute(uint8_t instr, MateContext* context) {
    mvalue n = call S.pop(context, 1);

    if (call T.intp(n))
      {
	vstring v = call T.alloc_string(call T.intv(n));
	if (v)
	  call S.push(context, call T.make_string(v));
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t MakeString.byteLength() {
    return 1;
  }

  //FN string-length: s -> i. Return length of string
  command result_t StringLength.execute(uint8_t instr, MateContext* context) {
    mvalue v = call S.pop(context, 1);

    if (call T.stringp(v))
      call S.qpush(context, call T.make_int(call T.string_length(call T.string(v))));
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t StringLength.byteLength() {
    return 1;
  }

  //FN string-fill!: s i -> . Set all characters of s to i
  command result_t StringFillB.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1);
    mvalue s = call S.pop(context, 1);

    if (call T.stringp(s) && call T.intp(x))
      {
	vstring vs = call T.string(s);
	msize len = call T.string_length(vs);
	vint ix = call T.intv(x);

	while (len-- > 0)
	  vs->str[len] = ix;
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t StringFillB.byteLength() {
    return 1;
  }

  //FN string: n1 ... -> v. Returns a string of its character arguments
  command result_t String.execute(uint8_t nargs, MateContext* context) {
    vstring s = call T.alloc_string(nargs);

    if (s)
      {
	while (nargs-- > 0)
	  s->str[nargs] = call T.intv(call S.pop(context, 1));
	call S.push(context, call T.make_string(s));
      }

    return SUCCESS;
  }

  command uint8_t String.byteLength() {
    return 1;
  }
}
