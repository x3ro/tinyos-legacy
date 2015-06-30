includes Mate;
includes Motlle;
interface MotlleGC
{
  // Access to the "safe over GC" fixed-size, pre-allocated stack
  command uint8_t gcpush(mvalue x);
  command mvalue gcfetch(uint8_t index);
  command mvalue gcpopfetch();
  command void gcpop(uint8_t count);

  command void collect();

  command void forward(mvalue *ptr);
  command void sforward(svalue *ptr);
  command uint8_t *base(); /* Return base of memory area */
  command mvalue entry_point();
  command bool mutable(void *ptr);

  command uint8_t *allocate(msize n);
}
