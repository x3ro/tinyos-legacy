includes Mate;
includes Motlle;
interface MotlleVar {
  command mvalue read(MateContext *context, uint16_t n);
  command void write(MateContext *context, uint16_t n, mvalue v);
}
