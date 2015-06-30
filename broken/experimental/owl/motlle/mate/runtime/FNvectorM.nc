module FNvectorM {
  provides {
    interface MateBytecode as VectorP;
    interface MateBytecode as MakeVector;
    interface MateBytecode as VectorLength;
    interface MateBytecode as VectorFillB;
    interface MateBytecode as Vector;
  }
  uses {
    interface MotlleStack as S;
    interface MotlleTypes as T;
    interface MateError as E;
    interface MotlleValues as V;
  }
}
implementation {
  //FN vector?: x -> b. TRUE if x is a vector
  command result_t VectorP.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1);
    call S.qpush(context, call T.make_bool(call T.vectorp(x)));
    return SUCCESS;
  }

  command uint8_t VectorP.byteLength() {
    return 1;
  }

  //FN make_vector: i -> v. Create an empty vector of length i
  command result_t MakeVector.execute(uint8_t instr, MateContext* context) {
    mvalue n = call S.pop(context, 1);

    if (call T.intp(n))
      {
	vvector v = call T.alloc_vector(call T.intv(n));
	if (v)
	  call S.push(context, call T.make_vector(v));
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t Vector.byteLength() {
    return 1;
  }

  command uint8_t MakeVector.byteLength() {
    return 1;
  }

  //FN vector_length: v -> i. Return length of vector
  command result_t VectorLength.execute(uint8_t instr, MateContext* context) {
    mvalue v = call S.pop(context, 1);

    if (call T.vectorp(v))
      call S.qpush(context, call T.make_int(call T.vector_length(call T.vector(v))));
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t VectorLength.byteLength() {
    return 1;
  }

  //FN vector_fill!: v x -> . Set all elements of v to x
  command result_t VectorFillB.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1);
    mvalue v = call S.pop(context, 1);

    if (call T.vectorp(v))
      {
	vvector vv = call T.vector(v);
	msize len = call T.vector_length(vv);

	while (len-- > 0)
	  call V.write(&vv->data[len], x);
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t VectorFillB.byteLength() {
    return 1;
  }

  //FN vector: x1 ... -> v. Returns a vector of the arguments
  command result_t Vector.execute(uint8_t nargs, MateContext* context) {
    vvector v = call T.alloc_vector(nargs);

    if (v)
      {
	while (nargs-- > 0)
	  call V.write(&v->data[nargs], call S.pop(context, 1));
	call S.push(context, call T.make_vector(v));
      }

    return SUCCESS;
  }
}
