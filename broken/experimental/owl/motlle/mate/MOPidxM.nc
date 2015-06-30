module MOPidxM {
  provides {
    interface MateBytecode as Set;
    interface MateBytecode as Ref;
  }
  uses {
    interface MotlleStack as S;
    interface MotlleTypes as T;
    interface MateError as E;
    interface MotlleValues as V;
    interface MotlleGC as GC;
  }
}
implementation {
  command result_t Ref.execute(uint8_t instr, MateContext *context) {
    mvalue x2 = call S.pop(context, 1);
    mvalue x1 = call S.pop(context, 1);

    if (call T.vectorp(x1))
      {
	vvector v = call T.vector(x1);

	if (call T.intp(x2))
	  {
	    vint idx = call T.intv(x2);

	    if (idx < 0 || idx >= call T.vector_length(v))
	      call E.error(context, MOTLLE_ERROR_BAD_INDEX);
	    else
	      call S.qpush(context, call V.read(&v->data[idx]));
	    return SUCCESS;
	  }
      }
    else if (call T.stringp(x1))
      {
	vstring s = call T.string(x1);

	if (call T.intp(x2))
	  {
	    vint idx = call T.intv(x2);

	    if (idx < 0 || idx >= call T.string_length(s))
	      call E.error(context, MOTLLE_ERROR_BAD_INDEX);
	    else
	      call S.qpush(context, call T.make_int(s->str[idx]));
	    return SUCCESS;
	  }
      }
    call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t Ref.byteLength() {
    return 1;
  }

  command result_t Set.execute(uint8_t instr, MateContext *context) {
    mvalue x3 = call S.pop(context, 1);
    mvalue x2 = call S.pop(context, 1);
    mvalue x1 = call S.pop(context, 1);

    if (call T.vectorp(x1))
      {
	vvector v = call T.vector(x1);

	if (call T.intp(x2))
	  {
	    vint idx = call T.intv(x2);

	    if (idx < 0 || idx >= call T.vector_length(v))
	      call E.error(context, MOTLLE_ERROR_BAD_INDEX);
	    else if (call GC.mutable(v))
	      {
		call V.write(&v->data[idx], x3);
		call S.qpush(context, x3);
	      }
	    else
	      call E.error(context, MOTLLE_ERROR_VALUE_READ_ONLY);
	    return SUCCESS;
	  }
      }
    else if (call T.stringp(x1))
      {
	vstring s = call T.string(x1);

	if (call T.intp(x2) && call T.intp(x3))
	  {
	    vint idx = call T.intv(x2);

	    if (idx < 0 || idx >= call T.string_length(s))
	      call E.error(context, MOTLLE_ERROR_BAD_INDEX);
	    else if (call GC.mutable(s))
	      {
		s->str[idx] = call T.intv(x3);
		call S.qpush(context, x3);
	      }
	    else
	      call E.error(context, MOTLLE_ERROR_VALUE_READ_ONLY);
	    return SUCCESS;
	  }
      }
    call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t Set.byteLength() {
    return 1;
  }

}

