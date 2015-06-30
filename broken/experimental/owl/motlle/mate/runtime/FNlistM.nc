module FNlistM {
  provides {
    interface MateBytecode as Cons;
    interface MateBytecode as Car;
    interface MateBytecode as Cdr;
    interface MateBytecode as PairP;
    interface MateBytecode as ListP;
    interface MateBytecode as NullP;
    interface MateBytecode as SetCarB;
    interface MateBytecode as SetCdrB;
    interface MateBytecode as List;
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

  //FN car: l -> x. Returns first element of pair l
  command result_t Car.execute(uint8_t instr, MateContext* context) {
    mvalue l = call S.pop(context, 1);

    if (call T.pairp(l))
      {
	vpair p = call T.pair(l);
	call S.qpush(context, call V.read(&p->car));
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t Car.byteLength() {
    return 1;
  }

  //FN cdr: l -> x. Returns first element of pair l
  command result_t Cdr.execute(uint8_t instr, MateContext* context) {
    mvalue l = call S.pop(context, 1);

    if (call T.pairp(l))
      {
	vpair p = call T.pair(l);
	call S.qpush(context, call V.read(&p->cdr));
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t Cdr.byteLength() {
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

  //FN set_car!: l x ->. Sets the first element of pair l to x
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

  //FN set_cdr!: l x ->. Sets the first element of pair l to x
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
}
