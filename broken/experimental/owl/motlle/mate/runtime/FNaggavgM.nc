module FNaggavgM {
  provides {
    interface MateBytecode as AvgMake;
    interface MateBytecode as AvgBuffer;
    interface MateBytecode as AvgEpochUpdate;
    interface MateBytecode as AvgIntercept;
    interface MateBytecode as AvgSample;
    interface MateBytecode as AvgGet;
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
    maxdepth = 5,
    window = 2 * maxdepth
  };

  //FN avg_make: -> v.
  command result_t AvgMake.execute(uint8_t instr, MateContext* context) {
    vvector state;
    svalue *count, *sum;
    int i;

    state = call T.alloc_vector(1 + 2 * window);
    if (!state)
      return SUCCESS;

    count = state->data + 1;
    sum = count + window;
    for (i = 0; i < window; i++)
      {
	call V.write(&count[i], call T.make_int(0));
	call V.write(&sum[i], call T.make_int(0));
      }

    call V.write(&state->data[0], call T.make_int(0));

    call S.push(context, call T.make_vector(state));

    return SUCCESS;
  }

  command uint8_t AvgMake.byteLength() {
    return 1;
  }

  vvector validate_state(mvalue v, vint *start, svalue **count, svalue **sum, MateContext *context) {
    vvector state;

    if (call T.vectorp(v) && call T.vector_length((state = call T.vector(v))) == 1 + 2 * window)
      {
	*start = call T.intv(call V.read(&state->data[0]));
	*count = state->data + 1;
	*sum = *count + window;

	return state;
      }
    else
      {
	call E.error(context, MOTLLE_ERROR_BAD_TYPE);
	return NULL;
      }
  }

  //FN avg_newepoch: sstate -> .
  command result_t AvgEpochUpdate.execute(uint8_t instr, MateContext* context) {
    mvalue v = call S.pop(context, 1);
    vvector state;
    svalue *count, *sum;
    vint start;

    if ((state = validate_state(v, &start, &count, &sum, context)))
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
		    call V.write(&count[i - shift], call V.read(&count[i]));
		    call V.write(&sum[i - shift], call V.read(&sum[i]));
		    i = i + 1;
		  }
	      }
	  
	    // clear new values
	    i = window - shift;
	    while (i < window)
	      {
		call V.write(&count[i], call T.make_int(0));
		call V.write(&sum[i], call T.make_int(0));
		i = i + 1;
	      }
	  }
      }

    return SUCCESS;
  }

  command uint8_t AvgEpochUpdate.byteLength() {
    return 1;
  }

  void addto(svalue *to, vint x) {
    call V.write(to, call T.make_int(call T.intv(call V.read(to)) + x));
  }

  void spatial_acc(vint start, svalue *count, svalue *sum,
		   vint when, vint n, vint s) {
    if (when >= start && when < start + window)
      {
	addto(&count[when - start], n);
	addto(&sum[when - start], s);
      }
  }

  vint decode2(unsigned char *s) {
    return s[0] | s[1] << 8;
  }

  void encode2(unsigned char *s, vint x) {
    s[0] = x;
    s[1] = x >> 8;
  }

  bool decode_avg(mvalue data, vint *when, vint *n, vint *s) {
    vstring enc;

    if (call T.stringp(data) &&
	call T.string_length((enc = call T.string(data))) == 6)
      {
	*when = decode2(enc->str);
	*n = decode2(enc->str + 2);
	*s = decode2(enc->str + 4);
	return TRUE;
      }
    else
      {
	call E.error(NULL, MOTLLE_ERROR_BAD_VALUE);
	return FALSE;
      }
  }

  vstring encode_avg(vint when, vint n, vint s) {
    vstring enc = call T.alloc_string(6);

    if (enc)
      {
	encode2(enc->str, when);
	encode2(enc->str + 2, n);
	encode2(enc->str + 4, s);
      }
    return enc;
  }

  //FN avg_buffer: -> s.
  command result_t AvgBuffer.execute(uint8_t instr, MateContext* context) {
    vstring buffer;

    buffer = call T.alloc_string(6);

    if (buffer)
      call S.push(context, call T.make_string(buffer));

    return SUCCESS;
  }

  command uint8_t AvgBuffer.byteLength() {
    return 1;
  }

  //FN avg_intercept: sstate s -> .
  command result_t AvgIntercept.execute(uint8_t instr, MateContext* context) {
    mvalue data = call S.pop(context, 1);
    mvalue v = call S.pop(context, 1);
    svalue *count, *sum;
    vint start, when, n, s;

    if (validate_state(v, &start, &count, &sum, context) &&
	decode_avg(data, &when, &n, &s))
      spatial_acc(start, count, sum, when, n, s);
    return SUCCESS;
  }

  command uint8_t AvgIntercept.byteLength() {
    return 1;
  }

  //FN avg_update: sstate n -> .
  command result_t AvgSample.execute(uint8_t instr, MateContext* context) {
    mvalue data = call S.pop(context, 1);
    mvalue v = call S.pop(context, 1);
    svalue *count, *sum;
    vint start;

    if (!call T.intp(data))
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    else if (validate_state(v, &start, &count, &sum, context))
      spatial_acc(start, count, sum, call Q.getEpoch(), 1, call T.intv(data) >> 6);

    return SUCCESS;
  }

  command uint8_t AvgSample.byteLength() {
    return 1;
  }

  //FN avg_get: sstate -> s.
  command result_t AvgGet.execute(uint8_t instr, MateContext* context) {
    mvalue v = call S.pop(context, 1);
    svalue *count, *sum;
    vint start;
    int depth = call Q.getDepth();

    if (validate_state(v, &start, &count, &sum, context))
      {
        vstring s;
	int when = call Q.getEpoch() - 2 * (maxdepth - 1 - depth);

	if (depth >= maxdepth) 
          s = encode_avg(call Q.getEpoch() - 256, 0, 0); // the deep past
	else if (when >= start)
	  s = encode_avg(when, call T.intv(call V.read(&count[when - start])),
			 call T.intv(call V.read(&sum[when - start])));
	else /* no data in window, return default value */
	  s = encode_avg(when, 0, 0);

	if (s)
	  call S.push(context, call T.make_string(s));
      }

    return SUCCESS;
  }

  command uint8_t AvgGet.byteLength() {
    return 1;
  }
}
