/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
module FNseqM {
  provides {
    interface MateBytecode as Map;
    interface MateBytecode as ForEach;
    interface MateBytecode as Vector2List;
    interface MateBytecode as List2Vector;
    interface MateBytecode as String2List;
    interface MateBytecode as List2String;
    interface MateBytecode as Length;
    interface MotlleFrame as ForeachFrame;
    interface MotlleFrame as MapFrame;
    interface MateBytecode as Memq;
    interface MateBytecode as Memv;
    interface MateBytecode as Assq;
    interface MateBytecode as Assv;
    interface MateBytecode as Reverse;
    interface MateBytecode as Append;
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
  mvalue make_list(msize len) {
    msize i;
    mvalue result = call T.nil();

    for (i = 0; i < len; i++)
      result = call T.make_pair(call T.alloc_list(call T.nil(), result));

    return result;
  }

  bool valid_list(MateContext *context, mvalue l, msize *len) {
    bool ok = call T.valid_list(l, len);

    if (!ok)
      call E.error(context, MOTLLE_ERROR_BAD_VALUE);
    
    return ok;
  }

  //FN vector->list: v -> l. Convert vector to a list.
  command result_t Vector2List.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1);

    if (call T.vectorp(x))
      {
	msize len = call T.vector_length(call T.vector(x)), i;
	mvalue result;

	/* Make n element list, then fill it in (we do this to avoid
	   constantly protecting/unprotecting and accessing x) */
	GCPRO1(x);
	result = make_list(len);
	GCPOP1(x);

	if (result)
	  {
	    vvector v = call T.vector(x);
	    mvalue scan = result;

	    for (i = 0; i < len; i++)
	      {
		vpair p = call T.pair(scan);

		call V.write(&p->car, call V.read(&v->data[i]));
		scan = call V.read(&p->cdr);
	      }
	    call S.qpush(context, result);
	  }
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);

    return SUCCESS;
  }

  command uint8_t Vector2List.byteLength() {
    return 1;
  }

  //FN string->list: v -> l. Convert string to a list.
  command result_t String2List.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1);

    if (call T.stringp(x))
      {
	msize len = call T.string_length(call T.string(x)), i;
	mvalue result;
	
	/* Make n element list, then fill it in (we do this to avoid
	   constantly protecting/unprotecting and accessing x) */
	GCPRO1(x);
	result = make_list(len);
	GCPOP1(x);

	if (result)
	  {
	    vstring s = call T.string(x);
	    mvalue scan = result;

	    for (i = 0; i < len; i++)
	      {
		vpair p = call T.pair(scan);

		call V.write(&p->car, call T.make_int(s->str[i]));
		scan = call V.read(&p->cdr);
	      }
	    call S.qpush(context, result);
	  }
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);

    return SUCCESS;
  }

  command uint8_t String2List.byteLength() {
    return 1;
  }

  //FN list->vector: l -> v. Convert list to vector.
  command result_t List2Vector.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1);
    msize len, i;
    vvector v;

    if (valid_list(context, x, &len))
      {
	GCPRO1(x);
	v = call T.alloc_vector(len);
	GCPOP1(x);

	if (v)
	  {
	    for (i = 0; i < len; i++)
	      {
		vpair p = call T.pair(x);

		call V.write(&v->data[i], call V.read(&p->car));
		x = call V.read(&p->cdr);
	      }
	    call S.qpush(context, call T.make_vector(v));
	  }
      }

    return SUCCESS;
  }

  command uint8_t List2Vector.byteLength() {
    return 1;
  }

  //FN list->string: l -> v. Convert list to string.
  command result_t List2String.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1);
    msize len, i;
    vstring s;

    if (valid_list(context, x, &len))
      {
	GCPRO1(x);
	s = call T.alloc_string(len);
	GCPOP1(x);

	if (s)
	  {
	    for (i = 0; i < len; i++)
	      {
		vpair p = call T.pair(x);
		mvalue car = call V.read(&p->car);

		if (call T.intp(car))
		  s->str[i] = call T.intv(car);
		else
		  call E.error(context, MOTLLE_ERROR_BAD_VALUE);
		x = call V.read(&p->cdr);
	      }
	    call S.qpush(context, call T.make_string(s));
	  }
      }

    return SUCCESS;
  }

  command uint8_t List2String.byteLength() {
    return 1;
  }

  //FN length: x -> n. Return length of list, vector or string
  command result_t Length.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1);
    msize len;

    if (call T.vectorp(x))
      call S.qpush(context, call T.make_int(call T.vector_length(call T.vector(x))));
    else if (call T.stringp(x))
      call S.qpush(context, call T.make_int(call T.string_length(call T.string(x))));
