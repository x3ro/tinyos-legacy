includes Mate;
includes Motlle;
interface MotlleStack
{
  // Frame allocation
  command void *alloc_frame(MateContext *context, framekind kind, msize size);
  command bool pop_frame(MateContext *context, msize size);
  command void *current_frame(MateContext *context);

  command void *fp(MateContext *context);
  command void *sp(MateContext *context);

  // Reserve stack space
  command bool reserve(MateContext *context, msize n);

  command bool push(MateContext *context, mvalue x);
  command void qpush(MateContext *context, mvalue x); // does not reserve
  command mvalue pop(MateContext *context, uint8_t n);
  command mvalue get(MateContext *context, uint8_t index);
}
