module FNaggminM {
  provides {
    interface MateBytecode as MinMake;
    interface MateBytecode as MinBuffer;
    interface MateBytecode as MinEpochUpdate;
    interface MateBytecode as MinIntercept;
    interface MateBytecode as MinSample;
    interface MateBytecode as MinGet;
  }
  uses {
    interface MotlleStack as S;
    interface MotlleTypes as T;
    interface MateError as E;
    interface MotlleValues as V;
    interface QueryAgg as Q;
  }
}
implementation {
  enum {
    maxdepth = 6,
    window = 2 * maxdepth,
    maxint = 0x3fff
  };

  //FN min_make: -> v.
  command result_t MinMake.execute(uint8_t instr, MateContext* context) {
    vvector state;
    svalue *mins;
    int i;

    state = call T.alloc_vector(1 + window);
    if (!state)
      return SUCCESS;

    mins = state->data + 1;
    for (i = 0; i < window; i++)
      call V.write(&mins[i], call T.make_int(maxint));

    call V.write(&state->data[0], call T.make_int(0));

    call S.push(context, call T.make_vector(state));

    return SUCCESS;
  }

  command uint8_t MinMake.byteLength() {
    return 1;
  }

  vvector validate_state(mvalue v, vint *start, svalue **mins, MateContext *context) {
    vvector state;

    if (call T.vectorp(v) && call T.vector_length((state = call T.vector(v))) == 1 + window)
      {
	*start = call T.intv(call V.read(&state->data[0]));
	*mins = state->data + 1;

	return state;
      }
    else
      {
	call E.error(context, MOTLLE_ERROR_BAD_TYPE);
	return NULL;
      }
  }

  //FN min_newepoch: sstate -> .
  command result_t MinEpochUpdate.execute(uint8_t instr, MateContext* context) {
    mvalue v = call S.pop(context, 1);
    vvector state;
    svalue *mins;
    vint start;

    if ((state = validate_state(v, &start, &mins, context)))
      {
	// ensure epoch + 1 is inside the window
	if (call Q.getEpoch() + 1 >= start + window)
	  {
	    int i, shift;
	 
	    // figure out new start and how much to shift values
	    // from old epoch for the new start
	    shift = call Q.getEpoch() + 2 - window - start;
	    start = call Q.getEpoch() + 2 - window;
	    call V.write(&state->data[0], call T.make_int(start));
	  
	    if (shift > window)
	      shift = window;
	    else
	      {
		i = shift;
		while (i < window)
		  {
		    call V.write(&mins[i - shift], call V.read(&mins[i]));
		    i = i + 1;
		  }
	      }
	  
	    // clear new values
	    i = window - shift;
	    while (i < window)
	      {
		call V.write(&mins[i], call T.make_int(maxint));
		i = i + 1;
	      }
	  }
      }

    return SUCCESS;
  }

  command uint8_t MinEpochUpdate.byteLength() {
    return 1;
  }

  void acc(vint start, svalue *mins, vint when, vint min) {
    if (when >= start && when < start + window)
      {
	vint omin = call T.intv(call V.read(&mins[when - start]));

	if (min < omin)
	  call V.write(&mins[when - start], call T.make_int(min));
      }
  }

  vint decode2(unsigned char *s) {
    return s[0] | s[1] << 8;
  }

  void encode2(unsigned char *s, vint x) {
    s[0] = x;
    s[1] = x >> 8;
  }

  bool decode_min(mvalue data, vint *when, vint *min) {
    vstring enc;

    if (call T.stringp(data) &&
	call T.string_length((enc = call T.string(data))) == 4)
      {
	*when = decode2(enc->str);
	*min = decode2(enc->str + 2);
	return TRUE;
      }
    else
      {
	call E.error(NULL, MOTLLE_ERROR_BAD_VALUE);
	return FALSE;
      }
  }

  vstring encode_min(vint when, vint min) {
    vstring enc = call T.alloc_string(4);

    if (enc)
      {
	encode2(enc->str, when);
	encode2(enc->str + 2, min);
      }
    return enc;
  }

  //FN min_buffer: -> s.
  command result_t MinBuffer.execute(uint8_t instr, MateContext* context) {
    vstring buffer;

    buffer = call T.alloc_string(4);

    if (buffer)
      call S.push(context, call T.make_string(buffer));

    return SUCCESS;
  }

  command uint8_t MinBuffer.byteLength() {
    return 1;
  }

  //FN min_intercept: sstate s -> .
  command result_t MinIntercept.execute(uint8_t instr, MateContext* context) {
    mvalue data = call S.pop(context, 1);
    mvalue v = call S.pop(context, 1);
    svalue *mins;
    vint start, when, min;

    if (validate_state(v, &start, &mins, context) &&
	decode_min(data, &when, &min))
      acc(start, mins, when, min);
    return SUCCESS;
  }

  command uint8_t MinIntercept.byteLength() {
    return 1;
  }

  //FN min_update: sstate n -> .
  command result_t MinSample.execute(uint8_t instr, MateContext* context) {
    mvalue data = call S.pop(context, 1);
    mvalue v = call S.pop(context, 1);
    svalue *mins;
    vint start;

    if (!call T.intp(data))
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    else if (validate_state(v, &start, &mins, context))
      acc(start, mins, call Q.getEpoch(), call T.intv(data));

    return SUCCESS;
  }

  command uint8_t MinSample.byteLength() {
    return 1;
  }

  //FN min_get: sstate -> s.
  command result_t MinGet.execute(uint8_t instr, MateContext* context) {
    mvalue v = call S.pop(context, 1);
    svalue *mins;
    vint start;
    int depth = call Q.getDepth();

    if (validate_state(v, &start, &mins, context))
      {
	int when = call Q.getEpoch() - 2 * (maxdepth - 1 - depth);
	vstring s;

	if (depth < maxdepth - 1 && when >= start)
	  s = encode_min(when, call T.intv(call V.read(&mins[when - start])));
	else /* no data in window, return default value */
	  s = encode_min(when, maxint);

	if (s)
	  call S.push(context, call T.make_string(s));
      }

    return SUCCESS;
  }

  command uint8_t MinGet.byteLength() {
    return 1;
  }
}
