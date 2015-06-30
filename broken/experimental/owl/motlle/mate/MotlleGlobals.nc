includes Mate;
includes Motlle;
interface MotlleGlobals
{
  command mvalue read(uint16_t n);
  command void write(uint16_t n, mvalue x);
}
