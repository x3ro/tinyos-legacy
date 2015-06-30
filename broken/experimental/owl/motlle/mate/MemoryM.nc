module MemoryM
{
  provides {
    interface StdControl;
    interface MateHandlerStore as HandlerStore[uint8_t id];
    interface MotlleGC as GC;
    interface MotlleGlobals as G;
    interface MotlleStack as S;
    interface MateEngineControl as EngineControl;
  }
  uses {
    interface MotlleValues as V;
    interface MotlleTypes as T;
    interface MateError as E;
    interface MotlleFrame[uint8_t kind];
    interface MateVirus as Virus;
    command result_t PowerMgmtEnable();
  }
#include "massert.h"
}
implementation
{
  // fp is aligned to STACK_ALIGNMENT
  // -> STACK_ALIGNMENT should be the maximum alignment necessary for any
  //    types stored in stack frames
  // sp may be offset from fp by an arbitrary multiple of sizeof(svalue)
  // (V.read & V.write must be able to deal with that)
  struct base_frame
  {
    framekind kind;
    uint8_t *oldfp;
  };

  enum {
    BASE_FRAME_SIZE = ALIGN(sizeof(struct base_frame), MOTLLE_STACK_ALIGNMENT),
  };

  struct memory_header {
    uint8_t nglobals;
    //svalue entry;
  };

  MateCapsule mcapsule;

  uint8_t *gvars;
#define end_gvars gc_heap
  uint8_t *gc_heap;
  uint8_t *posgc;
  uint8_t *sp, *fp, *splimit;

  msize gc_offset;
  svalue gcprotected[MOTLLE_GCPRO_SIZE];
  uint8_t gcpro;

  void reset_splimit() {
    splimit = gc_heap + (posgc - gc_heap) * 2;
  }

  command result_t StdControl.init() {
    call Virus.registerCapsule(0, &mcapsule);
#if 1
    if (TOS_LOCAL_ADDRESS != 0)
      call PowerMgmtEnable();
#endif
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command result_t HandlerStore.initializeHandler[uint8_t which]() {
    return SUCCESS;
  }
  
  command MateHandlerOptions HandlerStore.getOptions[uint8_t id]() {
    return 0;
  }
  
  command MateHandlerLength HandlerStore.getCodeLength[uint8_t id]() {
    /* Only 1 bytes for the actual handlers (see below) */
    return 1;
  }

  MINLINE command MateOpcode HandlerStore.getOpcode[uint8_t id](uint16_t which) {
    /* We dispatch to handlers using a special opcode, after that we
       live in a special "handler" which corresponds to the whole "capsule"
       (and where pc addresses are just offsets from the base of our
       memory segment). When the handler terminates, we return to the
       original handler with pc != 0 */

    if (id < MATE_HANDLER_NUM)
      // the test on gvars confirms that code has been installed
      // (before then we have no globals, so handlers must not trigger)
      return which == 0 && gvars ? OP_MHANDLER4 + id : OP_HALT;

    return (call GC.base())[which];
  }

  event result_t Virus.capsuleInstalled(MateCapsuleID id, MateCapsule *capsule) {
    struct memory_header *header = (struct memory_header *)mcapsule.data;
    uint8_t i, nglobals = header->nglobals;

    gvars = mcapsule.data + mcapsule.dataSize;
    // initialise globals to null
    for (i = 0; i < nglobals; i++)
      call G.write(i, call T.nil());
    posgc = gc_heap = gvars + sizeof(svalue) * nglobals;
    sp = fp = mcapsule.data + sizeof mcapsule.data;
    reset_splimit();
    for (i = 0; i < MATE_HANDLER_NUM; i++)
      signal HandlerStore.handlerChanged[i]();
    signal EngineControl.reboot();
    return SUCCESS;
  }

  event result_t Virus.capsuleHeard(uint8_t type) {
    return SUCCESS;
  }

  event result_t Virus.disableExecution() {
    return SUCCESS;
  }

  event result_t Virus.enableExecution() {
    return SUCCESS;
  }

  event void Virus.capsuleForce(uint8_t type) { }

#ifdef GCQDEBUG
  msize maxobjsize; /* biggest object created */
#endif

  MINLINE command uint8_t *GC.base() { /* Return base of GC area */
    return mcapsule.data + sizeof(struct memory_header);
  }

  command mvalue GC.entry_point() {
    //return call V.read(&((struct memory_header *)call GC.base())->entry);
    // 1st object, for now
    return call V.make_pointer(call V.make_pvalue(call GC.base() + sizeof(uint16_t)));
  }

  /* Returns TRUE if ptr is in a mutable object (i.e., above gc_heap)
   */
  MINLINE command bool GC.mutable(void *ptr) {
    return ptr >= (void *)gc_heap;
  }

  // Access to the "safe over GC" fixed-size, pre-allocated stack
  MINLINE command uint8_t GC.gcpush(mvalue x) {
    uint8_t n = gcpro++;

    assert(n < MOTLLE_GCPRO_SIZE);
    call V.write(gcprotected + n, x);

    return n;
  }

  MINLINE command mvalue GC.gcfetch(uint8_t idx) {
    assert(idx < gcpro);
    return call V.read(gcprotected + idx);
  }
  
  MINLINE command mvalue GC.gcpopfetch() {
    return call V.read(gcprotected + --gcpro);
  }

  MINLINE command void GC.gcpop(uint8_t count) {
    assert(count <= gcpro);
    gcpro -= count;
  }

  MINLINE command mvalue G.read(uint16_t n) {
    assert(n < (end_gvars - gvars) / sizeof(svalue));
    return call V.read((svalue *)gvars + n);
  }

  MINLINE command void G.write(uint16_t n, mvalue x) {
    assert(n < (end_gvars - gvars) / sizeof(svalue));
    call V.write((svalue *)gvars + n, x);
  }

  
  // Frame allocation
  command void *S.alloc_frame(MateContext *context, framekind kind, msize size) {
    struct base_frame *frame;

    size = BASE_FRAME_SIZE + ALIGN(size, MOTLLE_STACK_ALIGNMENT);

    if (!call S.reserve(context, size))
      return NULL;

    sp -= size;
    frame = (struct base_frame *)sp;
    frame->kind = kind;
    frame->oldfp = fp;
    fp = (uint8_t *)frame;

    return (uint8_t *)frame + BASE_FRAME_SIZE;
  }

  MINLINE command void *S.current_frame(MateContext *context) {
    return fp + BASE_FRAME_SIZE;
  }

  MINLINE void upframe(uint8_t **ffp, uint8_t **fsp, msize size) {
    *fsp = *ffp + BASE_FRAME_SIZE + ALIGN(size, MOTLLE_STACK_ALIGNMENT);
    *ffp = ((struct base_frame *)*ffp)->oldfp;
  }

  MINLINE command bool S.pop_frame(MateContext *context, msize size) {
    upframe(&fp, &sp, size);
    return fp == (uint8_t *)(mcapsule.data + sizeof mcapsule.data);
  }

  MINLINE command void *S.fp(MateContext *context) {
    return fp;
  }

  MINLINE command void *S.sp(MateContext *context) {
    return sp;
  }

  MINLINE framekind frame_kind(uint8_t *lfp) {
    return ((struct base_frame *)lfp)->kind;
  }

  // Reserve stack space
  command bool S.reserve(MateContext *context, msize n) {
    if (sp - n < splimit)
      {
	call GC.collect();
	if (sp - n < splimit)
	  {
	    call E.error(context, MOTLLE_ERROR_NO_MEMORY);
	    return FALSE;
	  }
      }
    return TRUE;
  }

  command bool S.push(MateContext *context, mvalue x) { 
    bool ok;

    GCPRO1(x);
    ok = call S.reserve(context, sizeof(svalue));
    GCPOP1(x);
    if (ok)
      {
	sp -= sizeof(svalue);
	call V.write((svalue *)sp, x);
      }
    return ok;
  }

  MINLINE command void S.qpush(MateContext *context, mvalue x) { 
    sp -= sizeof(svalue);
    call V.write((svalue *)sp, x);
  }

  MINLINE command mvalue S.pop(MateContext *context, uint8_t n) {
    mvalue v = call V.read((svalue *)sp);
    sp += n * sizeof(svalue);
    return v;
  }

  MINLINE command mvalue S.get(MateContext *context, uint8_t idx) {
    return call V.read((svalue *)sp + idx);
  }

  // Garbage collection
  // ------------------

  /* True iff GC can be called after another `extra' GC bytes are
     allocated */
  MINLINE bool can_allocate(msize extra) {
    return posgc + extra - gc_heap <= (sp - (posgc + extra));
  }

  MINLINE bool try_gc_reserve(msize n) {
    if (!can_allocate(n))
      {
	call GC.collect();
	return can_allocate(n);
      }
    return TRUE;
  }

  bool gc_reserve(msize n) {
    if (!try_gc_reserve(n))
      {
	call E.error(NULL/*XXX: context*/, MOTLLE_ERROR_NO_MEMORY);
	return FALSE;
      }
    return TRUE;
  }

  MINLINE void assert_inblockn(void *p, msize n) {
    assert((uint8_t *)p >= call GC.base() && (uint8_t *)p + n <= sp);
  }

  MINLINE void assert_inblock(void *p) {
    assert_inblockn(p, sizeof(svalue));
  }

  MINLINE bool gcpointerp(mvalue x) {
    return call V.pointerp(x) &&
      (uint8_t *)call V.data(call V.pointer(x)) >= gc_heap;
  }

  command void GC.sforward(svalue *ptr) {
    mvalue v = call V.read(ptr);
    pvalue obj, newobj;
    msize size;

    if (!gcpointerp(v))
      return;
    obj = call V.pointer(v);

    if (call V.forwardedp(obj))
      call V.write(ptr, call V.make_pointer(call V.forward_get(obj)));
    else
      {
	//GCCHECK(obj);
	size = call V.fullsize(obj);
	assert_inblockn(posgc, size);
	newobj = call V.forward(obj, posgc, gc_offset, size);
	call V.write(ptr, call V.make_pointer(newobj));
	posgc += size;
      }
  }

  command void GC.forward(mvalue *ptr) {
    mvalue v = *ptr;
    pvalue obj, newobj;
    msize size;

    if (!gcpointerp(v))
      return;
    obj = call V.pointer(v);

    if (call V.forwardedp(obj))
      *ptr = call V.make_pointer(call V.forward_get(obj));
    else
      {
	//GCCHECK(obj);
	size = call V.fullsize(obj);
	assert_inblockn(posgc, size);
	newobj = call V.forward(obj, posgc, gc_offset, size);
	*ptr = call V.make_pointer(newobj);
	posgc += size;
      }
  }

  void forward_roots() {
    uint8_t scan_localpro;
    uint8_t *scanfp, *scansp;
    svalue *scan_globals;
    msize s;

    /* Forward protected C vars */
    for (scan_localpro = 0; scan_localpro < gcpro; scan_localpro++)
      call GC.sforward(gcprotected + scan_localpro);

    /* Forward globals */
    scan_globals = (svalue *)gvars; 
    while ((uint8_t *)(scan_globals + 1) <= end_gvars)
      call GC.sforward(scan_globals++);
  
    /* Forward the motlle stack */
    scansp = sp; scanfp = fp;
    while (scansp < (uint8_t *)mcapsule.data + sizeof mcapsule.data)
      {
	s = call MotlleFrame.gc_forward[frame_kind(scanfp)](NULL, scanfp + BASE_FRAME_SIZE, scanfp, scansp);
	upframe(&scanfp, &scansp, s);
      }
  }

  default command msize MotlleFrame.gc_forward[framekind k](MateContext *context, void *vframe, uint8_t *lfp, uint8_t *lsp) {
    assert(0);
    return 0;
  }

  uint8_t *scan(uint8_t *ptr) {
    void *data = call V.skip_header(ptr);
    pvalue obj = call V.make_pvalue(data);
    msize size = call V.fullsize(obj);
    uint8_t *end = ptr + size;
    mtype t = call V.ptype(obj);

    assert_inblockn(ptr, size);

    if (!(t == type_string || t == type_null))
      {
	svalue *o = (svalue *)data, *recend = (svalue *)end;

	while (o + 1 <= recend)
	  call GC.sforward(o++);
      }
    return end;
  }

  command void GC.collect() {
    uint8_t *data, *old_posgc = posgc;

    gc_offset = gc_heap - posgc;

    forward_roots();

    data = old_posgc;
    while (data < posgc)
      data = scan(data);

    /* Reset & move block */
    assert(posgc <= sp && posgc - old_posgc <= old_posgc - gc_heap);
    memcpy(gc_heap, old_posgc, posgc - old_posgc);
    posgc = gc_heap + (posgc - old_posgc);
    reset_splimit();
  }

  uint8_t *fast_gc_allocate(msize n) {
    uint8_t *newp = posgc;

    assert(can_allocate(n));

    posgc += n;

#ifdef GCQDEBUG
    if (n > maxobjsize) maxobjsize = n;
#endif

    return newp;
  }

  command uint8_t *GC.allocate(msize n)
  /* Effects: Allocates n bytes and returns a pointer to the start of
     the allocated area.
     DOES ABSOLUTELY NO INITIALISATION. BEWARE!
     Returns: Pointer to allocated area, or NULL for failure (no memory)
       In case of failure, MOTLLE_ERROR_NO_MEMORY is reported.
  */
  {
    uint8_t *p;

    if (!gc_reserve(n))
      return NULL;
    p = fast_gc_allocate(n);
    reset_splimit();
    return p;
  }
}
