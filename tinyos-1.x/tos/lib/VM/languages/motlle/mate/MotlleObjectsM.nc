/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
module MotlleObjectsM {
  provides interface MotlleTypes as T;
  uses {
    interface MotlleValues as V;
    interface MotlleGC as GC;
  }
}
implementation {
#include "primitive_args.h"

  enum { 
    NUM_PRIMITIVES = sizeof mp_args / sizeof *mp_args
  };

  // Atoms: 0 is null, 1-n are the primitives, n+1 onwards are symbols
  enum {
    ATOM_NULL,
    ATOM_FIRST_PRIMITIVE,
    ATOM_LAST_PRIMITIVE = ATOM_FIRST_PRIMITIVE + NUM_PRIMITIVES - 1,
    ATOM_FIRST_SYMBOL
  };

  command mtype T.user_type(mvalue x) {
    mtype t;

    if (call V.integerp(x))
      return type_int;
    if (call V.realp(x))
      return type_real;
    if (call V.atomp(x))
      {
	avalue a = call V.atom(x);

	if (a == ATOM_NULL)
	  return type_null;
	if (a <= ATOM_LAST_PRIMITIVE)
	  return type_function;
	return type_symbol;
      }

    t = call V.ptype(call V.pointer(x));
    switch (t)
      {
      case itype_code: case itype_closure: return type_function;
      default: return t;
      }
  }

  command mtype T.internal_type(mvalue x) {
    if (call V.integerp(x))
      return type_int;
    if (call V.realp(x))
      return type_real;
    if (call V.atomp(x))
      {
	avalue a = call V.atom(x);

	if (a == ATOM_NULL)
	  return type_null;
	if (a <= ATOM_LAST_PRIMITIVE)
	  return itype_primitive;
	return type_symbol;
      }

    return call V.ptype(call V.pointer(x));
  }


  MINLINE bool boxedtypep(mvalue x, mtype t) {
    return call V.pointerp(x) && call V.ptype(call V.pointer(x)) == t;
  }

  MINLINE command bool T.codep(mvalue x) {
    return boxedtypep(x, itype_code);
  }

  MINLINE command bool T.nullp(mvalue x) {
    return call T.internal_type(x) == type_null;
  }

  MINLINE command bool T.stringp(mvalue x) {
    return boxedtypep(x, type_string);
  }

  MINLINE command bool T.vectorp(mvalue x) {
    return boxedtypep(x, type_vector);
  }

  MINLINE command bool T.pairp(mvalue x) {
    return boxedtypep(x, type_pair);
  }

  MINLINE command bool T.closurep(mvalue x) {
    return boxedtypep(x, itype_closure);
  }

  MINLINE command bool T.intp(mvalue x) {
    return call V.integerp(x);
  }

  inline command bool T.realp(mvalue x) {
    return call V.realp(x);
  }

  MINLINE command bool T.functionp(mvalue x) {
    return call T.user_type(x) == type_function;
  }

  MINLINE command bool T.primitivep(mvalue x) {
    if (call V.atomp(x))
      {
	avalue a = call V.atom(x);

	return a >= ATOM_FIRST_PRIMITIVE && a <= ATOM_LAST_PRIMITIVE;
      }
    return FALSE;
  }

  MINLINE command bool T.listp(mvalue x) {
    mtype t = call T.internal_type(x);

    return t == type_pair || t == type_null;
  }

  MINLINE command bool T.symbolp(mvalue x) {
    return call V.atomp(x) && call V.atom(x) >= ATOM_FIRST_SYMBOL;
  }


  MINLINE command vcode T.code(mvalue x) {
    return call V.data(call V.pointer(x));
  }

  MINLINE command vstring T.string(mvalue x) {
    return call V.data(call V.pointer(x));
  }

  MINLINE command vvector T.vector(mvalue x) {
    return call V.data(call V.pointer(x));
  }

  MINLINE command vpair T.pair(mvalue x) {
    return call V.data(call V.pointer(x));
  }

  MINLINE command vclosure T.closure(mvalue x) {
    return call V.data(call V.pointer(x));
  }

  MINLINE command vint T.intv(mvalue x) {
    return call V.integer(x);
  }

  MINLINE command vreal T.real(mvalue x) {
    return call V.real(x);
  }

  MINLINE command vprimitive T.primitive(mvalue x) {
    return call V.atom(x) - ATOM_FIRST_PRIMITIVE;
  }

  MINLINE command vsymbol T.symbol(mvalue x) {
    return call V.atom(x) - ATOM_FIRST_SYMBOL;
  }


  MINLINE command mvalue T.make_code(vcode x) {
    return call V.make_pointer(call V.make_pvalue(x));
  }

  MINLINE command mvalue T.make_string(vstring x) {
    return call V.make_pointer(call V.make_pvalue(x));
  }

  MINLINE command mvalue T.make_vector(vvector x) {
    return call V.make_pointer(call V.make_pvalue(x));
  }

  MINLINE command mvalue T.make_pair(vpair x) {
    return call V.make_pointer(call V.make_pvalue(x));
  }

  MINLINE command mvalue T.make_closure(vclosure x) {
    return call V.make_pointer(call V.make_pvalue(x));
  }

  MINLINE command mvalue T.make_int(vint x) {
    return call V.make_integer(x);
  }

  MINLINE command mvalue T.make_real(vreal x) {
    return call V.make_real(x);
  }

  MINLINE command mvalue T.make_primitive(vprimitive x) {
    return call V.make_atom(x + ATOM_FIRST_PRIMITIVE);
  }

  MINLINE command mvalue T.make_symbol(vsymbol x) {
    return call V.make_atom(x + ATOM_FIRST_SYMBOL);
  }


  MINLINE command mvalue T.nil() {
    return call V.make_atom(ATOM_NULL);
  }

  MINLINE command bool T.truep(mvalue x) {
    return call V.truep(x);
  }

  MINLINE command mvalue T.make_bool(bool x) {
    return call V.make_integer(x);
  }


  MINLINE command vstring T.alloc_string(msize size) {
    return call V.allocate(type_string, size);
  }

  void *alloc_record(mtype type, msize nentries) {
    svalue *newp = call V.allocate(type, nentries * sizeof(svalue)), *o;

    if (!newp)
      return NULL;

    /* Initialise data to nil */
    o = newp;
    while (nentries--)
      call V.write(o++, call T.nil());
    
    return newp;
  }

  MINLINE command vvector T.alloc_vector(msize nentries) {
    return alloc_record(type_vector, nentries);
  }

  command vpair T.alloc_list(mvalue car, mvalue cdr) {
    vpair pair;

    GCPRO2(car, cdr);
    pair = alloc_record(type_pair, 2);
    GCPOP2(car, cdr);
    if (pair)
      {
	call V.write(&pair->car, car);
	call V.write(&pair->cdr, cdr);
      }
    return pair;
  }

  MINLINE command int8_t T.primitive_args(vprimitive x) {
    return motlle_primitive_args(x);
  }

  MINLINE command bool T.primitive_retval(vprimitive x) {
    return motlle_primitive_retval(x);
  }

  MINLINE command msize T.vector_length(vvector v) {
    return call V.size(call V.make_pvalue(v)) / sizeof *v->data;
  }

  MINLINE command msize T.string_length(vstring s) {
    return call V.size(call V.make_pvalue(s)) / sizeof *s->str;
  }

  MINLINE command bool T.int_intp(mvalue x, mvalue y) {
    return call T.intp(x) && call T.intp(y);
  }

  inline command bool T.real_intp(mvalue x, mvalue y) {
    return call T.realp(x) && call T.intp(y);
  }

  inline command bool T.real_realp(mvalue x, mvalue y) {
    return call T.realp(x) && call T.realp(y);
  }

  MINLINE command bool T.numberp(mvalue x) {
    return call T.realp(x) || call T.intp(x);
  }

  inline command bool T.promotep(mvalue x, mvalue y) {
    if (call T.realp(x))
      return call T.numberp(y);
    if (call T.realp(y))
      return call T.intp(x);
    return FALSE;
  }
      
  command vreal T.number(mvalue x) {
    if (call T.intp(x))
      return call T.intv(x);
    else
      return call T.real(x);
  }

  command bool T.valid_list(mvalue l, msize *len) {
    bool ok = TRUE;
    mvalue scan;

    *len = 0;

    /* Check for valid, non-circular list using marks. Clear marks
       when done. */
    for (scan = l;; scan = call V.read(&(call T.pair(scan))->cdr))
      {
	if (call T.nullp(scan))
	  break;
	if (!call T.pairp(scan) || call V.marked(scan))
	  {
	    ok = FALSE;
	    break;
	  }
	call V.mark(scan);
	(*len)++;
      }
    for (scan = l;; scan = call V.read(&(call T.pair(scan))->cdr))
      {
	if (call T.nullp(scan) || !call V.marked(scan))
	  return ok;
	call V.unmark(scan);
      }
  }
}
