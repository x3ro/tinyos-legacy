module FNbasicM {
  provides {
    interface MateBytecode as FunctionP;
    interface MateBytecode as Apply;
    interface MateBytecode as Error;
    interface MateBytecode as GarbageCollect;
  }
  uses {
    interface MotlleGC as GC;
    interface MotlleStack as S;
    interface MotlleTypes as T;
    interface MateError as E;
    interface MotlleValues as V;
    interface MateBytecode as Exec;
  }
}
implementation {
  //FN error: i -> . Causes error i
  command result_t Error.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1);

    if (call T.intp(x))
      call E.error(context, call T.intv(x));
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t Error.byteLength() {
    return 1;
  }

  //FN apply: fn v -> x. Excutes fn with arguments v, returns its result
  command result_t Apply.execute(uint8_t instr, MateContext* context) {
    mvalue v = call S.pop(context, 1), fn = call S.pop(context, 1);

    if (call T.functionp(fn) && call T.vectorp(v))
      {
	msize i, len = call T.vector_length(call T.vector(v));
	vvector args;

	if (len >= 16)
	  call E.error(context, MOTLLE_ERROR_BAD_VALUE);
	else
	  {
	    bool ok;

	    GCPRO2(fn, v);
	    ok = call S.reserve(context, (len + 1) * sizeof(svalue));
	    GCPOP2(fn, v);
	    if (ok)
	      {
		args = call T.vector(v);
		for (i = 0; i < len; i++)
		  call S.qpush(context, call V.read(&args->data[i]));
		call S.qpush(context, fn);
		call Exec.execute(OP_MEXEC4 + len, context);
	      }
	  }
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t Apply.byteLength() {
    return 1;
  }

  //FN function?: x -> b. TRUE if x is a function
  command result_t FunctionP.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1);
    call S.qpush(context, call T.make_bool(call T.functionp(x)));
    return SUCCESS;
  }

  command uint8_t FunctionP.byteLength() {
    return 1;
  }

  //FN garbage_collect: -> . Does a forced garbage collection
  command result_t GarbageCollect.execute(uint8_t instr, MateContext* context) {
    call GC.collect();
    return SUCCESS;
  }

  command uint8_t GarbageCollect.byteLength() {
    return 1;
  }
}
