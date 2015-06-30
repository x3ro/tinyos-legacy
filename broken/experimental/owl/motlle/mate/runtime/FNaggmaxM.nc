module FNaggmaxM {
  provides {
    interface MateBytecode as MaxMake;
    interface MateBytecode as MaxBuffer;
    interface MateBytecode as MaxEpochUpdate;
    interface MateBytecode as MaxIntercept;
    interface MateBytecode as MaxSample;
    interface MateBytecode as MaxGet;
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
    minint = -0x4000
  };

  //FN max_make: -> v.
  command result_t MaxMake.execute(uint8_t instr, MateContext* context) {
    vvector state;
    svalue *maxs;
    int i;

    state = call T.alloc_vector(1 + window);
    if (!state)
      return SUCCESS;

    maxs = state->data + 1;
    for (i = 0; i < window; i++)
      call V.write(&maxs[i], call T.make_int(minint));

    call V.write(&state->data[0], call T.make_int(0));

    call S.push(context, call T.make_vector(state));

    return SUCCESS;
  }

  command uint8_t MaxMake.byteLength() {
    return 1;
  }

  vvector validate_state(mvalue v, vint *start, svalue **maxs, MateContext *context) {
    vvector state;

    if (call T.vectorp(v) && call T.vector_length((state = call T.vector(v))) == 1 + window)
      {
	*start = call T.intv(call V.read(&state->data[0]));
	*maxs = state->data + 1;

	return state;
      }
    else
      {
	call E.error(context, MOTLLE_ERROR_BAD_TYPE);
	return NULL;
      }
  }

  //FN max_newepoch: sstate -> .
  command result_t MaxEpochUpdate.execute(uint8_t instr, MateContext* context) {
    mvalue v = call S.pop(context, 1);
    vvector state;
    svalue *maxs;
    vint start;

    if ((state = validate_state(v, &start, &maxs, context)))
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
		    call V.write(&maxs[i - shift], call V.read(&maxs[i]));
		    i = i + 1;
		  }
	      }
	  
	    // clear new values
	    i = window - shift;
	    while (i < window)
	      {
		call V.write(&maxs[i], call T.make_int(minint));
		i = i + 1;
	      }
	  }
      }

    return SUCCESS;
  }

  command uint8_t MaxEpochUpdate.byteLength() {
    return 1;
  }

  void acc(vint start, svalue *maxs, vint when, vint max) {
    if (when >= start && when < start + window)
      {
	vint omax = call T.intv(call V.read(&maxs[when - start]));

	if (max > omax)
	  call V.write(&maxs[when - start], call T.make_int(max));
      }
  }

  vint decode2(unsigned char *s) {
    return s[0] | s[1] << 8;
  }

  void encode2(unsigned char *s, vint x) {
    s[0] = x;
    s[1] = x >> 8;
  }

  bool decode_max(mvalue data, vint *when, vint *max) {
    vstring enc;

    if (call T.stringp(data) &&
	call T.string_length((enc = call T.string(data))) == 4)
      {
	*when = decode2(enc->str);
	*max = decode2(enc->str + 2);
	return TRUE;
      }
    else
      {
	call E.error(NULL, MOTLLE_ERROR_BAD_VALUE);
	return FALSE;
      }
  }

  vstring encode_max(vint when, vint max) {
    vstring enc = call T.alloc_string(4);

    if (enc)
      {
	encode2(enc->str, when);
	encode2(enc->str + 2, max);
      }
    return enc;
  }

  //FN max_buffer: -> s.
  command result_t MaxBuffer.execute(uint8_t instr, MateContext* context) {
    vstring buffer;

    buffer = call T.alloc_string(4);

    if (buffer)
      call S.push(context, call T.make_string(buffer));

    return SUCCESS;
  }

  command uint8_t MaxBuffer.byteLength() {
    return 1;
  }

  //FN max_intercept: sstate s -> .
  command result_t MaxIntercept.execute(uint8_t instr, MateContext* context) {
    mvalue data = call S.pop(context, 1);
    mvalue v = call S.pop(context, 1);
    svalue *maxs;
    vint start, when, max;

    if (validate_state(v, &start, &maxs, context) &&
	decode_max(data, &when, &max))
      acc(start, maxs, when, max);
    return SUCCESS;
  }

  command uint8_t MaxIntercept.byteLength() {
    return 1;
  }

  //FN max_update: sstate n -> .
  command result_t MaxSample.execute(uint8_t instr, MateContext* context) {
    mvalue data = call S.pop(context, 1);
    mvalue v = call S.pop(context, 1);
    svalue *maxs;
    vint start;

    if (!call T.intp(data))
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    else if (validate_state(v, &start, &maxs, context))
      acc(start, maxs, call Q.getEpoch(), call T.intv(data));

    return SUCCESS;
  }

  command uint8_t MaxSample.byteLength() {
    return 1;
  }

  //FN max_get: sstate -> s.
  command result_t MaxGet.execute(uint8_t instr, MateContext* context) {
    mvalue v = call S.pop(context, 1);
    svalue *maxs;
    vint start;
    int depth = call Q.getDepth();

    if (validate_state(v, &start, &maxs, context))
      {
	int when = call Q.getEpoch() - 2 * (maxdepth - 1 - depth);
	vstring s;

	if (depth < maxdepth - 1 && when >= start)
	  s = encode_max(when, call T.intv(call V.read(&maxs[when - start])));
	else /* no data in window, return default value */
	  s = encode_max(when, minint);

	if (s)
	  call S.push(context, call T.make_string(s));
      }

    return SUCCESS;
  }

  command uint8_t MaxGet.byteLength() {
    return 1;
  }
}
