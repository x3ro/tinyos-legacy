module MOPcallM {
  provides {
    interface MateBytecode as Exec;
    interface MateBytecode as ExecGlobal;
    interface MateBytecode as ExecPrimitive;
    interface MateBytecode as Return;
    interface MotlleFrame as InterpretFrame;
    interface MotlleVar as LV;
    interface MotlleVar as CV;
    interface MotlleVar as RawLV;
    interface MotlleVar as RawCV;
    interface MotlleClosure;
  }
  uses {
    interface MotlleGlobals as G;
    interface MotlleCode as C;
    interface MotlleGC as GC;
    interface MotlleStack as S;
    interface MotlleValues as V;
    interface MotlleTypes as T;
    interface MateError as E;
    interface MateBytecode as Primitives[uint16_t id];
  }
}
implementation {
  struct interpret_frame {
    uint16_t retpc;
    vclosure closure;
    uint8_t nb_locals;
    svalue locals[0];
  };

  MINLINE svalue *getvar(svalue *loc) {
    return call V.data(call V.pointer(call V.read(loc)));
  }

  MINLINE mvalue vread(svalue *loc) {
    return call V.read(getvar(loc));
  }

  MINLINE void vwrite(svalue *loc, mvalue v) {
    call V.write(getvar(loc), v);
  }

  MINLINE mvalue raw_vread(svalue *loc) {
    return call V.read(loc);
  }

  MINLINE void raw_vwrite(svalue *loc, mvalue v) {
    call V.write(loc, v);
  }

  MINLINE command mvalue LV.read(MateContext *context, uint16_t n) {
    struct interpret_frame *frame = call S.current_frame(context);
    return vread(&frame->locals[frame->nb_locals - 1 - n]);
  }

  MINLINE command void LV.write(MateContext *context, uint16_t n, mvalue v) {
    struct interpret_frame *frame = call S.current_frame(context);
    vwrite(&frame->locals[frame->nb_locals - 1 - n], v);
  }

  MINLINE command mvalue CV.read(MateContext *context, uint16_t n) {
    struct interpret_frame *frame = call S.current_frame(context);
    return vread(&frame->closure->variables[n]);
  }

  MINLINE command void CV.write(MateContext *context, uint16_t n, mvalue v) {
    struct interpret_frame *frame = call S.current_frame(context);
    vwrite(&frame->closure->variables[n], v);
  }

  MINLINE command mvalue RawLV.read(MateContext *context, uint16_t n) {
    struct interpret_frame *frame = call S.current_frame(context);
    return raw_vread(&frame->locals[frame->nb_locals - 1 - n]);
  }

  MINLINE command void RawLV.write(MateContext *context, uint16_t n, mvalue v) {
    struct interpret_frame *frame = call S.current_frame(context);
    raw_vwrite(&frame->locals[frame->nb_locals - 1 - n], v);
  }

  MINLINE command mvalue RawCV.read(MateContext *context, uint16_t n) {
    struct interpret_frame *frame = call S.current_frame(context);
    return raw_vread(&frame->closure->variables[n]);
  }

  MINLINE command void RawCV.write(MateContext *context, uint16_t n, mvalue v) {
    struct interpret_frame *frame = call S.current_frame(context);
    raw_vwrite(&frame->closure->variables[n], v);
  }

  command msize InterpretFrame.gc_forward(MateContext *context,
					  void *vframe,
					  uint8_t *lfp, uint8_t *lsp) {
    struct interpret_frame *frame = vframe;
    svalue *values, *last;

    if (frame->closure)
      {
	mvalue tmp = call T.make_closure(frame->closure);

	call GC.forward(&tmp);
	frame->closure = call T.closure(tmp);
      }

    /* Forward stack */
    values = (svalue *)lsp;
    last = (svalue *)lfp;
    while (values < last)
      call GC.sforward(values++);
	
    /* Forward locals */
    values = (svalue *)frame->locals;
    last = values + frame->nb_locals;
    while (values < last)
      call GC.sforward(values++);

    return (uint8_t *)last - (uint8_t *)frame;
  }

  void allocate_locals(svalue *locals, uint8_t n)
  /* Effect: Allocate an array of local variables in an optimised fashion.
   */
  {
    while (n--)
      {
	svalue *v = call V.allocate(type_vector, sizeof(svalue));

	if (!v)
	  return;
	// write old value to *v
	call V.write(v, call V.read(locals)); 
	// put v in place of old local
	call V.write(locals, call V.make_pointer(call V.make_pvalue(v)));
	locals++;
      }
  }

  void call_bytecode(vcode code, mvalue closure, uint8_t call_args,
		     MateContext *context) {
    struct interpret_frame *frame;
    uint8_t nb_locals = code->nb_locals, nb_nonargs;
    int8_t nargs = code->nargs;
    msize frame_size;
    uint16_t i;
    uint16_t oldpc = context->pc;

    /* Set context pc, to an offset from the start of our memory block.
       ASSUME: code is not garbage collected. */
    context->pc = code->ins - (instruction *)call GC.base();

    if (nargs < 0)
      nb_nonargs = nb_locals;
    else
      nb_nonargs = nb_locals - nargs;
    frame_size = sizeof(struct interpret_frame) + nb_nonargs * sizeof(svalue);

    GCPRO1(closure);
    frame = call S.alloc_frame(context, MOTLLE_INTERPRET_FRAME, frame_size);
    GCPOP1(closure);
    if (!frame)
      return;
    frame->closure = call T.closure(closure);
    frame->retpc = oldpc;
    frame->nb_locals = nb_locals;
    for (i = 0; i < nb_nonargs; i++)
      call V.write(&frame->locals[i], call T.nil());

    if (nargs < 0)
      {
	/* varargs */
	uint8_t j;
	vvector vargs;

	vargs = call V.allocate(type_vector, call_args * sizeof(svalue));
	if (!vargs)
	  return;

	for (j = 0; j < call_args; j++)
	  call V.write(&vargs->data[call_args - j - 1], call S.get(context, j));

	/* Pop args from stack and reserve space for vargs */
	call S.pop(context, call_args);
	frame_size += sizeof(mvalue);
	/* Save vargs in the right place */
	call V.write(&frame->locals[nb_locals - 1], call T.make_vector(vargs));
      }
    else /* fixed args, already in place, just check number */
      if (call_args != (uint8_t)nargs)
	{
	  call E.error(context, MOTLLE_ERROR_WRONG_PARAMETERS);
	  return;
	}

    /* Make local variables */
    allocate_locals(frame->locals, nb_locals);

    /* We don't check for infinite loops through function calls because
       these will run out of memory anyway */
  }

  vclosure lastClosure;

  command vclosure MotlleClosure.closure() {
    return lastClosure;
  }

  void call_primitive(mvalue fn, mvalue closure, uint8_t call_args,
		      MateContext *context) {
    uint16_t op;
    int8_t nargs;

    lastClosure = call T.closure(closure);
    op = call T.primitive(fn);
    nargs = call T.primitive_args(op);
    if (nargs >= 0 && (uint8_t)nargs != call_args)
      call E.error(context, MOTLLE_ERROR_WRONG_PARAMETERS);
    else
      call Primitives.execute[op](call_args, context);
    if (!call T.primitive_retval(op))
      call S.push(context, call T.make_int(42));
  }

  default command result_t Primitives.execute[uint16_t op](uint8_t i, MateContext* c) {
    return FAIL;
  }

  result_t callfn(mvalue fn, uint8_t nargs, MateContext *context) {
    mvalue closure;

    if (call T.closurep(fn))
      {
	vclosure c = call T.closure(fn);

	closure = fn;
	fn = call V.read(&c->code);
      }
    else
      closure = call T.nil();

    if (call T.primitivep(fn))
      call_primitive(fn, closure, nargs, context);
    else if (call T.codep(fn))
      call_bytecode(call T.code(fn), closure, nargs, context);
    else
      call E.error(context, MOTLLE_ERROR_BAD_FUNCTION);

    return SUCCESS;
  }

  command result_t Exec.execute(uint8_t instr, MateContext *context) {
    uint8_t nargs = instr - OP_MEXEC4;
    mvalue fn = call S.pop(context, 1);

    return callfn(fn, nargs, context);
  }

  command uint8_t Exec.byteLength() {
    return 1;
  }

  command result_t ExecGlobal.execute(uint8_t instr, MateContext *context) {
    uint8_t nargs = instr - OP_MEXECG4;
    mvalue fn = call G.read(call C.read_global_var(context));

    return callfn(fn, nargs, context);
  }

  command uint8_t ExecGlobal.byteLength() {
    return 1;
  }

  command result_t ExecPrimitive.execute(uint8_t instr, MateContext *context) {
    uint16_t op = instr - OP_MEXECPRIM6;
    uint8_t nargs = call T.primitive_args(op);

    call_primitive(call T.make_primitive(op), call T.nil(), nargs, context);

    return SUCCESS;
  }

  command uint8_t ExecPrimitive.byteLength() {
    return 1;
  }

  command result_t Return.execute(uint8_t instr, MateContext *context) {
    struct interpret_frame *frame = call S.current_frame(context);
    mvalue v = call S.pop(context, 1);

    if (call S.pop_frame(context, sizeof(struct interpret_frame) +
			 frame->nb_locals * sizeof(svalue)))
      {
	// Terminate handler (see MemoryM.HandlerStore.getOpcode)
	context->currentHandler = context->rootHandler;
	context->pc = 1;
      }
    else // not last frame
      {
	context->pc = frame->retpc;
	call S.qpush(context, v);
      }

    return SUCCESS;
  }

  command uint8_t Return.byteLength() {
    return 1;
  }
}