/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
    else if (valid_list(context, x, &len))
      call S.qpush(context, call T.make_int(len));
    return SUCCESS;
  }

  command uint8_t Length.byteLength() {
    return 1;
  }

  //FN assq: l x1 -> x2. Returns first element of l whose car is x1,
  //   or false if there is no such element.
  command result_t Assq.execute(uint8_t nargs, MateContext* context) {
    mvalue x = call S.pop(context, 1);
    mvalue l = call S.pop(context, 1);
    msize len;
    mvalue result;

    if (valid_list(context, l, &len))
      {
	for (;;)
	  {
	    vpair p;
	    mvalue pcar;

	    if (call T.nullp(l))
	      {
		result = call T.make_bool(FALSE);
		break;
	      }

	    p = call T.pair(l);
	    pcar = call V.read(&p->car);
	    if (call T.pairp(pcar))
	      {
		vpair elem = call T.pair(pcar);

		if (x == call V.read(&elem->car))
		  {
		    result = pcar;
		    break;
		  }
	      }
	    l = call V.read(&p->cdr);
	  }
	call S.qpush(context, result);
      }
    return SUCCESS;
  }

  command uint8_t Assq.byteLength() {
    return 1;
  }

  //FN assv: l x1 -> x2. Returns first element of l whose car is x1,
  //   or false if there is no such element.
  command result_t Assv.execute(uint8_t nargs, MateContext* context) {
    return call Assq.execute(nargs, context);
  }

  command uint8_t Assv.byteLength() {
    return 1;
  }

  //FN memq: l1 x -> l2. Returns l1 starting at the first element which is x,
  //   or false if there is no such element.
  command result_t Memq.execute(uint8_t nargs, MateContext* context) {
    mvalue x = call S.pop(context, 1);
    mvalue l = call S.pop(context, 1);
    msize len;

    if (valid_list(context, l, &len))
      {
	for (;;)
	  {
	    vpair p;

	    if (call T.nullp(l))
	      {
		l = call T.make_bool(FALSE);
		break;
	      }

	    p = call T.pair(l);
	    if (call V.read(&p->car) == x)
	      break;
	    l = call V.read(&p->cdr);
	  }
	call S.qpush(context, l);
      }
    return SUCCESS;
  }

  command uint8_t Memq.byteLength() {
    return 1;
  }

  //FN memv: l1 x -> l2. Returns l1 starting at the first element which is x,
  //   or false if there is no such element.
  command result_t Memv.execute(uint8_t nargs, MateContext* context) {
    return call Memq.execute(nargs, context);
  }

  command uint8_t Memv.byteLength() {
    return 1;
  }

  //FN reverse: l1 -> l2. Reverse list l1
  command result_t Reverse.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1), result = call T.nil();
    msize len;

    if (valid_list(context, x, &len))
      {
	while (!call T.nullp(x))
	  {
	    vpair p = call T.pair(x);

	    x = call V.read(&p->cdr);
	    GCPRO1(x);
	    p = call T.alloc_list(call V.read(&p->car), result);
	    GCPOP1(x);
	    if (!p)
	      return SUCCESS;
	    result = call T.make_pair(p);
	  }
	call S.qpush(context, result);
      }
    return SUCCESS;
  }

  command uint8_t Reverse.byteLength() {
    return 1;
  }

  //FN append: l1 l2 -> l3. Append list l1 to l2.
  command result_t Append.execute(uint8_t instr, MateContext* context) {
    mvalue l2 = call S.pop(context, 1);
    mvalue l1 = call S.pop(context, 1);
    msize len;
    mvalue result;

    if (call T.nullp(l1))
      call S.qpush(context, l2);
    else if (valid_list(context, l1, &len))
      {
	/* Make n element list, then fill it in (this avoids
	   constantly protecting/unprotecting and accessing x) */
	GCPRO1(l1);
	result = make_list(len);
	GCPOP1(l1);

	if (result)
	  {
	    mvalue scanr = result;

	    for (;;)
	      {
		vpair pl1 = call T.pair(l1);
		vpair pr = call T.pair(scanr);

		call V.write(&pr->car, call V.read(&pl1->car));
		l1 = call V.read(&pl1->cdr);

		if (call T.nullp(l1))
		  {
		    call V.write(&pr->cdr, l2);
		    break;
		  }
		else
		  scanr = call V.read(&pr->cdr);
	      }
	    call S.qpush(context, result);
	  }
      }
    return SUCCESS;
  }

  command uint8_t Append.byteLength() {
    return 1;
  }

  bool map_length(MateContext *context, uint8_t i, msize *len) {
    mvalue x = call S.get(context, i);

    if (call T.vectorp(x))
      {
	*len = call T.vector_length(call T.vector(x));
	return TRUE;
      }
    else if (call T.stringp(x))
      {
	call T.string_length(call T.string(x));
	return TRUE;
      }
    else
      return valid_list(context, x, len);
  }

  bool check_map_args(MateContext *context, uint8_t nargs, msize *len) {
    bool first = TRUE;
    uint8_t i;
    mvalue fn;

    /* Check min/max args */
    if (nargs <= 1 || --nargs >= 16)
      {
	call E.error(context, MOTLLE_ERROR_BAD_VALUE);
	return FALSE;
      }

    fn = call S.get(context, nargs);
    if (!call T.functionp(fn))
      {
	call E.error(context, MOTLLE_ERROR_BAD_VALUE);
	return FALSE;
      }

    /* Check that all sequences are of the same lengths */
    for (i = 0; i < nargs; i++)
      {
	msize nlen;

	if (!map_length(context, i, &nlen))
	  return FALSE;

	if (first)
	  {
	    first = FALSE;
	    *len = nlen;
	  }
	else if (*len != nlen)
	  {
	    call E.error(context, MOTLLE_ERROR_BAD_VALUE);
	    return FALSE;
	  }
      }

    return TRUE;
  }

  struct foreach_frame {
    msize idx, len;
    uint8_t nargs;
    uint16_t retpc;
    void *sp;
  };

  mvalue map_arg(struct foreach_frame *frame, msize idx, uint8_t i) {
    mvalue arg = call S.getOtherFrame(frame->sp, frame->nargs - 1 - i);

    if (call T.vectorp(arg))
      return call V.read(&(call T.vector(arg))->data[idx]);
    else if (call T.stringp(arg))
      return call T.make_int((call T.string(arg))->str[idx]);
    else
      {
	vpair p = call T.pair(arg);

	call S.putOtherFrame(frame->sp, frame->nargs - 1 - i, call V.read(&p->cdr));
	
	return call V.read(&p->car);
      }
  }

  void foreach_execute(MateContext *context, struct foreach_frame *frame,
		       mvalue result) {
    uint8_t i, nargs = frame->nargs, idx = frame->idx++;

    if (idx == frame->len)
      {
	/* Done. Get rid of the frame and old arguments. */
	context->pc = frame->retpc;
	call S.pop_frame(context, sizeof(struct foreach_frame), 0);
	call S.pop(context, nargs + 1);
	call S.qpush(context, result);
      }
    else if (call S.reserve(context, (nargs + 1) * sizeof(svalue)))
      {
	for (i = 0; i < nargs; i++)
	  call S.qpush(context, map_arg(frame, idx, i));
	call S.qpush(context, call S.getOtherFrame(frame->sp, nargs));
	call Exec.execute(OP_MEXEC4 + nargs, context);
      }
  }

  command void ForeachFrame.execute(MateContext *context, void *vframe) {
    struct foreach_frame *frame = vframe;

    if (frame->idx != 0)
      call S.pop(context, 1); // get rid of the old result

    foreach_execute(context, frame, call T.make_int(42));
  }

  command msize ForeachFrame.gc_forward(MateContext *context, void *vframe, uint8_t *lfp, uint8_t *lsp) {
    return sizeof(struct foreach_frame);
  }

  void init_foreach_frame(MateContext *context, struct foreach_frame *frame, uint8_t nargs, msize len, void *map_sp) {
    frame->idx = 0;
    frame->len = len;
    frame->nargs = nargs - 1;
    frame->retpc = context->pc;
    frame->sp = map_sp;
    context->pc = 2;
  }

  void push_foreach_frame(MateContext *context, uint8_t nargs, msize len) {
    struct foreach_frame *frame;
    void *map_sp = call S.sp(context);

    frame = call S.alloc_frame(context, MOTLLE_FOREACH_FRAME,
			       sizeof(struct foreach_frame));
    if (frame)
      init_foreach_frame(context, frame, nargs, len, map_sp);
  }

  //FN for-each: fn x1 ... -> x.: apply fn to the n-tuple formed by taking
  //   one element from each xi list/vector/string, in order.
  //   Each xi must have the same length. The result is undefined.
  command result_t ForEach.execute(uint8_t nargs, MateContext* context) {
    msize len;

    if (check_map_args(context, nargs, &len))
      push_foreach_frame(context, nargs, len);

    return SUCCESS;
  }

  command uint8_t ForEach.byteLength() {
    return 1;
  }

  struct map_frame {
    struct foreach_frame foreach;
    mvalue results, last_result;
  };

  command void MapFrame.execute(MateContext *context, void *vframe) {
    struct map_frame *frame = vframe;

    if (frame->foreach.idx != 0)
      {
	/* Add last result to list */
	mvalue result = call S.pop(context, 1);
	vpair presult = call T.alloc_list(result, call T.nil());

	result = call T.make_pair(presult);
	if (frame->results == call T.nil())
	  frame->results = result;
	else
	  call V.write(&(call T.pair(frame->last_result))->cdr, result);
	frame->last_result = result;
      }

    foreach_execute(context, &frame->foreach, frame->results);
  }

  command msize MapFrame.gc_forward(MateContext *context, void *vframe, uint8_t *lfp, uint8_t *lsp) {
    struct map_frame *frame = vframe;

    call GC.forward(&frame->results);
    call GC.forward(&frame->last_result);
    return sizeof(struct map_frame);
  }

  void push_map_frame(MateContext *context, uint8_t nargs, msize len) {
    struct map_frame *frame;
    void *map_sp = call S.sp(context);

    frame = call S.alloc_frame(context, MOTLLE_MAP_FRAME,
			       sizeof(struct map_frame));
    if (frame)
      {
	init_foreach_frame(context, &frame->foreach, nargs, len, map_sp);
	frame->results = frame->last_result = call T.nil();
      }
  }

  //FN map: fn x1 ... -> x.: apply fn to the n-tuple formed by taking
  //   one element from each xi list/vector/string.
  //   Each xi must have the same length. The result is the result of
  //   the calls to fn.
  command result_t Map.execute(uint8_t nargs, MateContext* context) {
    msize len;

    if (check_map_args(context, nargs, &len))
      push_map_frame(context, nargs, len);

    return SUCCESS;
  }

  command uint8_t Map.byteLength() {
    return 1;
  }
}
