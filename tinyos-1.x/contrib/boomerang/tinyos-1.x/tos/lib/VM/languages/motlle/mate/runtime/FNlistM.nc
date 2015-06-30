/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
module FNlistM {
  provides {
    interface MateBytecode as Cons;
    interface MateBytecode as PairP;
    interface MateBytecode as ListP;
    interface MateBytecode as NullP;
    interface MateBytecode as SetCarB;
    interface MateBytecode as SetCdrB;
    interface MateBytecode as List;
    interface MateBytecode as ListTail;
    interface MateBytecode as ListRef;
    interface MateBytecode as Car;
    interface MateBytecode as Cdr;
    interface MateBytecode as Caar;
    interface MateBytecode as Cadr;
    interface MateBytecode as Cdar;
    interface MateBytecode as Cddr;
    interface MateBytecode as Caaar;
    interface MateBytecode as Caadr;
    interface MateBytecode as Cadar;
    interface MateBytecode as Caddr;
    interface MateBytecode as Cdaar;
    interface MateBytecode as Cdadr;
    interface MateBytecode as Cddar;
    interface MateBytecode as Cdddr;
  }
  uses {
    interface MotlleGC as GC;
    interface MotlleStack as S;
    interface MotlleTypes as T;
    interface MotlleValues as V;
    interface MateError as E;
  }
}
implementation {
  //FN cons: x1 x2 -> l. Make a new pair from elements x1 & x2
  command result_t Cons.execute(uint8_t instr, MateContext* context) {
    mvalue x2 = call S.pop(context, 1), x1 = call S.pop(context, 1);
    vpair pair;

    pair = call T.alloc_list(x1, x2);
    if (pair)
      // can't use qpush because we've called alloc_list
      call S.push(context, call T.make_pair(pair));
    return SUCCESS;
  }

  command uint8_t Cons.byteLength() {
    return 1;
  }

  //FN pair?: x -> b. TRUE if x is a pair
  command result_t PairP.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1);
    call S.qpush(context, call T.make_bool(call T.pairp(x)));
    return SUCCESS;
  }

  command uint8_t PairP.byteLength() {
    return 1;
  }

  //FN list?: x -> b. TRUE if x is a pair or null
  command result_t ListP.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1);
    call S.qpush(context, call T.make_bool(call T.listp(x)));
    return SUCCESS;
  }

  command uint8_t ListP.byteLength() {
    return 1;
  }

  //FN null?: x -> b. TRUE if x is null
  command result_t NullP.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1);
    call S.qpush(context, call T.make_bool(call T.nullp(x)));
    return SUCCESS;
  }

  command uint8_t NullP.byteLength() {
    return 1;
  }

  //FN set-car!: l x ->. Sets the first element of pair l to x
  command result_t SetCarB.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1);
    mvalue l = call S.pop(context, 1);

    if (call T.pairp(l))
      {
	vpair p = call T.pair(l);

	if (call GC.mutable(p)) 
	  call V.write(&p->car, x);
	else
	  call E.error(context, MOTLLE_ERROR_VALUE_READ_ONLY);
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t SetCarB.byteLength() {
    return 1;
  }

  //FN set-cdr!: l x ->. Sets the first element of pair l to x
  command result_t SetCdrB.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1);
    mvalue l = call S.pop(context, 1);

    if (call T.pairp(l))
      {
	vpair p = call T.pair(l);

	if (call GC.mutable(p)) 
	  call V.write(&p->cdr, x);
	else
	  call E.error(context, MOTLLE_ERROR_VALUE_READ_ONLY);
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t SetCdrB.byteLength() {
    return 1;
  }

  //FN list: x1 ... -> l. Returns a list of the arguments
  command result_t List.execute(uint8_t nargs, MateContext* context) {
    mvalue l = call T.nil();

    while (nargs-- > 0)
      {
	vpair p = call T.alloc_list(call S.pop(context, 1), l);

	if (!p)
	  return SUCCESS;
	l = call T.make_pair(p);
      }
    call S.push(context, l);

    return SUCCESS;
  }

  command uint8_t List.byteLength() {
    return 1;
  }

  //FN list-tail: l1 n -> l2. Returns the nth cdr of l2
  command result_t ListTail.execute(uint8_t nargs, MateContext* context) {
    mvalue mn = call S.pop(context, 1);
    mvalue l = call S.pop(context, 1);

    if (call T.intp(mn))
      {
	vint n = call T.intv(mn);

	if (n < 0)
	  call E.error(context, MOTLLE_ERROR_BAD_VALUE);
	while (n-- > 0)
	  {
	    if (!call T.pairp(l))
	      {
		call E.error(context, MOTLLE_ERROR_BAD_VALUE);
		return SUCCESS;
	      }
	    l = call V.read(&(call T.pair(l))->cdr);
	  }
	call S.qpush(context, l);
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);

    return SUCCESS;
  }

  command uint8_t ListTail.byteLength() {
    return 1;
  }

  //FN list-ref: l1 n -> l2. Returns the nth car of l2
  command result_t ListRef.execute(uint8_t nargs, MateContext* context) {
    mvalue mn = call S.pop(context, 1);
    mvalue l = call S.pop(context, 1);

    if (call T.intp(mn))
      {
	vint n = call T.intv(mn);

	if (n < 0)
	  call E.error(context, MOTLLE_ERROR_BAD_VALUE);
	else
	  for (;;)
	    {
	      vpair p;

	      if (!call T.pairp(l))
		{
		  call E.error(context, MOTLLE_ERROR_BAD_VALUE);
		  return SUCCESS;
		}
	      p = call T.pair(l);
	      if (n-- == 0)
		{
		  call S.qpush(context, call V.read(&p->car));
		  return SUCCESS;
		}
	      else
		l = call V.read(&p->cdr);
	    }
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);

    return SUCCESS;
  }

  command uint8_t ListRef.byteLength() {
    return 1;
  }

#define CAR(l) if (!call T.pairp(l)) goto bad; l = call V.read(&(call T.pair(l))->car)
#define CDR(l) if (!call T.pairp(l)) goto bad; l = call V.read(&(call T.pair(l))->cdr)
#define PUSH(l) call S.qpush(context, l); return SUCCESS; bad: call E.error(context, MOTLLE_ERROR_BAD_TYPE); return SUCCESS

  //FN car: l -> x. Returns first element of pair l
  command result_t Car.execute(uint8_t instr, MateContext* context) {
    mvalue l = call S.pop(context, 1);

    CAR(l);
    PUSH(l);
  }

  command uint8_t Car.byteLength() {
    return 1;
  }

  //FN cdr: l -> x. Returns first element of pair l
  command result_t Cdr.execute(uint8_t instr, MateContext* context) {
    mvalue l = call S.pop(context, 1);

    CDR(l);
    PUSH(l);
  }

  command uint8_t Cdr.byteLength() {
    return 1;
  }

  //FN caar: l -> x. car(car(l))
  command result_t Caar.execute(uint8_t instr, MateContext* context) {
    mvalue l = call S.pop(context, 1);

    CAR(l);
    CAR(l);
    PUSH(l);
  }

  command uint8_t Caar.byteLength() {
    return 1;
  }

  //FN cadr: l -> x. car(cdr(l))
  command result_t Cadr.execute(uint8_t instr, MateContext* context) {
    mvalue l = call S.pop(context, 1);

    CDR(l);
    CAR(l);
    PUSH(l);
  }

  command uint8_t Cadr.byteLength() {
    return 1;
  }

  //FN cdar: l -> x. cdr(car(l))
  command result_t Cdar.execute(uint8_t instr, MateContext* context) {
    mvalue l = call S.pop(context, 1);

    CAR(l);
    CDR(l);
    PUSH(l);
  }

  command uint8_t Cdar.byteLength() {
    return 1;
  }

  //FN cddr: l -> x. cdr(cdr(l))
  command result_t Cddr.execute(uint8_t instr, MateContext* context) {
    mvalue l = call S.pop(context, 1);

    CDR(l);
    CDR(l);
    PUSH(l);
  }

  command uint8_t Cddr.byteLength() {
    return 1;
  }

  //FN caaar: l -> x. car(car(car(l)))
  command result_t Caaar.execute(uint8_t instr, MateContext* context) {
    mvalue l = call S.pop(context, 1);

    CAR(l);
    CAR(l);
    CAR(l);
    PUSH(l);
  }

  command uint8_t Caaar.byteLength() {
    return 1;
  }

  //FN caadr: l -> x. car(car(cdr(l)))
  command result_t Caadr.execute(uint8_t instr, MateContext* context) {
    mvalue l = call S.pop(context, 1);

    CDR(l);
    CAR(l);
    CAR(l);
    PUSH(l);
  }

  command uint8_t Caadr.byteLength() {
    return 1;
  }

  //FN cadar: l -> x. car(cdr(car(l)))
  command result_t Cadar.execute(uint8_t instr, MateContext* context) {
    mvalue l = call S.pop(context, 1);

    CAR(l);
    CDR(l);
    CAR(l);
    PUSH(l);
  }

  command uint8_t Cadar.byteLength() {
    return 1;
  }

  //FN caddr: l -> x. car(cdr(cdr(l)))
  command result_t Caddr.execute(uint8_t instr, MateContext* context) {
    mvalue l = call S.pop(context, 1);

    CDR(l);
    CDR(l);
    CAR(l);
    PUSH(l);
  }

  command uint8_t Caddr.byteLength() {
    return 1;
  }

  //FN cdaar: l -> x. cdr(car(car(l)))
  command result_t Cdaar.execute(uint8_t instr, MateContext* context) {
    mvalue l = call S.pop(context, 1);

    CAR(l);
    CAR(l);
    CDR(l);
    PUSH(l);
  }

  command uint8_t Cdaar.byteLength() {
    return 1;
  }

  //FN cdadr: l -> x. cdr(car(cdr(l)))
  command result_t Cdadr.execute(uint8_t instr, MateContext* context) {
    mvalue l = call S.pop(context, 1);

    CDR(l);
    CAR(l);
    CDR(l);
    PUSH(l);
  }

  command uint8_t Cdadr.byteLength() {
    return 1;
  }

  //FN cddar: l -> x. cdr(cdr(car(l)))
  command result_t Cddar.execute(uint8_t instr, MateContext* context) {
    mvalue l = call S.pop(context, 1);

    CAR(l);
    CDR(l);
    CDR(l);
    PUSH(l);
  }

  command uint8_t Cddar.byteLength() {
    return 1;
  }

  //FN cdddr: l -> x. cdr(cdr(cdr(l)))
  command result_t Cdddr.execute(uint8_t instr, MateContext* context) {
    mvalue l = call S.pop(context, 1);

    CDR(l);
    CDR(l);
    CDR(l);
    PUSH(l);
  }

  command uint8_t Cdddr.byteLength() {
    return 1;
  }

}
